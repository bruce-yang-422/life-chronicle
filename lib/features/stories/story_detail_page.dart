import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/time_format.dart';
import '../../core/time/time_value.dart';
import '../../core/stories/theme_rule.dart';
import '../../data/providers.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/story_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_time_texts.dart';
import '../event_detail/event_detail_page.dart';
import '../security/security_dialogs.dart';
import '../shared/ios_group.dart';
import 'story_editor_page.dart';

class StoryDetailPage extends ConsumerWidget {
  const StoryDetailPage({super.key, required this.storyId});
  final String storyId;

  Future<void> _openEvent(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final event = await (await ref.read(eventRepositoryProvider.future))
        .find(id);
    if (!context.mounted || event == null || event.deletedAt != null) return;
    if (event.privacy == 'private' &&
        !ref.read(securityProvider).canReadPrivate &&
        !await authorizePrivate(context)) {
      return;
    }
    if (!context.mounted) return;
    // 完整頁避免平板主從詳情被篇章路由遮住，標題由詳情頁依權限讀取。
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => EventDetailPage(eventId: id)),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.storiesDelete),
        content: Text(l.storiesDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.timelineCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.storiesDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await (await ref.read(storyRepositoryProvider.future)).delete(storyId);
      if (context.mounted) Navigator.pop(context);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.storiesError)));
      }
    }
  }

  Widget _entryTile(BuildContext context, WidgetRef ref, StoryEntry entry) {
    final l = AppLocalizations.of(context);
    final canReadPrivate = ref.watch(securityProvider).canReadPrivate;
    final event = !canReadPrivate && entry.event?.privacy == 'private'
        ? null
        : entry.event;
    String? timeLabel;
    if (event != null) {
      final time = decodeTime(event.timePayload);
      final texts = L10nTimeTexts(l);
      String? relatedTitle;
      if (time is RelativeTime) {
        final reference = ref
            .watch(eventReferencesProvider)
            .value
            ?.where((e) => e.id == time.eventId)
            .firstOrNull;
        relatedTitle = reference == null
            ? texts.deletedReferenceTitle(time, canReadPrivate: canReadPrivate)
            : reference.privacy == 'private' && !canReadPrivate
            ? l.securityPrivateEvent
            : reference.deletedAt != null
            ? l.recycleDeletedTitle(reference.title)
            : reference.title;
      }
      timeLabel = TimeFormat.full(time, texts, relatedEventTitle: relatedTitle);
    }
    return ListTile(
      leading: Icon(
        event == null ? Icons.lock_outline : Icons.article_outlined,
      ),
      title: Text(
        event == null
            ? l.securityPrivateEvent
            : event.deletedAt != null
            ? l.recycleDeletedTitle(event.title)
            : event.title,
      ),
      subtitle: event == null
          ? null
          : Text(event.deletedAt != null ? l.storiesDeletedEvent : timeLabel!),
      trailing: event?.deletedAt != null
          ? null
          : const Icon(Icons.chevron_right),
      onTap: event?.deletedAt != null
          ? null
          : () => _openEvent(context, ref, entry.eventId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.navStories)),
      body: ref
          .watch(storyContentProvider(storyId))
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(storyContentProvider(storyId)),
                child: Text(l.timelineRetry),
              ),
            ),
            data: (content) {
              if (content == null) return Center(child: Text(l.storiesMissing));
              final summary = content.summary;
              final rule = summary.story.rulesJson == null
                  ? null
                  : ThemeRule.decode(summary.story.rulesJson!);
              final tags = {
                for (final tag in ref.watch(storyTagsProvider).value ?? [])
                  tag.id: tag.label,
              };
              return ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  IosPageTitle(summary.story.title),
                  Text(
                    summary.story.layer == 'original'
                        ? l.timelineOriginal
                        : l.timelineRemembrance,
                  ),
                  const SizedBox(height: 12),
                  if (rule != null) ...[
                    Text(
                      rule.mode == TagMatchMode.all ? l.themesAll : l.themesAny,
                    ),
                    IosGroup(
                      title: l.themesInclude,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final id in rule.include)
                                Chip(
                                  label: Text(tags[id] ?? l.themesMissingTag),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (rule.exclude.isNotEmpty)
                      IosGroup(
                        title: l.themesExclude,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final id in rule.exclude)
                                  Chip(
                                    label: Text(tags[id] ?? l.themesMissingTag),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    Text(l.themesAutoUpdate),
                  ] else
                    Text(l.themesLegacy),
                  if (!summary.canModify) Text(l.storiesReadOnly),
                  if (summary.canModify)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l.storiesEdit),
                        onPressed: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StoryEditorPage(initial: content),
                          ),
                        ),
                      ),
                    ),
                  if (content.entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(l.storiesEmptyEvents),
                    ),
                  IosGroup(
                    title: l.storiesCount(summary.eventCount),
                    children: [
                      for (final entry in content.entries)
                        _entryTile(context, ref, entry),
                    ],
                  ),
                  if (summary.canModify)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () => _delete(context, ref),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l.storiesDelete),
                      ),
                    ),
                ],
              );
            },
          ),
    );
  }
}
