import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../shared/ios_group.dart';
import 'story_editor_page.dart';
import 'story_detail_page.dart';

class StoriesPage extends ConsumerWidget {
  const StoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IosPageTitle(l.navStories),
                  FilledButton.icon(
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StoryEditorPage(),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(l.storiesCreate),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          ref
              .watch(storiesProvider)
              .when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => SliverFillRemaining(
                  child: Center(
                    child: TextButton(
                      onPressed: () => ref.invalidate(storiesProvider),
                      child: Text(l.timelineRetry),
                    ),
                  ),
                ),
                data: (stories) => stories.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_offer_outlined,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(l.storiesEmpty, textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        sliver: SliverList.builder(
                          itemCount: stories.length,
                          itemBuilder: (context, index) {
                            final summary = stories[index];
                            return IosGroup(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.local_offer_outlined),
                                  title: Text(summary.story.title),
                                  subtitle: Text(
                                    l.storiesCount(summary.eventCount),
                                  ),
                                  trailing: Icon(
                                    summary.canModify
                                        ? Icons.chevron_right
                                        : Icons.lock_outline,
                                  ),
                                  onTap: () => Navigator.push<void>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StoryDetailPage(
                                        storyId: summary.story.id,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
              ),
        ],
      ),
    );
  }
}
