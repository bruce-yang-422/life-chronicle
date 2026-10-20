import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/timeline_sort.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';

Future<List<String>?> chooseEvents(
  BuildContext context, {
  List<String> selected = const [],
  String? excludeId,
  bool multiple = true,
  String? confirmLabel,
}) => showModalBottomSheet<List<String>>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _EventSelection(
    selected: selected,
    excludeId: excludeId,
    multiple: multiple,
    confirmLabel: confirmLabel,
  ),
);

class _EventSelection extends ConsumerStatefulWidget {
  const _EventSelection({
    required this.selected,
    required this.multiple,
    this.excludeId,
    this.confirmLabel,
  });
  final List<String> selected;
  final String? excludeId;
  final bool multiple;
  final String? confirmLabel;
  @override
  ConsumerState<_EventSelection> createState() => _EventSelectionState();
}

class _EventSelectionState extends ConsumerState<_EventSelection> {
  late final _selected = widget.selected.toSet();
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: InputDecoration(labelText: l.searchQuery),
                onChanged: (value) =>
                    setState(() => _query = value.toLowerCase()),
              ),
            ),
            Expanded(
              child: ref
                  .watch(timelineItemsProvider)
                  .when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text(l.timelineLoadError)),
                    data: (data) {
                      final items =
                          TimelineSort.sort(
                                data,
                                ref.watch(timelineDirectionProvider),
                              )
                              .where(
                                (item) =>
                                    item.id != widget.excludeId &&
                                    (ref
                                            .watch(securityProvider)
                                            .canReadPrivate ||
                                        item.data.privacy != 'private') &&
                                    item.data.title.toLowerCase().contains(
                                      _query,
                                    ),
                              )
                              .toList();
                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          if (!widget.multiple) {
                            return ListTile(
                              title: Text(item.data.title),
                              onTap: () => Navigator.pop(context, [item.id]),
                            );
                          }
                          return CheckboxListTile(
                            title: Text(item.data.title),
                            value: _selected.contains(item.id),
                            onChanged: (checked) => setState(() {
                              if (checked == true) {
                                _selected.add(item.id);
                              } else {
                                _selected.remove(item.id);
                              }
                            }),
                          );
                        },
                      );
                    },
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _selected.toList()),
                child: Text(widget.confirmLabel ?? l.editorRelated),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
