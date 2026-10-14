import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as p;

import '../../core/archive/archive_integrity.dart';
import '../../core/archive/archive_reading.dart';
import '../../data/providers.dart';
import '../../data/repositories/archive_repository.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../l10n/l10n_time_texts.dart';
import '../../l10n/app_localizations_zh.dart';
import '../attachments/attachment_import.dart';

import '../attachments/attachment_warehouse_page.dart';
import '../../l10n/app_localizations.dart';
import 'recently_deleted_page.dart';
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
    var media = true;
    final chosen = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(l.backupScope),
          content: CheckboxListTile(
            value: media,
            onChanged: (value) => setLocal(() => media = value!),
            title: Text(l.backupMedia),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.timelineCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.backupExport),
            ),
          ],
        ),
      ),
    );
    if (chosen != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final repository = await ref.read(archiveRepositoryProvider.future);
      final plan = await repository.prepare(includeMedia: media);
      if (!mounted) return;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.backupExport),
          content: Text(
            l.backupPlan(
              formatBytes(plan.requiredBytes),
              formatBytes(plan.freeBytes),
              '${plan.data['events']!.length}',
            ),
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
      if (accepted != true || !mounted) return;
      final zone = await ref.read(timeZoneProvider.future);
      if (!mounted) return;
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
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.navBackup, style: Theme.of(context).textTheme.headlineSmall),
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
          FilledButton.icon(
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.archive_outlined),
            label: Text(l.backupExport),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : _verify,
            icon: const Icon(Icons.fact_check_outlined),
            label: Text(l.backupVerify),
          ),
          if (_last != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.backupLast),
                    SelectableText(p.basename(_last!.zip.path)),
                    SelectableText(_last!.hash),
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
    );
  }
}
