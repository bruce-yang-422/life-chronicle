import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/archive/archive_integrity.dart';
import '../../core/archive/archive_subject_policy.dart';
import '../../core/time/time_format.dart';
import '../../core/time/time_value.dart';
import '../../data/providers.dart';
import '../../data/repositories/archive_restore.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_time_texts.dart';
import '../attachments/attachment_import.dart';
import '../security/security_dialogs.dart';
import '../settings/time_display_settings.dart';

final restoreFilePickerProvider = Provider<Future<File?> Function()>(
  (ref) => () async {
    final selected = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    return selected?.path == null ? null : File(selected!.path!);
  },
);

class RestorePage extends ConsumerStatefulWidget {
  const RestorePage({super.key});
  @override
  ConsumerState<RestorePage> createState() => _RestorePageState();
}

class _RestorePageState extends ConsumerState<RestorePage> {
  ArchiveRestore? _restore;
  ArchiveRestorePlan? _plan;
  ArchiveRestoreReport? _report;
  final _choices = <String, ArchiveConflictChoice>{};
  List<String> _excludedPaths = const [];
  bool _busy = false;
  String? _filename;
  String? _error;

  @override
  void dispose() {
    final plan = _plan;
    if (plan != null) unawaited(_restore!.discard(plan));
    super.dispose();
  }

  String _failure(Object error) {
    final l = AppLocalizations.of(context);
    if (error is ArchiveSubjectException) {
      return error.reason == ArchiveSubjectFailure.differentSubject
          ? l.restoreDifferentSubject
          : l.restoreInvalidSubject;
    }
    if (error is ImportSpaceException) return l.attachmentNoSpace;
    if (error is ArchiveIntegrityException &&
        error.paths.contains('revision')) {
      return l.restoreChanged;
    }
    if (error is ArchiveIntegrityException) {
      final paths = error.paths.where(
        (path) => path.contains('/') || path.contains('.'),
      );
      return [l.backupFailure, ...paths].join('\n');
    }
    return l.backupFailure;
  }

