import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/time_format.dart';
import '../../core/time/time_value.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_time_texts.dart';
import '../event_detail/event_detail_page.dart';

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
    setState(() {
      _invalid = invalid;
      if (!invalid) _request = (query: _query.text.trim(), from: from, to: to);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  l.navSearch,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                TextField(
                  controller: _query,
                  decoration: InputDecoration(labelText: l.searchQuery),
                  onSubmitted: (_) => _search(),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _from,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l.searchFrom),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _to,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l.searchTo),
                      ),
                    ),
                  ],
                ),
                if (_invalid)
                  Text(
                    l.searchInvalid,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                FilledButton.icon(
                  onPressed: _search,
                  icon: const Icon(Icons.search),
                  label: Text(l.searchAction),
                ),
              ],
            ),
          ),
          if (_request != null)
            Expanded(
              child: ref
                  .watch(searchResultsProvider(_request!))
                  .when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text(l.timelineLoadError)),
                    data: (results) {
                      final items = results
                          .where(
                            (item) =>
                                ref.watch(securityProvider).canReadPrivate ||
                                item.data.privacy != 'private',
                          )
                          .toList();
                      return items.isEmpty
                          ? Center(child: Text(l.searchNoResults))
                          : ListView.builder(
                              itemCount: items.length,
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
                                    ? null
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
