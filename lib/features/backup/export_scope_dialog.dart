import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/archive/archive_media_scope.dart';
import '../../data/providers.dart';
import '../../data/repositories/archive_repository.dart';
import '../../l10n/app_localizations.dart';
import '../attachments/attachment_import.dart';

/// 共用副本只列一列，避免選擇某個附件後仍由其他引用將檔案匯出。
class ExportScopeDialog extends ConsumerStatefulWidget {
  const ExportScopeDialog({super.key, required this.options});
  final List<ArchiveMediaOption> options;

  @override
  ConsumerState<ExportScopeDialog> createState() => _ExportScopeDialogState();
}

class _ExportScopeDialogState extends ConsumerState<ExportScopeDialog> {
  bool _includeMedia = true;
  final _excluded = <String>{};

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
                  CheckboxListTile(
                    value: _includeMedia,
                    onChanged: (value) =>
                        setState(() => _includeMedia = value!),
                    title: Text(l.backupMedia),
                  ),
                  Text(l.backupMediaNotice),
                  if (_includeMedia && widget.options.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(l.backupMediaSelection),
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.3,
                      child: ListView.builder(
                        itemCount: widget.options.length,
                        itemBuilder: (context, index) {
                          final option = widget.options[index];
                          return CheckboxListTile(
                            value: !_excluded.contains(option.blobId),
                            onChanged: (value) => setState(() {
                              if (value == true) {
                                _excluded.remove(option.blobId);
                              } else {
                                _excluded.add(option.blobId);
                              }
                            }),
                            title: Text(option.names.join('\n')),
                            subtitle: Text(
                              l.backupMediaDetails(
                                formatBytes(option.byteSize),
                                option.references,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (widget.options.isEmpty) Text(l.backupNoMedia),
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
                    excludedBlobIds: _excluded,
                  ),
                )
              : null,
          child: Text(l.backupExport),
        ),
      ],
    );
  }
}