  Future<void> _pick() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!await authorizePrivate(context) || !mounted) return;
      final file = await ref.read(restoreFilePickerProvider)();
      if (file == null || !mounted) return;
      final restore = ArchiveRestore(
        await ref.read(archiveRepositoryProvider.future),
      );
      if (!mounted) return;
      final token = ImportCancellation();
      final inspected = await withImportProgress<ArchiveRestorePlan>(
        context,
        token,
        (progress) =>
            restore.inspect(file, cancellation: token, onProgress: progress),
        title: AppLocalizations.of(context).backupProgress,
      );
      if (!mounted) {
        await restore.discard(inspected);
        return;
      }
      if (_plan != null) await _restore!.discard(_plan!);
      if (!mounted) {
        await restore.discard(inspected);
        return;
      }
      setState(() {
        _restore = restore;
        _plan = inspected;
        _report = null;
        _choices.clear();
        _filename = p.basename(file.path);
        _excludedPaths = [
          for (final item
              in (inspected.verified.manifest['scope'] as Map)['excluded']
                  as List)
            (item as Map)['path'] as String,
        ];
      });
    } catch (error) {
      if (mounted && error is! ImportCancelled) {
        setState(() => _error = _failure(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply() async {
    final plan = _plan;
    if (_busy || plan == null || _choices.length != plan.conflicts.length) {
      return;
    }
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      if (!await authorizePrivate(context) || !mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.backupImport),
          content: Text(l.backupRestoreConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.timelineCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.restoreApply),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      // 對話框開啟期間可能重新鎖定；不得使用已失效的私密授權。
      if (!ref.read(securityProvider).canReadPrivate) return;
      setState(() {
        _busy = true;
        _error = null;
      });
      final token = ImportCancellation();
      final report = await withImportProgress(
        context,
        token,
        (progress) => _restore!.apply(plan, _choices, cancellation: token),
        title: l.backupProgress,
      );
      if (!mounted) return;
      ref.read(selectedEventProvider.notifier).clear();
      ref.invalidate(profileProvider);
      setState(() {
        _report = report;
        _plan = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _plan = null;
          _error = error is ImportCancelled
              ? l.restoreCancelled
              : _failure(error);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _value(String field, Object? value) {
    final l = AppLocalizations.of(context);
    if (value == null || value == '') return l.restoreEmpty;
    if (value is bool) return value ? l.restoreYes : l.restoreNo;
    if ([
      'time_payload',
      'birth_date',
      'death_date',
      'start_time',
      'end_time',
    ].contains(field)) {
      try {
        final time = TimeValue.fromJson(
          Map<String, Object?>.from(jsonDecode(value as String) as Map),
        );
        return TimeFormat.full(time, L10nTimeTexts(l));
      } catch (_) {
        return value.toString();
      }
    }
    if (field.endsWith('_at') || field == 'timestamp') {
      final date = DateTime.tryParse(value.toString());
      if (date != null) return readableTimestamp(ref, l, date);
    }
    if (field == 'layer') {
      return value == 'original' ? l.timelineOriginal : l.detailRemembrance;
    }
    if (field == 'privacy') {
      return value == 'private' ? l.editorPrivate : l.editorNormal;
    }
    if (field.endsWith('_id') ||
        field == 'activated_by' ||
        field == 'deactivated_by') {
      for (final rows in _plan!.data.values) {
        for (final row in rows) {
          if (row.entries.any(
            (entry) => entry.key.endsWith('_id') && entry.value == value,
          )) {
            for (final key in [
              'title',
              'display_name',
              'name',
              'label',
              'original_filename',
            ]) {
              if (row[key] is String && (row[key] as String).isNotEmpty) {
                return row[key] as String;
              }
            }
          }
        }
      }
    }
    return value.toString();
  }

  Widget _conflict(ArchiveConflict conflict, int index) {
    final l = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.restoreConflictNumber(
                l.restoreTable(conflict.table),
                index + 1,
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (conflict.sourceId != null)
              SelectableText(
                l.restoreReuseId(
                  conflict.sourceId!,
                  conflict.local[switch (conflict.table) {
                        'places' => 'place_id',
                        'people' => 'person_id',
                        _ => 'tag_id',
                      }]
                      as String,
                ),
              ),
            for (final field in conflict.incoming.keys.where(
              (key) =>
                  conflict.local[key] != conflict.incoming[key] ||
                  (conflict.sourceId != null &&
                      key ==
                          switch (conflict.table) {
                            'places' => 'name',
                            'people' => 'display_name',
                            _ => 'label',
                          }),
            ))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.restoreField(field),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    SelectableText(
                      l.restoreLocalValue(_value(field, conflict.local[field])),
                    ),
                    SelectableText(
                      l.restoreArchiveValue(
                        _value(field, conflict.incoming[field]),
                      ),
                    ),
                  ],
                ),
              ),
            RadioGroup<ArchiveConflictChoice>(
              groupValue: _choices[conflict.key],
              onChanged: (value) {
                if (!_busy && value != null) {
                  setState(() => _choices[conflict.key] = value);
                }
              },
              child: Column(
                children: [
                  RadioListTile(
                    value: ArchiveConflictChoice.keepLocal,
                    title: Text(l.backupKeep),
                  ),
                  RadioListTile(
                    value: ArchiveConflictChoice.useArchive,
                    title: Text(l.backupUseArchive),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final allowed = ref.watch(securityProvider).canReadPrivate;
    final plan = _plan;
    final report = _report;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(l.backupImport)),
        body: !allowed
            ? Center(
                child: TextButton.icon(
                  onPressed: () => authorizePrivate(context),
                  icon: const Icon(Icons.lock_outline),
                  label: Text(l.securityPrivateUnlock),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(l.restoreIntro),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _pick,
                    icon: const Icon(Icons.folder_open),
                    label: Text(l.restoreSelect),
                  ),
                  if (_filename != null) Text(_filename!),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (plan != null) ...[
                    Text(
                      l.restorePreview,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    for (final entry in plan.data.entries.where(
                      (entry) => entry.value.isNotEmpty,
                    ))
                      Text(
                        l.restoreCount(
                          l.restoreTable(entry.key),
                          entry.value.length,
                        ),
                      ),
                    if (plan.verified.manifest['format_version'] != '1.0')
                      Text(l.backupNewFormat),
                    if (_excludedPaths.isNotEmpty) ...[
                      Text(l.restoreExcluded),
                      for (final path in _excludedPaths) Text(path),
                    ],
                    if (plan.verified.extraFiles.isNotEmpty) ...[
                      Text(l.restoreExtraFiles),
                      for (final path in plan.verified.extraFiles) Text(path),
                    ],
                    Text(l.restoreChooseAll),
                    for (var i = 0; i < plan.conflicts.length; i++)
                      _conflict(plan.conflicts[i], i),
                    FilledButton(
                      onPressed:
                          _busy || _choices.length != plan.conflicts.length
                          ? null
                          : _apply,
                      child: Text(l.restoreApply),
                    ),
                  ],
                  if (report != null) ...[
                    Text(
                      l.backupRestoreDone,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      l.restoreMediaTotals(
                        report.attachmentCount,
                        formatBytes(report.mediaBytes),
                      ),
                    ),
                    if (_excludedPaths.isNotEmpty) ...[
                      Text(l.restoreExcluded),
                      for (final path in _excludedPaths) Text(path),
                    ],
                    Text(
                      l.backupReport(
                        '${report.inserted.values.fold(0, (a, b) => a + b)}',
                        '${report.replaced}',
                        '${report.skipped}',
                        '${report.excluded}',
                        '${report.extraFiles.length}',
                      ),
                    ),
                    for (final entry in report.inserted.entries)
                      Text(
                        l.restoreCount(l.restoreTable(entry.key), entry.value),
                      ),
                    for (final path in report.extraFiles) Text(path),
                  ],
                ],
              ),
      ),
    );
  }
}
