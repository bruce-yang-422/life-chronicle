import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/archive/archive_media_scope.dart';
import '../../data/providers.dart';
import '../../data/repositories/archive_repository.dart';
import '../../l10n/app_localizations.dart';
import '../attachments/attachment_import.dart';

final archivePartLimitsProvider = Provider<List<int>>(
  (ref) => [1024 * 1024 * 1024, 2 * 1024 * 1024 * 1024, 4000 * 1024 * 1024],
);

/// 以私密範圍與附件總開關選擇備份，不隨附件數量增加操作量。
class ExportScopeDialog extends ConsumerStatefulWidget {
  const ExportScopeDialog({super.key, required this.options});
  final List<ArchiveMediaOption> options;

  @override
  ConsumerState<ExportScopeDialog> createState() => _ExportScopeDialogState();
}

class _ExportScopeDialogState extends ConsumerState<ExportScopeDialog> {
  bool _includeMedia = true;
  bool _excludePrivate = false;
  int _maxPartBytes = 0;

  List<ArchiveMediaOption> get _selectedOptions => !_includeMedia
      ? const []
      : widget.options
            .where(
              (file) =>
                  !_excludePrivate ||
                  file.references == 0 ||
                  (file.normalReferences ?? file.references) > 0,
            )
            .toList();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final allowed = ref.watch(securityProvider).canReadPrivate;
    return AlertDialog(
      scrollable: true,
      title: Text(l.backupScope),
      content: SizedBox(
        width: 440,
        child: allowed
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: !_excludePrivate,
                    onChanged: (value) =>
                        setState(() => _excludePrivate = !value),
                    title: Text(l.backupIncludePrivate),
                    subtitle: Text(l.backupPrivateScopeHint),
                  ),
                  if (_excludePrivate) Text(l.backupExcludePrivateNotice),
                  const Divider(),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _includeMedia,
                    onChanged: (value) => setState(() => _includeMedia = value),
                    title: Text(l.backupMedia),
                    subtitle: Text(
                      l.backupAttachmentTotals(
                        _selectedOptions.length,
                        formatBytes(
                          _selectedOptions.fold<int>(
                            0,
                            (sum, file) => sum + file.byteSize,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!_includeMedia) Text(l.backupMediaNotice),
                  if (widget.options.isEmpty) Text(l.backupNoMedia),
                  const SizedBox(height: 12),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(l.backupAdvanced),
                    childrenPadding: const EdgeInsets.only(top: 12, bottom: 8),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.backupSplit,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        initialValue: _maxPartBytes,
                        isExpanded: true,
                        decoration: const InputDecoration(),
                        items: [
                          DropdownMenuItem(
                            value: 0,
                            child: Text(l.backupNoSplit),
                          ),
                          for (final size in ref.watch(
                            archivePartLimitsProvider,
                          ))
                            DropdownMenuItem(
                              value: size,
                              child: Text(l.backupPartLimit(formatBytes(size))),
                            ),
                        ],
                        onChanged: _includeMedia
                            ? (value) => setState(() => _maxPartBytes = value!)
                            : null,
                      ),
                      if (_includeMedia && _maxPartBytes > 0)
                        Text(l.backupSplitNotice),
                    ],
                  ),
                ],
              )
            : Text(l.securityPrivateUnlock),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.timelineCancel),
        ),
        FilledButton(
          onPressed: allowed
              ? () => Navigator.pop(
                  context,
                  ArchiveMediaScope(
                    includeMedia: _includeMedia,
                    excludePrivateEvents: _excludePrivate,
                    maxPartBytes: _includeMedia && _maxPartBytes > 0
                        ? _maxPartBytes
                        : null,
                  ),
                )
              : null,
          child: Text(l.backupContinue),
        ),
      ],
    );
  }
}
