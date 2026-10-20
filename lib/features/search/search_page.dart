import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/time_format.dart';
import '../../core/time/time_value.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_time_texts.dart';
import '../event_detail/event_detail_page.dart';
import '../shared/ios_group.dart';

/// 搜尋與視圖（T11 實作）。
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});
  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _query = TextEditingController();
  final _from = TextEditingController();
  final _to = TextEditingController();
  // 空白條件代表所有可讀紀錄，首次開啟便顯示結果，不留下沒有說明的空白頁。
  ({String query, int? from, int? to})? _request = (
    query: '',
    from: null,
    to: null,
  );
  bool _invalid = false;
  @override
  void dispose() {
    _query.dispose();
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  void _search() {
    final from = int.tryParse(_from.text.trim());
    final to = int.tryParse(_to.text.trim());
    final invalid =
        (_from.text.trim().isNotEmpty &&
            (from == null || from < 1 || from > 9999)) ||
        (_to.text.trim().isNotEmpty && (to == null || to < 1 || to > 9999)) ||
        (from != null && to != null && from > to);
    if (!invalid) FocusScope.of(context).unfocus();
    setState(() {
      _invalid = invalid;
      if (!invalid) _request = (query: _query.text.trim(), from: from, to: to);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: CustomScrollView(
        key: const PageStorageKey('search-scroll'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IosPageTitle(l.navSearch),
                  TextField(
                    key: const ValueKey('search-query'),
                    controller: _query,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l.searchQuery,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final sideBySide =
                          constraints.maxWidth >= 320 &&
                          MediaQuery.textScalerOf(context).scale(16) <= 20;
                      final width = sideBySide
                          ? (constraints.maxWidth - 8) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: width,
                            child: TextField(
                              key: const ValueKey('search-from'),
                              controller: _from,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                labelText: l.searchFrom,
                              ),
                              onSubmitted: (_) => _search(),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: TextField(
                              key: const ValueKey('search-to'),
                              controller: _to,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                labelText: l.searchTo,
                              ),
                              onSubmitted: (_) => _search(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (_invalid)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        l.searchInvalid,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const ValueKey('search-submit'),
                    onPressed: _search,
                    icon: const Icon(Icons.search),
                    label: Text(l.searchAction),
                  ),
                ],
              ),
            ),
          ),
          if (_request != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: ref
                  .watch(searchResultsProvider(_request!))
                  .when(
                    loading: () => const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, stack) => SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text(l.timelineLoadError)),
                    ),
                    data: (results) {
                      final items = results
                          .where(
                            (item) =>
                                ref.watch(securityProvider).canReadPrivate ||
                                item.data.privacy != 'private',
                          )
                          .toList();
                      return items.isEmpty
                          ? SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(child: Text(l.searchNoResults)),
                            )
                          : SliverList.separated(
                              itemCount: items.length,
                              separatorBuilder: (context, index) => ColoredBox(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow,
                                child: const Divider(indent: 16),
                              ),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final time = item.time;
                                final references = time is RelativeTime
                                    ? ref.watch(eventReferencesProvider)
                                    : null;
                                final referenceEvent = time is RelativeTime
                                    ? references?.value
                                          ?.where(
                                            (item) => item.id == time.eventId,
                                          )
                                          .firstOrNull
                                    : null;
                                final referenceTitle = referenceEvent == null
                                    ? L10nTimeTexts(l).deletedReferenceTitle(
                                        time,
                                        canReadPrivate: ref
                                            .watch(securityProvider)
                                            .canReadPrivate,
                                      )
                                    : referenceEvent.privacy == 'private' &&
                                          !ref
                                              .watch(securityProvider)
                                              .canReadPrivate
                                    ? l.securityPrivateEvent
                                    : referenceEvent.deletedAt == null
                                    ? referenceEvent.title
                                    : l.recycleDeletedTitle(
                                        referenceEvent.title,
                                      );
                                return ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: index == 0
                                          ? const Radius.circular(12)
                                          : Radius.zero,
                                      bottom: index == items.length - 1
                                          ? const Radius.circular(12)
                                          : Radius.zero,
                                    ),
                                  ),
                                  title: Text(item.data.title),
                                  subtitle: Text(
                                    references?.isLoading == true
                                        ? l.pickerRelative
                                        : TimeFormat.full(
                                            item.time,
                                            L10nTimeTexts(l),
                                            relatedEventTitle: referenceTitle,
                                          ),
                                  ),
                                  leading: item.data.privacy == 'private'
                                      ? Tooltip(
                                          message: l.searchPrivate,
                                          child: const Icon(Icons.lock_outline),
                                        )
                                      : null,
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => openEventDetail(
                                    context,
                                    item.id,
                                    title: item.data.title,
                                  ),
                                );
                              },
                            );
                    },
                  ),
            ),
        ],
      ),
    );
  }
}
