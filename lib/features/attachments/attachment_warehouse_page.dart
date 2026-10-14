import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import 'attachment_import.dart';

final _unreferencedProvider = FutureProvider.autoDispose(
  (ref) async =>
      (await ref.watch(attachmentRepositoryProvider.future))
          .unreferencedFiles(),
);

class AttachmentWarehousePage extends ConsumerWidget {
  const AttachmentWarehousePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.attachmentWarehouse)),
      body: ref
          .watch(_unreferencedProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text(l.attachmentUnavailable)),
            data: (files) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l.attachmentUnreferenced,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (files.isEmpty) Text(l.attachmentEmpty),
                for (final file in files)
                  ListTile(
                    title: Text(file.uri.pathSegments.last),
                    subtitle: FutureBuilder<int>(
                      future: file.length().catchError((Object error) => 0),
                      builder: (context, snapshot) =>
                          Text(formatBytes(snapshot.data ?? 0)),
                    ),
                  ),
                if (files.isNotEmpty)
                  FilledButton(
                    onPressed: () async {
                      var size = 0;
                      for (final file in files) {
                        if (await file.exists()) size += await file.length();
                      }
                      if (!context.mounted) return;
                      final accepted = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          content: Text(
                            l.attachmentCleanConfirm(formatBytes(size)),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(l.timelineCancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(l.attachmentClean),
                            ),
                          ],
                        ),
                      );
                      if (accepted != true) return;
                      try {
                        await (await ref.read(
                          attachmentRepositoryProvider.future,
                        )).cleanUnreferenced();
                        ref.invalidate(_unreferencedProvider);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.attachmentUnavailable)),
                          );
                        }
                      }
                    },
                    child: Text(l.attachmentClean),
                  ),
              ],
            ),
          ),
    );
  }
}
