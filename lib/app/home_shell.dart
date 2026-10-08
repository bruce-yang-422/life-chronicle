import 'package:flutter/material.dart';

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

  static const _pages = <Widget>[
    TimelinePage(),
    SearchPage(),
    NewEventPage(),
    StoriesPage(),
    BackupPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      // 保留各分頁狀態（捲動位置、編輯中內容）
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.schedule_outlined),
            selectedIcon: const Icon(Icons.schedule),
            label: l10n.navTimeline,
          ),
          NavigationDestination(
            icon: const Icon(Icons.search),
            label: l10n.navSearch,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline),
            selectedIcon: const Icon(Icons.add_circle),
            label: l10n.navNewEvent,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: l10n.navStories,
          ),
          NavigationDestination(
            icon: const Icon(Icons.storage_outlined),
            selectedIcon: const Icon(Icons.storage),
            label: l10n.navBackup,
          ),
        ],
      ),
    );
  }
}
