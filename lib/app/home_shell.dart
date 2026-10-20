import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../features/event_detail/event_detail_page.dart';

import '../features/backup/backup_page.dart';
import '../features/event_editor/new_event_page.dart';
import '../features/search/search_page.dart';
import '../features/stories/stories_page.dart';
import '../features/timeline/timeline_page.dart';
import '../l10n/app_localizations.dart';

/// 主畫面外殼：五個主分頁與底部導覽列（企劃書第 4 節）。
///
/// 依寬度切換導覽，分頁始終保留在相同元件位置。
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  final _visited = <int>{0};
  void _select(int index) => setState(() {
    _index = index;
    _visited.add(index);
  });

  late final _pages = <Widget>[
    TimelinePage(onNewEvent: () => _select(2)),
    _bounded(const SearchPage()),
    _bounded(const NewEventPage()),
    _bounded(const StoriesPage()),
    _bounded(const BackupPage()),
  ];

  Widget _bounded(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: SizedBox.expand(child: child),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final rail = width >= 600;
    final selected = ref.watch(selectedEventProvider);
    final showDetail = selected != null && (_index == 0 || _index == 1);
    final destinations = [
      (Icons.history, l10n.navTimeline),
      (Icons.search, l10n.navSearch),
      (Icons.add_circle_outline, l10n.navNewEvent),
      (Icons.local_offer_outlined, l10n.navStories),
      (Icons.backup_outlined, l10n.navBackup),
    ];
    return Scaffold(
      // 保留各分頁狀態（捲動位置、編輯中內容）
      body: PopScope(
        canPop: !showDetail,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) ref.read(selectedEventProvider.notifier).clear();
        },
        child: Row(
          children: [
            SizedBox(
              width: rail ? 88 : 0,
              child: rail
                  ? SafeArea(
                      child: SingleChildScrollView(
                        child: IntrinsicHeight(
                          child: NavigationRail(
                            selectedIndex: _index,
                            onDestinationSelected: _select,
                            labelType: NavigationRailLabelType.all,
                            destinations: [
                              for (final item in destinations)
                                NavigationRailDestination(
                                  icon: Icon(item.$1),
                                  label: Text(item.$2),
                                ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: Stack(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: IndexedStack(
                          index: _index,
                          children: [
                            for (var i = 0; i < _pages.length; i++)
                              _visited.contains(i)
                                  ? HeroMode(
                                      enabled:
                                          _index == i &&
                                          !MediaQuery.disableAnimationsOf(
                                            context,
                                          ),
                                      child: TickerMode(
                                        enabled: _index == i,
                                        child: _pages[i],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                          ],
                        ),
                      ),
                      if (width > 840 && (_index == 0 || _index == 1))
                        Expanded(
                          child: showDetail
                              ? HeroMode(
                                  enabled: false,
                                  child: EventDetailPage(
                                    eventId: selected.id,
                                    initialTitle: selected.title,
                                    onClose: () => ref
                                        .read(selectedEventProvider.notifier)
                                        .clear(),
                                  ),
                                )
                              : Center(child: Text(l10n.detailSelectEvent)),
                        ),
                    ],
                  ),
                  if (showDetail && width <= 840)
                    Positioned.fill(
                      child: HeroMode(
                        enabled: false,
                        child: EventDetailPage(
                          eventId: selected.id,
                          initialTitle: selected.title,
                          onClose: () =>
                              ref.read(selectedEventProvider.notifier).clear(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: rail
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant
                        .withValues(alpha: .6),
                  ),
                ),
              ),
              child: NavigationBar(
                height: 56 * MediaQuery.textScalerOf(context).scale(10) / 10,
                selectedIndex: _index,
                onDestinationSelected: _select,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(CupertinoIcons.clock),
                    selectedIcon: const Icon(CupertinoIcons.clock_fill),
                    label: l10n.navTimeline,
                  ),
                  NavigationDestination(
                    icon: const Icon(CupertinoIcons.search),
                    label: l10n.navSearch,
                  ),
                  NavigationDestination(
                    icon: const Icon(CupertinoIcons.add_circled),
                    selectedIcon: const Icon(CupertinoIcons.add_circled_solid),
                    label: l10n.navNewEvent,
                  ),
                  NavigationDestination(
                    icon: const Icon(CupertinoIcons.tag),
                    selectedIcon: const Icon(CupertinoIcons.tag_fill),
                    label: l10n.navStories,
                  ),
                  NavigationDestination(
                    icon: const Icon(CupertinoIcons.layers),
                    selectedIcon: const Icon(CupertinoIcons.layers_fill),
                    label: l10n.navBackup,
                  ),
                ],
              ),
            ),
    );
  }
}
