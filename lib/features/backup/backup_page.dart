import '../shared/ios_group.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as p;

import '../../core/archive/archive_integrity.dart';
import '../../core/archive/archive_reading.dart';
import '../../core/archive/archive_media_scope.dart';
import '../../data/providers.dart';
import '../../data/repositories/archive_repository.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../l10n/l10n_time_texts.dart';
import '../../l10n/app_localizations_zh.dart';
import '../attachments/attachment_import.dart';

import '../attachments/attachment_warehouse_page.dart';
import '../../l10n/app_localizations.dart';
import 'recently_deleted_page.dart';
import 'restore_page.dart';
import 'export_scope_dialog.dart';
import '../security/security_page.dart';
import '../security/security_dialogs.dart';
import '../settings/time_display_settings.dart';
import '../../core/time/timestamp_display.dart';

/// 資料與備份（T12、T13 實作）。
class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage> {
  bool _busy = false;
  ArchiveExport? _last;
  @override
  void initState() {
    super.initState();
    _loadLast();
  }

  Future<void> _loadLast() async {
    try {
      final repository = await ref.read(archiveRepositoryProvider.future);
      final record = File(
        p.join(repository.outputDirectory.path, 'latest.json'),
      );
      if (!await record.exists()) return;
      final row =
          jsonDecode(await record.readAsString()) as Map<String, dynamic>;
      final zip = File(row['path'] as String);
      final sidecar = File('${zip.path}.sha256');
      if (mounted &&
          row['verified'] == true &&
          await zip.exists() &&
          await sidecar.exists()) {
        setState(
          () => _last = ArchiveExport(
            zip,
            sidecar,
            row['sha256'] as String,
            Map<String, int>.from(row['counts'] as Map),
          ),
        );
      }
    } catch (_) {
      /* 沒有完整紀錄時不宣稱已有有效備份。 */
    }
  }

