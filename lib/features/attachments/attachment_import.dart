import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/repositories/attachment_repository.dart';
import '../../l10n/app_localizations.dart';

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
  if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MiB';
  return '${(bytes / 1073741824).toStringAsFixed(2)} GiB';
}

/// 準備及匯入中皆有可見的取消按鈕。
Future<T> withImportProgress<T>(
  BuildContext context,
  ImportCancellation token,
  Future<T> Function(void Function(int, int) progress) action, {
  String? title,
}) async {
  final progress = ValueNotifier<(int, int)>((0, 0));
  final l = AppLocalizations.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(title ?? l.attachmentImport),
        content: ValueListenableBuilder(
          valueListenable: progress,
          builder: (_, value, child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: value.$2 > 0
                    ? (value.$1 / value.$2).clamp(0.0, 1.0)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(l.attachmentProgress(value.$1, value.$2)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => token.cancelled = true,
            child: Text(l.attachmentCancel),
          ),
        ],
      ),
    ),
  );
  try {
    return await action((done, total) => progress.value = (done, total));
  } finally {
    navigator.pop();
    Future<void>.delayed(const Duration(seconds: 1), progress.dispose);
  }
}

Future<AttachmentImportPlan?> pickImportPlan(
  BuildContext context,
  AttachmentRepository repository, {
  bool forDraft = false,
}) async {
  final selected = await FilePicker.pickFiles();
  if (selected.isEmpty || !context.mounted) return null;
  final sources = [
    for (final file in selected) AttachmentSource(file.path ?? '', file.name),
  ];
  final token = ImportCancellation();
  final plan = await withImportProgress(
    context,
    token,
    (progress) =>
        repository.prepare(sources, cancellation: token, onProgress: progress),
  );
  if (!context.mounted) return null;
  final required = plan.addedBytes + (forDraft ? plan.originalBytes : 0);
  final l = AppLocalizations.of(context);
  if (required > plan.freeBytes) throw ImportSpaceException();
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.attachmentPlan),
      content: Text(
        l.attachmentPlanBody(
          plan.files.length,
          formatBytes(plan.originalBytes),
          formatBytes(required),
          formatBytes(plan.freeBytes),
          plan.duplicates,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.timelineCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.attachmentImport),
        ),
      ],
    ),
  );
  return accepted == true ? plan : null;
}

void showImportError(BuildContext context, Object error) {
  if (error is ImportCancelled) return;
  final l = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        error is ImportSpaceException ? l.attachmentNoSpace : l.attachmentError,
      ),
    ),
  );
}
