import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../event_detail/event_detail_page.dart';
import '../settings/time_display_settings.dart';
import '../security/security_dialogs.dart';

final recentlyDeletedProvider = StreamProvider<List<Event>>((ref) async* {
  final repository = await ref.watch(eventRepositoryProvider.future);
  yield* repository.watchDeleted();
});

/// 軟刪除沒有期限；永久刪除必須先看過影響說明。
class RecentlyDeletedPage extends ConsumerWidget {
  const RecentlyDeletedPage({super.key});

  Future<void> _purge(BuildContext context, WidgetRef ref, Event event) async {
    final l = AppLocalizations.of(context);
    try {
      final repository = await ref.read(eventRepositoryProvider.future);
      final preserves = await repository.hasRemembranceContent(event.id);
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.recyclePurge),
          content: SingleChildScrollView(
            child: Text(
              [
                event.title,
                l.recyclePurgeConfirm,
                if (preserves) l.recyclePreserve,
              ].join('\n\n'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.timelineCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.recyclePurge),
            ),
          ],
        ),
      );
      if (confirmed == true) await repository.purge(event.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.editorError)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final canReadPrivate = ref.watch(securityProvider).canReadPrivate;
    return Scaffold(
      appBar: AppBar(title: Text(l.recycleTitle)),
      body: ref
          .watch(recentlyDeletedProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, stack) => Center(child: Text(l.timelineLoadError)),
            data: (events) => events.isEmpty
                ? Center(child: Text(l.recycleEmpty))
                : ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final protected =
                          event.privacy == 'private' && !canReadPrivate;
                      return Card(
                        margin: const EdgeInsets.all(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                protected
                                    ? l.securityPrivateEvent
                                    : event.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(readableTimestamp(ref, l, event.deletedAt!)),
                              TextButton.icon(
                                icon: const Icon(Icons.menu_book),
                                label: Text(l.recycleView),
                                onPressed: () async {
                                  if (protected &&
                                      !await authorizePrivate(context)) {
                                    return;
                                  }
                                  if (!context.mounted) return;
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => EventDetailPage(
                                        eventId: event.id,
                                        includeDeleted: true,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (protected)
                                TextButton.icon(
                                  icon: const Icon(Icons.lock_outline),
                                  label: Text(l.securityPrivateUnlock),
                                  onPressed: () => authorizePrivate(context),
                                )
                              else if (event.purgedAt != null)
                                Text(l.recyclePreserve)
                              else
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.restore),
                                      label: Text(l.recycleRestore),
                                      onPressed: () async {
                                        try {
                                          await (await ref.read(
                                            eventRepositoryProvider.future,
                                          )).restore(event.id);
                                        } catch (_) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(l.editorError),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                    TextButton.icon(
                                      icon: const Icon(Icons.delete_forever),
                                      label: Text(l.recyclePurge),
                                      onPressed: () =>
                                          _purge(context, ref, event),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
    );
  }
}