  void _failure(Object error) {
    if (!mounted || error is ImportCancelled) return;
    final l = AppLocalizations.of(context);
    final detail = error is ArchiveIntegrityException
        ? error.paths.join('\n')
        : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${error is ImportSpaceException ? l.attachmentNoSpace : l.backupFailure}\n$detail',
        ),
      ),
    );
  }

  Future<void> _export() async {
    if (!await authorizePrivate(context) || !mounted) return;
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final repository = await ref.read(archiveRepositoryProvider.future);
      final options = await repository.mediaOptions();
      if (!mounted) return;
      final chosen = await showDialog<ArchiveMediaScope>(
        context: context,
        builder: (_) => ExportScopeDialog(options: options),
      );
      if (chosen == null ||
          !mounted ||
          !ref.read(securityProvider).canReadPrivate) {
        return;
      }
      final plan = await repository.prepare(
        includeMedia: chosen.includeMedia,
        excludePrivateEvents: chosen.excludePrivateEvents,
        excludedBlobIds: chosen.excludedBlobIds,
      );
      if (!mounted) return;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text(l.backupExport),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plan.privacyFilter != null)
                Text(
                  l.backupPrivateExcluded(
                    plan.privacyFilter!.excludedEvents,
                    plan.privacyFilter!.excludedMedia,
                  ),
                ),
              Text(
                l.backupScopeSummary(
                  switch (plan.scope.type) {
                    'full' => l.backupScopeFull,
                    'no_media' => l.backupScopeNoMedia,
                    _ => l.backupScopeCustom,
                  },
                  plan.excludedMedia.length +
                      (plan.privacyFilter?.excludedMedia ?? 0),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.backupPlan(
                  formatBytes(plan.requiredBytes),
                  formatBytes(plan.freeBytes),
                  '${plan.data['events']!.length}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.timelineCancel),
            ),
            FilledButton(
              onPressed: plan.requiredBytes > plan.freeBytes
                  ? null
                  : () => Navigator.pop(context, true),
              child: Text(l.backupExport),
            ),
          ],
        ),
      );
      if (accepted != true ||
          !mounted ||
          !ref.read(securityProvider).canReadPrivate) {
        return;
      }
      final zone = await ref.read(timeZoneProvider.future);
      if (!mounted || !ref.read(securityProvider).canReadPrivate) return;
      final reading = ArchiveReading(
        {
          'timeline': l.navTimeline,
          'time': l.archiveTimeLabel,
          'layer': l.archiveLayerLabel,
          'author': l.archiveAuthorLabel,
          'recorded': l.detailRecorded,
          'category': l.editorCategory,
          'deleted': l.recycleTitle,
          'original': l.timelineOriginal,
          'remembrance': l.detailRemembrance,
          'reflections': l.detailReflections,
          'attachments': l.detailMedia,
          'privacy': l.editorPrivacy,
          'private': l.editorPrivate,
          'normal': l.editorNormal,
          'place': l.editorPlace,
          'people': l.archivePeople,
          'tags': l.archiveTags,
          'periods': l.archivePeriods,
          'stories': l.navStories,
          'themeAll': l.themesAll,
          'themeAny': l.themesAny,
          'themeExclude': l.themesExclude,
          'themeMissing': l.themesMissingTag,
          'related': l.editorRelated,
          'coordinates': l.archiveCoordinates,
          'radius': l.archiveRadius,
          'captured': l.archiveCaptured,
          'imported': l.archiveImported,
          'filename': l.archiveFilename,
          'unavailable': l.archiveExcludedMedia,
          'selfAuthor': l.detailAuthorSelf,
          'narrative': l.editorNarrative,
          'deletedReference': l.archiveDeletedReference,
        },
        L10nTimeTexts(l),
        timestampFormat: (value) => TimestampDisplay.format(
          value,
          zone,
          l.timestampPattern,
          l.localeName,
        ),
      );
      final token = ImportCancellation();
      final result = await withImportProgress(
        context,
        token,
        (progress) => repository.export(
          plan,
          reading,
          readme: AppLocalizationsZh().backupReadme,
          appVersion: '1.0.0+1',
          cancellation: token,
          onProgress: progress,
        ),
        title: l.backupProgress,
      );
      if (mounted) {
        setState(() => _last = result);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.backupSuccess)));
      }
    } catch (error) {
      _failure(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final selected = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (selected?.path == null || !mounted) return;
    setState(() => _busy = true);
    Directory? staging;
    try {
      final repository = await ref.read(archiveRepositoryProvider.future);
      staging = Directory(
        p.join(
          repository.outputDirectory.path,
          'verify_${repository.ctx.newId().toLowerCase()}',
        ),
      );
      final token = ImportCancellation();
      if (!mounted) return;
      await withImportProgress(
        context,
        token,
        (progress) async => repository.zipCodec.verify(
          File(selected!.path!),
          staging!,
          freeBytes: await repository.attachments.platform.availableBytes(
            repository.outputDirectory.path,
          ),
          cancellation: token,
          onProgress: progress,
        ),
        title: AppLocalizations.of(context).backupProgress,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).backupVerified)),
        );
      }
    } catch (error) {
      _failure(error);
    } finally {
      if (staging != null && await staging.exists()) {
        await staging.delete(recursive: true);
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          IosPageTitle(l.navBackup),
          IosGroup(
            children: [
              ListTile(
                title: Text(l.displaySettings),
                leading: const Icon(Icons.settings_outlined),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const TimeDisplaySettingsPage(),
                  ),
                ),
              ),
              ListTile(
                title: Text(l.securityTitle),
                leading: const Icon(Icons.security),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const SecurityPage()),
                ),
              ),
              if (ref.watch(securityProvider).configured)
                ListTile(
                  title: Text(l.securityLockNow),
                  leading: const Icon(Icons.lock_outline),
                  onTap: () => ref.read(securityProvider).lock(),
                ),
            ],
          ),
          IosGroup(
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _export,
                icon: const Icon(Icons.archive_outlined),
                label: Text(l.backupExport),
              ),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const RestorePage(),
                        ),
                      ),
                icon: const Icon(Icons.restore),
                label: Text(l.backupImport),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _verify,
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(l.backupVerify),
              ),
            ],
          ),
          if (_last != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.backupLast,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(p.basename(_last!.zip.path)),
                    const SizedBox(height: 8),
                    SelectableText(
                      _last!.hash,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () async {
                              try {
                                await SharePlus.instance.share(
                                  ShareParams(
                                    files: [
                                      XFile(
                                        _last!.zip.path,
                                        mimeType: 'application/zip',
                                      ),
                                      XFile(
                                        _last!.sidecar.path,
                                        mimeType: 'text/plain',
                                      ),
                                    ],
                                    sharePositionOrigin:
                                        context.findRenderObject() is RenderBox
                                        ? (context.findRenderObject()
                                                      as RenderBox)
                                                  .localToGlobal(Offset.zero) &
                                              (context.findRenderObject()
                                                      as RenderBox)
                                                  .size
                                        : null,
                                  ),
                                );
                              } catch (error) {
                                _failure(error);
                              }
                            },
                      icon: const Icon(Icons.ios_share),
                      label: Text(l.backupShare),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          IosGroup(
            children: [
              ListTile(
                title: Text(l.recycleTitle),
                leading: const Icon(Icons.restore_from_trash),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const RecentlyDeletedPage(),
                  ),
                ),
              ),
              ListTile(
                title: Text(l.attachmentWarehouse),
                leading: const Icon(Icons.folder_outlined),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AttachmentWarehousePage(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
