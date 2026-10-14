import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/time_format.dart';
import '../../core/time/time_value.dart';
import '../../core/time/timeline_sort.dart';
import '../../data/providers.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/timeline_repository.dart';
import '../../data/repositories/timeline_preferences_store.dart';
import '../../data/repositories/timeline_demo_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_time_texts.dart';
import 'timeline_filter_sheet.dart';
import 'timeline_masthead.dart';
import '../event_detail/event_detail_page.dart';
import '../../core/time/elapsed_time.dart';
import '../../core/time/calendar_date.dart';
import '../../core/time/timestamp_display.dart';
import '../../l10n/l10n_elapsed_time.dart';
import '../settings/time_display_settings.dart';

/// 時間軸首頁：年份索引與可視年份分開載入（T07）。
class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key, this.onNewEvent});
  final VoidCallback? onNewEvent;

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage>
    with WidgetsBindingObserver {
  Timer? _dayTimer;
  CalendarDate? _lastDay;
  CalendarDate _today() {
    final value = TimestampDisplay.convert(
      DateTime.now(),
      ref.read(timeZoneProvider).value ?? 'system',
    );
    return CalendarDate(value.year, value.month, value.day);
  }

  void _refreshDay() {
    if (mounted && _lastDay != null && _lastDay != _today()) {
      setState(() => _lastDay = _today());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshDay();
  }

  double get _rowExtent =>
      (_cards ? 184 : 80) * MediaQuery.textScalerOf(context).scale(14) / 14;
  bool _cards = false;
  bool _preferencesLoaded = false;
  final _collapsed = <int?>{};
  late ScrollController _scroll = ScrollController()..addListener(_trackYear);
  SortDirection _direction = SortDirection.newestFirst;
  int? _centerYear;
  bool _hasCenter = false;
  int _scrollVersion = 0;
  bool _showRail = false;
  Timer? _railTimer;
  bool _generating = false;
  final _firstContentWatch = Stopwatch()..start();
  bool _reportedFirstContent = false;

  Future<void> _generateDemo(int count) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.timelineDemo),
        content: Text(l10n.timelineDemoConfirm(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.timelineCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.timelineGenerate),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _generating = true);
    try {
      final context = await ref.read(repositoryContextProvider.future);
      await TimelineDemoRepository(context).generate(
        count,
        title: l10n.timelineDemoTitle,
        category: l10n.timelineDemoCategory,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.timelineLoadError)));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dayTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshDay(),
    );
    _restorePreferences();
  }

  Future<void> _restorePreferences() async {
    try {
      final store = await ref.read(timelinePreferencesStoreProvider.future);
      final preferences = await store.load();
      if (!mounted) return;
      ref.read(timelineDirectionProvider.notifier).set(preferences.direction);
      setState(() {
        _direction = preferences.direction;
        _cards = preferences.cards;
        _preferencesLoaded = true;
        _hasCenter = false;
        _replaceScroll(0);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _preferencesLoaded = true);
      _preferencesError();
    }
  }

  Future<void> _savePreferences() async {
    final preferences = TimelinePreferences(
      direction: _direction,
      cards: _cards,
    );
    try {
      final store = await ref.read(timelinePreferencesStoreProvider.future);
      await store.save(preferences);
    } catch (error) {
      if (mounted) _preferencesError();
    }
  }

  void _preferencesError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).timelinePreferencesError),
      ),
    );
  }

  void _toggleDensity() {
    final year = _centerYear;
    final position = _scroll.hasClients
        ? (_scroll.offset - _yearOffset(year, _direction)).clamp(
            0,
            double.infinity,
          )
        : 0.0;
    final index = (position / _rowExtent).floor();
    final fraction = (position % _rowExtent) / _rowExtent;
    setState(() {
      _cards = !_cards;
      _replaceScroll(
        _yearOffset(year, _direction) + (index + fraction) * _rowExtent,
      );
    });
    _savePreferences();
  }

  Future<void> _chooseFilter() async {
    ref.invalidate(timelineFilterOptionsProvider);
    final filter = await showModalBottomSheet<TimelineFilter>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const TimelineFilterSheet(),
    );
    if (filter == null || !mounted) return;
    ref.read(timelineFilterProvider.notifier).apply(filter);
    setState(() {
      _hasCenter = false;
      _replaceScroll(0);
    });
  }

  List<TimelineYearCount> _orderedCounts(SortDirection direction) {
    final counts = ref.read(timelineYearsProvider).value ?? [];
    final byYear = {for (final count in counts) count.year: count};
    return [
      for (final year in TimelineSort.orderYears(byYear.keys, direction))
        byYear[year]!,
    ];
  }

  double _yearOffset(int? year, SortDirection direction) {
    var offset = 0.0;
    for (final count in _orderedCounts(direction)) {
      if (count.year == year) break;
      offset +=
          56 + (_collapsed.contains(count.year) ? 0 : count.count * _rowExtent);
    }
    return offset;
  }

  void _trackYear() {
    if (!_scroll.hasClients) return;
    if (!_showRail) setState(() => _showRail = true);
    _railTimer?.cancel();
    _railTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _showRail = false);
    });
    var offset = _scroll.offset;
    for (final count in _orderedCounts(_direction)) {
      final height =
          56 + (_collapsed.contains(count.year) ? 0 : count.count * _rowExtent);
      if (offset < height) {
        if (!_hasCenter || _centerYear != count.year) {
          setState(() {
            _centerYear = count.year;
            _hasCenter = true;
          });
        }
        return;
      }
      offset -= height;
    }
  }

  void _replaceScroll(double offset) {
    final oldScroll = _scroll;
    _scroll = ScrollController(initialScrollOffset: offset)
      ..addListener(_trackYear);
    _scrollVersion++;
    WidgetsBinding.instance.addPostFrameCallback((_) => oldScroll.dispose());
  }

  void _toggleDirection() {
    final year = _centerYear;
    final data = _hasCenter
        ? ref.read(timelineYearProvider((year: year, previews: _cards))).value
        : null;
    final position = _scroll.hasClients
        ? _scroll.offset - _yearOffset(year, _direction)
        : 0.0;
    final index = position < 56 ? 0 : (position / _rowExtent).ceil();
    final oldItems = data == null
        ? null
        : TimelineSort.sort(data.items, _direction);
    final anchorIndex = oldItems == null || oldItems.isEmpty
        ? 0
        : index.clamp(0, oldItems.length - 1);
    final id = oldItems != null && oldItems.isNotEmpty
        ? oldItems[anchorIndex].id
        : null;
    setState(() {
      _direction = _direction == SortDirection.newestFirst
          ? SortDirection.oldestFirst
          : SortDirection.newestFirst;
      ref.read(timelineDirectionProvider.notifier).set(_direction);
      var offset = _yearOffset(year, _direction);
      if (id != null) {
        final items = TimelineSort.sort(data!.items, _direction);
        final newIndex = items.indexWhere((item) => item.id == id);
        offset += (newIndex * _rowExtent + position - anchorIndex * _rowExtent)
            .clamp(0, double.infinity);
      }
      _replaceScroll(offset);
    });
    _savePreferences();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dayTimer?.cancel();
    _railTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  String _yearLabel(AppLocalizations l10n, int? year) =>
      year == null ? l10n.timeUnknown : l10n.timeYearFull('$year');

  void _jump(int? year) {
    setState(() {
      _centerYear = year;
      _hasCenter = true;
      _collapsed.remove(year);
      _replaceScroll(_yearOffset(year, _direction));
    });
  }

  Future<void> _chooseYear(List<TimelineYearCount> counts) async {
    final l10n = AppLocalizations.of(context);
    final byYear = {for (final count in counts) count.year: count.count};
    final years = TimelineSort.orderYears(byYear.keys, _direction);
    var query = '';
    final result = await showModalBottomSheet<(int?,)>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .7,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.timelineChooseYear,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.today),
                  title: Text(l10n.timelineThisYear),
                  enabled: byYear.containsKey(DateTime.now().year),
                  onTap: () => Navigator.pop(context, (DateTime.now().year,)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.timelineEnterYear,
                    ),
                    onChanged: (value) =>
                        setSheetState(() => query = value.trim()),
                    onSubmitted: (value) {
                      final year = int.tryParse(value);
                      if (byYear.containsKey(year) && year != null) {
                        Navigator.pop(context, (year,));
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: years
                        .where(
                          (year) => query.isEmpty || '$year'.contains(query),
                        )
                        .length,
                    itemBuilder: (context, index) {
                      final year = years
                          .where(
                            (year) => query.isEmpty || '$year'.contains(query),
                          )
                          .elementAt(index);
                      return ListTile(
                        title: Text(_yearLabel(l10n, year)),
                        trailing: Text(l10n.timelineCount(byYear[year]!)),
                        onTap: () => Navigator.pop(context, (year,)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted) _jump(result.$1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final counts = ref.watch(timelineYearsProvider);
    final filter = ref.watch(timelineFilterProvider);
    if (!_hasCenter && counts.hasValue && counts.value!.isNotEmpty) {
      _centerYear = TimelineSort.orderYears(
        counts.value!.map((count) => count.year),
        _direction,
      ).first;
      _hasCenter = true;
    }
    return SafeArea(
      child: Column(
        children: [
          TimelineMasthead(trailing: kDebugMode ? _demoMenu(l10n) : null),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 125,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary
                          .withValues(alpha: .08),
                    ),
                    onPressed: counts.hasValue && counts.value!.isNotEmpty
                        ? () => _chooseYear(counts.value!)
                        : null,
                    icon: const Icon(Icons.expand_more),
                    label: Text(
                      _hasCenter
                          ? _yearLabel(l10n, _centerYear)
                          : l10n.timelineChooseYear,
                    ),
                  ),
                ),
                TextButton.icon(
                  style: _toolbarStyle(context),
                  onPressed: _preferencesLoaded ? _toggleDirection : null,
                  icon: const Icon(Icons.swap_vert),
                  label: Text(
                    _direction == SortDirection.newestFirst
                        ? l10n.timelineNewestFirst
                        : l10n.timelineOldestFirst,
                  ),
                ),
                TextButton.icon(
                  style: _toolbarStyle(context),
                  onPressed: _chooseFilter,
                  icon: const Icon(Icons.filter_list),
                  label: Text(l10n.timelineFilter),
                ),
                IconButton(
                  style: _toolbarStyle(context),
                  onPressed: _preferencesLoaded ? _toggleDensity : null,
                  tooltip: _cards ? l10n.timelineCompact : l10n.timelineCards,
                  icon: Icon(
                    _cards ? Icons.view_list : Icons.view_agenda_outlined,
                  ),
                ),
              ],
            ),
          ),
          if (filter.isActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final label in _filterLabels(l10n, filter))
                          Chip(label: Text(label)),
                        Text(
                          l10n.timelineMatches(
                            (counts.value ?? []).fold<int>(
                              0,
                              (sum, count) => sum + count.count,
                            ),
                            (ref.watch(timelineAllYearsProvider).value ?? [])
                                .fold<int>(
                                  0,
                                  (sum, count) => sum + count.count,
                                ),
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.timelineClear,
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      ref
                          .read(timelineFilterProvider.notifier)
                          .apply(const TimelineFilter());
                      setState(() {
                        _hasCenter = false;
                        _replaceScroll(0);
                      });
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: counts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  _failure(l10n, () => ref.invalidate(timelineYearsProvider)),
              data: (counts) {
                if (counts.isEmpty) {
                  return Center(child: Text(l10n.timelineEmpty));
                }
                final byYear = {
                  for (final count in counts) count.year: count.count,
                };
                final years = TimelineSort.orderYears(byYear.keys, _direction);
                if (!_hasCenter || !byYear.containsKey(_centerYear)) {
                  _centerYear = years.first;
                  _hasCenter = true;
                }
                return Stack(
                  children: [
                    CustomScrollView(
                      key: ValueKey(_scrollVersion),
                      controller: _scroll,
                      slivers: [
                        for (final year in years)
                          SliverMainAxisGroup(
                            key: ValueKey(year),
                            slivers: [
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: _YearHeader(
                                  label: l10n.timelineYearCount(
                                    byYear[year]!,
                                    _yearLabel(l10n, year),
                                  ),
                                  collapsed: _collapsed.contains(year),
                                  onTap: () => setState(() {
                                    if (!_collapsed.add(year)) {
                                      _collapsed.remove(year);
                                    }
                                  }),
                                ),
                              ),
                              if (!_collapsed.contains(year))
                                SliverLayoutBuilder(
                                  builder: (context, constraints) {
                                    final extent = byYear[year]! * _rowExtent;
                                    // 遠離可視範圍時只保留高度，不啟動年份查詢。
                                    if (constraints.remainingPaintExtent <= 0 ||
                                        constraints.scrollOffset >= extent) {
                                      return SliverToBoxAdapter(
                                        child: SizedBox(height: extent),
                                      );
                                    }
                                    return Consumer(
                                      builder: (context, ref, child) {
                                        final data = ref.watch(
                                          timelineYearProvider((
                                            year: year,
                                            previews: _cards,
                                          )),
                                        );
                                        return data.when(
                                          loading: () => SliverToBoxAdapter(
                                            child: SizedBox(
                                              height: extent,
                                              child: const Align(
                                                alignment: Alignment.topCenter,
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            ),
                                          ),
                                          error: (error, stack) =>
                                              SliverToBoxAdapter(
                                                child: SizedBox(
                                                  height: extent,
                                                  child: Align(
                                                    alignment:
                                                        Alignment.topCenter,
                                                    child: _failure(
                                                      l10n,
                                                      () => ref.invalidate(
                                                        timelineYearProvider((
                                                          year: year,
                                                          previews: _cards,
                                                        )),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          data: (data) {
                                            if ((kDebugMode || kProfileMode) &&
                                                !_reportedFirstContent &&
                                                data.items.isNotEmpty) {
                                              _reportedFirstContent = true;
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                    debugPrint(
                                                      'TIMELINE_FIRST_CONTENT_MS=${_firstContentWatch.elapsedMilliseconds} '
                                                      'COUNT=${counts.fold<int>(0, (sum, count) => sum + count.count)}',
                                                    );
                                                  });
                                            }
                                            final items = TimelineSort.sort(
                                              data.items,
                                              _direction,
                                            );
                                            return SliverFixedExtentList.builder(
                                              itemExtent: _rowExtent,
                                              itemCount: items.length,
                                              itemBuilder: (context, index) {
                                                final item = items[index];
                                                final month = _month(item.time);
                                                final previousMonth = index == 0
                                                    ? null
                                                    : _month(
                                                        items[index - 1].time,
                                                      );
                                                return _eventRow(
                                                  item,
                                                  data,
                                                  items.length > 30 &&
                                                          month != null &&
                                                          month != previousMonth
                                                      ? l10n.timeListMonth(
                                                          '$month',
                                                        )
                                                      : null,
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                            ],
                          ),
                      ],
                    ),
                    if (_showRail && years.length > 1)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: 40,
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: Slider(
                            label: _yearLabel(l10n, _centerYear),
                            semanticFormatterCallback: (value) =>
                                _yearLabel(l10n, years[value.round()]),
                            value: years
                                .indexOf(_centerYear)
                                .clamp(0, years.length - 1)
                                .toDouble(),
                            max: (years.length - 1).toDouble(),
                            divisions: years.length - 1,
                            onChanged: (value) => _jump(years[value.round()]),
                          ),
                        ),
                      ),
                    if (widget.onNewEvent != null)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton(
                          onPressed: widget.onNewEvent,
                          tooltip: l10n.navNewEvent,
                          child: const Icon(Icons.add),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _failure(AppLocalizations l10n, VoidCallback retry) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.timelineLoadError),
        TextButton(onPressed: retry, child: Text(l10n.timelineRetry)),
      ],
    ),
  );

  ButtonStyle _toolbarStyle(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextButton.styleFrom(
      foregroundColor: colors.onSurface,
      backgroundColor: colors.surfaceContainerLow,
      side: BorderSide(color: colors.outlineVariant.withValues(alpha: .75)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      minimumSize: const Size(48, 48),
    );
  }

  Widget _demoMenu(AppLocalizations l10n) => PopupMenuButton<int>(
    tooltip: l10n.timelineDemo,
    enabled: !_generating,
    icon: _generating
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.more_horiz, size: 20),
    onSelected: _generateDemo,
    itemBuilder: (context) => [
      for (final count in [1000, 5000])
        PopupMenuItem(value: count, child: Text(l10n.timelineDemoCount(count))),
    ],
  );

  int? _month(TimeValue time) => switch (time) {
    DayTime(:final month) || MonthTime(:final month) => month,
    _ => null,
  };

  Widget _eventRow(
    TimelineItem<Event> item,
    TimelineYearData data,
    String? monthLabel,
  ) {
    final l10n = AppLocalizations.of(context);
    final time = item.time;
    ref.watch(timeZoneProvider);
    _lastDay = _today();
    final elapsed = elapsedTimeLabel(
      ElapsedTime.calculate(time, _lastDay!),
      l10n,
    );
    final privacyLocked =
        item.data.privacy == 'private' &&
        !ref.watch(securityProvider).canReadPrivate;
    final date = TimeFormat.list(
      time,
      L10nTimeTexts(l10n),
      relatedEventTitle: time is RelativeTime
          ? data.deletedReferenceIds.contains(time.eventId)
                ? l10n.recycleDeletedTitle(data.referenceTitles[time.eventId]!)
                : data.referenceTitles[time.eventId]
          : null,
    );
    final preview = privacyLocked
        ? const TimelinePreview()
        : data.previews[item.id] ?? const TimelinePreview();
    final title = privacyLocked
        ? Tooltip(
            message: l10n.securityPrivateEvent,
            child: const Icon(Icons.lock_outline),
          )
        : HeroMode(
            enabled: !MediaQuery.disableAnimationsOf(context),
            child: Hero(
              tag: 'event-title-${item.id}',
              child: Material(
                type: MaterialType.transparency,
                child: Text(
                  item.data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          );
    final contents = _cards
        ? Card(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                date,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                elapsed,
                                maxLines: 2,
                                textAlign: TextAlign.end,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        title,
                        if (preview.summary.isNotEmpty)
                          Text(
                            preview.summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (!privacyLocked)
                          Text(
                            l10n.timelineAttachments(preview.attachmentCount),
                          ),
                      ],
                    ),
                  ),
                  if (preview.imagePath != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _TimelineThumbnail(
                        key: ValueKey(preview.imagePath),
                        path: preview.imagePath!,
                        label: preview.imageLabel,
                      ),
                    ),
                ],
              ),
            ),
          )
        : Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant
                    .withValues(alpha: .35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .018),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        elapsed,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.3,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: title),
                if (!privacyLocked && item.data.category != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 64),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary
                            .withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.data.category!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
    return GestureDetector(
      onTap: () => openEventDetail(context, item.id, title: item.data.title),
      child: Column(
        key: ValueKey(item.id),
        children: [
          if (monthLabel != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  monthLabel,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
          Expanded(child: contents),
        ],
      ),
    );
  }

  List<String> _filterLabels(AppLocalizations l10n, TimelineFilter filter) {
    final options = ref.watch(timelineFilterOptionsProvider).value;
    String label(
      String id,
      List<TimelineFilterOption>? options,
      String fallback,
    ) =>
        options?.where((option) => option.id == id).firstOrNull?.label ??
        fallback;
    return [
      if (filter.category != null) filter.category!,
      if (filter.lifePeriodId != null)
        label(
          filter.lifePeriodId!,
          options?.lifePeriods,
          l10n.timelineLifePeriod,
        ),
      if (filter.tagId != null)
        label(filter.tagId!, options?.tags, l10n.timelineTag),
      if (filter.personId != null)
        label(filter.personId!, options?.people, l10n.timelinePerson),
      if (filter.placeId != null)
        label(filter.placeId!, options?.places, l10n.timelinePlace),
      if (filter.layer != null)
        filter.layer == 'original'
            ? l10n.timelineOriginal
            : l10n.timelineRemembrance,
    ];
  }
}

/// 縮圖只在可視列建立，離開時從圖片快取釋放。
class _TimelineThumbnail extends StatefulWidget {
  const _TimelineThumbnail({super.key, required this.path, this.label});
  final String path;
  final String? label;
  @override
  State<_TimelineThumbnail> createState() => _TimelineThumbnailState();
}

class _TimelineThumbnailState extends State<_TimelineThumbnail> {
  late final ImageProvider _image = ResizeImage(
    FileImage(File(widget.path)),
    width: 192,
    height: 192,
    policy: ResizeImagePolicy.fit,
  );
  @override
  void dispose() {
    _image.evict();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Image(
    image: _image,
    width: 80,
    height: 80,
    fit: BoxFit.cover,
    semanticLabel: widget.label,
    errorBuilder: (context, error, stack) => const SizedBox(
      width: 80,
      height: 80,
      child: Icon(Icons.image_not_supported_outlined),
    ),
  );
}

class _YearHeader extends SliverPersistentHeaderDelegate {
  const _YearHeader({
    required this.label,
    required this.collapsed,
    required this.onTap,
  });
  final String label;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox.expand(
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: true,
          expanded: !collapsed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Icon(collapsed ? Icons.expand_more : Icons.expand_less),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  @override
  bool shouldRebuild(_YearHeader oldDelegate) =>
      label != oldDelegate.label ||
      collapsed != oldDelegate.collapsed ||
      onTap != oldDelegate.onTap;
}
