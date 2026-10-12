import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../features/backup/backup_page.dart';
import '../features/event_editor/new_event_page.dart';
import '../features/search/search_page.dart';
import '../features/stories/stories_page.dart';
import '../features/timeline/timeline_page.dart';
import '../l10n/app_localizations.dart';

/// 主畫面外殼：五個主分頁與底部導覽列（企劃書第 4 節）。
///
/// 平板的側邊導覽與雙欄版面於 T14 實作。
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  late final _pages = <Widget>[
    TimelinePage(onNewEvent: () => setState(() => _index = 2)),
    const SearchPage(),
    const NewEventPage(),
    const StoriesPage(),
    const BackupPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      // 保留各分頁狀態（捲動位置、編輯中內容）
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant
                  .withValues(alpha: .6),
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
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
              icon: const Icon(CupertinoIcons.book),
              selectedIcon: const Icon(Icons.menu_book),
              label: l10n.navStories,
            ),
            NavigationDestination(
              icon: const Icon(CupertinoIcons.layers),
              selectedIcon: const Icon(Icons.storage),
              label: l10n.navBackup,
            ),
          ],
        ),
      ),
    );
  }
}
