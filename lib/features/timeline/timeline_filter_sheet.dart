import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/db/tables.dart';
import '../../data/repositories/timeline_repository.dart';
import '../../l10n/app_localizations.dart';

/// 各欄位單選，避免將空字串或沒有選項誤當成已套用的條件。
class TimelineFilterSheet extends ConsumerStatefulWidget {
  const TimelineFilterSheet({super.key});
  @override
  ConsumerState<TimelineFilterSheet> createState() =>
      _TimelineFilterSheetState();
}

class _TimelineFilterSheetState extends ConsumerState<TimelineFilterSheet> {
  late TimelineFilter _filter = ref.read(timelineFilterProvider);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = ref.watch(timelineFilterOptionsProvider);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .8,
        child: options.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(timelineFilterOptionsProvider),
              child: Text(l10n.timelineRetry),
            ),
          ),
          data: (options) => ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                l10n.timelineFilter,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              _field(
                l10n.timelineCategory,
                options.categories,
                _filter.category,
                (value) => _change(category: value),
              ),
              _field(
                l10n.timelineLifePeriod,
                options.lifePeriods,
                _filter.lifePeriodId,
                (value) => _change(lifePeriodId: value),
              ),
              _field(
                l10n.timelineTag,
                options.tags,
                _filter.tagId,
                (value) => _change(tagId: value),
              ),
              _field(
                l10n.timelinePerson,
                options.people,
                _filter.personId,
                (value) => _change(personId: value),
              ),
              _field(
                l10n.timelinePlace,
                options.places,
                _filter.placeId,
                (value) => _change(placeId: value),
              ),
              _field(
                l10n.timelineLayer,
                [
                  TimelineFilterOption(Layer.original, l10n.timelineOriginal),
                  TimelineFilterOption(
                    Layer.remembrance,
                    l10n.timelineRemembrance,
                  ),
                ],
                _filter.layer,
                (value) => _change(layer: value),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context, _filter),
                child: Text(l10n.timelineApply),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, const TimelineFilter()),
                child: Text(l10n.timelineClear),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    List<TimelineFilterOption> options,
    String? selected,
    ValueChanged<String?> change,
  ) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: DropdownButtonFormField<String>(
        key: ValueKey((label, selected)),
        initialValue: selected,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem(value: null, child: Text(l10n.timelineAll)),
          if (selected != null &&
              !options.any((option) => option.id == selected))
            DropdownMenuItem(
              value: selected,
              child: Text(l10n.timelineUnavailableFilter),
            ),
          for (final option in options)
            DropdownMenuItem(
              value: option.id,
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: change,
      ),
    );
  }

  void _change({
    Object? category = _unset,
    Object? lifePeriodId = _unset,
    Object? tagId = _unset,
    Object? personId = _unset,
    Object? placeId = _unset,
    Object? layer = _unset,
  }) {
    setState(
      () => _filter = TimelineFilter(
        category: category == _unset ? _filter.category : category as String?,
        lifePeriodId: lifePeriodId == _unset
            ? _filter.lifePeriodId
            : lifePeriodId as String?,
        tagId: tagId == _unset ? _filter.tagId : tagId as String?,
        personId: personId == _unset ? _filter.personId : personId as String?,
        placeId: placeId == _unset ? _filter.placeId : placeId as String?,
        layer: layer == _unset ? _filter.layer : layer as String?,
      ),
    );
  }
}

const _unset = Object();
