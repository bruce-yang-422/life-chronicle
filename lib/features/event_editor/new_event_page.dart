import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/editor/event_draft.dart';
import '../../core/time/time_format.dart';
import '../../core/time/time_value.dart';
import '../../data/providers.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../data/repositories/event_draft_store.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_time_texts.dart';
import '../attachments/attachment_import.dart';
import '../event_detail/event_detail_page.dart';
import 'event_selection_sheet.dart';
import 'time_picker_sheet.dart';
import 'location_picker_page.dart';
import '../../core/location/location_anchor.dart';
import '../security/security_dialogs.dart';
import '../shared/markdown_content.dart';

class NewEventPage extends ConsumerStatefulWidget {
  const NewEventPage({super.key, this.eventId});
  final String? eventId;
  @override
  ConsumerState<NewEventPage> createState() => _NewEventPageState();
}

class _NewEventPageState extends ConsumerState<NewEventPage> {
  EventDraft _draft = EventDraft();
  EventDraftStore? _store;
  bool _loading = true, _busy = false, _restored = false;
  bool _draftError = false, _titleError = false;
  bool _locating = false, _locationError = false;

  void _setLocation(LocationAnchor anchor) {
    setState(() {
      _draft.latitude = anchor.latitude;
      _draft.longitude = anchor.longitude;
      _draft.radiusM = anchor.radiusM;
      _locationError = false;
    });
    _changed();
  }

  Future<void> _currentLocation() async {
    setState(() => _locating = true);
    try {
      final anchor = await ref.read(locationPlatformProvider).current();
      if (mounted) _setLocation(anchor);
    } catch (error) {
      if (mounted &&
          !(error is PlatformException && error.code == 'location_cancelled')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).locationUnavailable),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _chooseLocation() async {
    final chosen = await Navigator.push<LocationAnchor>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          privateCoordinates: _draft.privacy == 'private',
          initial: _draft.latitude == null
              ? null
              : LocationAnchor(
                  _draft.latitude!,
                  _draft.longitude!,
                  radiusM: _draft.radiusM,
                ),
        ),
      ),
    );
    if (chosen != null && mounted) _setLocation(chosen);
  }

  int _version = 0;
  String _pendingPerson = '';
  String get _key => widget.eventId ?? 'new';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final store = await ref.read(eventDraftStoreProvider.future);
      final saved = await store.load(_key);
      EventDraft? initial;
      if (saved == null && widget.eventId != null) {
        final content = await (await ref.read(
          eventContentRepositoryProvider.future,
        )).load(widget.eventId!);
        if (content == null) throw StateError('missing');
        initial = content.toDraft();
      }
      if (!mounted) return;
      setState(() {
        _store = store;
        _draft = saved ?? initial ?? EventDraft();
        if (_draft.sections.isEmpty) {
          _draft.sections.add(DraftSection());
        }
        _restored = saved != null;
        _loading = false;
        _draftError = false;
        _version++;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _draftError = true;
          _loading = false;
        });
      }
    }
  }

  void _changed() {
    if (_store == null || _busy) return;
    // 每次輸入立即排入持久性寫入，退出時不依賴 debounce。
    _store!.save(_key, _draft).catchError((Object error) {
      if (mounted) setState(() => _draftError = true);
    });
  }

  List<AttachmentSource> get _sources => [
    for (final value in _draft.attachments)
      AttachmentSource(
        value['path']!,
        value['name']!,
        referenceId: value['referenceId'],
      ),
  ];
  Future<void> _addAttachments() async {
    if (_store == null) return;
    setState(() => _busy = true);
    try {
      final repository = await ref.read(attachmentRepositoryProvider.future);
      if (!mounted) return;
      final plan = await pickImportPlan(context, repository, forDraft: true);
      if (plan == null || !mounted) return;
      final token = ImportCancellation();
      final retained = await withImportProgress(
        context,
        token,
        (progress) =>
            repository.retainForDraft(plan, token, onProgress: progress),
      );
      _draft.attachments.addAll(
        retained.map(
          (file) => {
            'path': file.path,
            'name': file.name,
            'referenceId': file.referenceId!,
          },
        ),
      );
      await _store!.save(_key, _draft);
      if (mounted) setState(() {});
      final located = plan.files
          .where(
            (file) =>
                file.metadata.latitude != null &&
                file.metadata.longitude != null,
          )
          .toList();
      if (located.isNotEmpty && mounted) {
        final l = AppLocalizations.of(context);
        var chosen = located.length == 1 ? located.first : null;
        final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setLocal) => AlertDialog(
              title: Text(l.locationPhotoSuggestion),
              content: SizedBox(
                width: 400,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final file in located)
                      ListTile(
                        title: Text(file.source.name),
                        subtitle: Text(
                          l.locationCoordinates(
                            file.metadata.latitude!.toStringAsFixed(6),
                            file.metadata.longitude!.toStringAsFixed(6),
                          ),
                        ),
                        leading: Icon(
                          chosen == file
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                        ),
                        onTap: () => setLocal(() => chosen = file),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l.timelineCancel),
                ),
                FilledButton(
                  onPressed: chosen == null
                      ? null
                      : () => Navigator.pop(context, true),
                  child: Text(l.locationUsePhoto),
                ),
              ],
            ),
          ),
        );
        if (accepted == true && mounted) {
          _setLocation(
            LocationAnchor(
              chosen!.metadata.latitude!,
              chosen!.metadata.longitude!,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) showImportError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_locationError || _locating) return;
    if (_draft.title.trim().isEmpty) {
      setState(() => _titleError = true);
      return;
    }
    if (_store == null) return;
    setState(() => _busy = true);
    try {
      final repository = await ref.read(eventContentRepositoryProvider.future);
      if (_draft.eventId == null) {
        _draft.creationId ??= repository.reserveCreationId();
      }
      await _store!.save(_key, _draft);
      final sources = _sources;
      String id;
      final committed = _draft.eventId == null && _draft.creationId != null
          ? await repository.load(_draft.creationId!)
          : null;
      if (committed != null) {
        id = committed.event.id;
      } else if (sources.isEmpty) {
        id = await repository.save(_draft);
      } else {
        final media = await ref.read(attachmentRepositoryProvider.future);
        if (!mounted) return;
        final token = ImportCancellation();
        id = await withImportProgress(context, token, (progress) async {
          final plan = await media.prepare(
            sources,
            cancellation: token,
            onProgress: progress,
          );
          return media.importBatch(
            plan,
            saveEvent: () => repository.save(_draft),
            cancellation: token,
            onProgress: progress,
          );
        });
      }
      await _store!.remove(_key);
      if (sources.isNotEmpty) {
        try {
          await (await ref.read(attachmentRepositoryProvider.future))
              .releaseDraftSources(sources);
        } catch (_) {
          /* 成功的事件與附件已保存；不將清理失敗誤報為匯入失敗。 */
        }
      }
      if (!mounted) return;
      if (widget.eventId != null) {
        Navigator.pop(context);
      } else {
        setState(() {
          _draft = EventDraft();
          _restored = false;
          _titleError = false;
          _version++;
        });
        await openEventDetail(context, id);
      }
    } catch (error) {
      if (mounted) {
        if (error is ImportCancelled ||
            error is ImportSpaceException ||
            error is ImportIntegrityException) {
          showImportError(context, error);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).editorError)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _discard() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l.editorDiscardConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.timelineCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.editorDiscard),
          ),
        ],
      ),
    );
    if (confirmed != true || _store == null) return;
    final sources = _sources;
    await _store!.remove(_key);
    if (sources.isNotEmpty) {
      await (await ref.read(attachmentRepositoryProvider.future))
          .releaseDraftSources(sources);
    }
    if (!mounted) return;
    if (widget.eventId != null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _draft = EventDraft();
        _version++;
        _restored = false;
      });
    }
  }

  Future<void> _addSection() async {
    final l = AppLocalizations.of(context);
    final suggestions = <String, String>{
      'cause': l.sectionCause,
      'process': l.sectionProcess,
      'result': l.sectionResult,
      'feeling': l.sectionFeeling,
      'difficulty': l.sectionDifficulty,
      'insight': l.sectionInsight,
      'people': l.sectionPeople,
      'scene': l.sectionScene,
      'words': l.sectionWords,
    };
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(l.editorCustomSection),
              onTap: () => Navigator.pop(context, 'custom'),
            ),
            for (final entry in suggestions.entries)
              ListTile(
                title: Text(entry.value),
                onTap: () => Navigator.pop(context, entry.key),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    setState(
      () => _draft.sections.add(
        DraftSection(
          title: suggestions[choice] ?? '',
          suggestionKey: choice == 'custom' ? null : choice,
        ),
      ),
    );
    _changed();
  }

  void _move(int index, int next) {
    if (next < 0 || next >= _draft.sections.length) return;
    setState(() {
      final item = _draft.sections.removeAt(index);
      _draft.sections.insert(next, item);
    });
    _changed();
  }

  Widget _section(int index, AppLocalizations l) {
    final section = _draft.sections[index];
    return Card(
      key: ObjectKey(section),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextFormField(
              initialValue: section.title,
              decoration: InputDecoration(labelText: l.editorSectionTitle),
              onChanged: (value) {
                section.title = value;
                _changed();
              },
            ),
            MarkdownEditor(
              initialValue: section.content,
              label: l.editorNarrative,
              onChanged: (value) {
                section.content = value;
                _changed();
              },
            ),
            Wrap(
              children: [
                IconButton(
                  tooltip: l.editorMoveUp,
                  onPressed: index > 0 ? () => _move(index, index - 1) : null,
                  icon: const Icon(Icons.arrow_upward),
                ),
                IconButton(
                  tooltip: l.editorMoveDown,
                  onPressed: index < _draft.sections.length - 1
                      ? () => _move(index, index + 1)
                      : null,
                  icon: const Icon(Icons.arrow_downward),
                ),
                IconButton(
                  tooltip: l.editorRemoveSection,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() => _draft.sections.removeAt(index));
                    _changed();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nameSuggestions({
    required String label,
    required String initial,
    required Future<List<String>> Function(String) suggestions,
    required ValueChanged<String> onChanged,
  }) => Autocomplete<String>(
    initialValue: TextEditingValue(text: initial),
    optionsBuilder: (value) => suggestions(value.text),
    onSelected: onChanged,
    fieldViewBuilder: (context, controller, focus, onSubmitted) => TextField(
      controller: controller,
      focusNode: focus,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    ),
  );
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final time = _draft.time;
    if (!_loading &&
        _draft.privacy == 'private' &&
        !ref.watch(securityProvider).canReadPrivate) {
      return Scaffold(
        body: Center(
          child: TextButton.icon(
            icon: const Icon(Icons.lock_outline),
            label: Text(l.securityPrivateUnlock),
            onPressed: () => authorizePrivate(context),
          ),
        ),
      );
    }
    final references = time is RelativeTime
        ? ref.watch(eventReferencesProvider)
        : null;
    final referenceEvent = time is RelativeTime
        ? references?.value
              ?.where((item) => item.id == time.eventId)
              .firstOrNull
        : null;
    final referenceTitle = referenceEvent == null
        ? null
        : referenceEvent.privacy == 'private' &&
              !ref.watch(securityProvider).canReadPrivate
        ? l.securityPrivateEvent
        : referenceEvent.deletedAt == null
        ? referenceEvent.title
        : l.recycleDeletedTitle(referenceEvent.title);
    final timeLabel = references?.isLoading == true
        ? l.pickerRelative
        : TimeFormat.full(
            time,
            L10nTimeTexts(l),
            relatedEventTitle: referenceTitle,
          );
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : AbsorbPointer(
            absorbing: _busy,
            child: ListView(
              key: ValueKey(_version),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.eventId == null ? l.navNewEvent : l.editorEdit,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (_restored) Text(l.editorRestored),
                if (_draftError)
                  Row(
                    children: [
                      Expanded(child: Text(l.editorDraftError)),
                      TextButton(
                        onPressed: _load,
                        child: Text(l.timelineRetry),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _draft.title,
                  decoration: InputDecoration(
                    labelText: l.editorName,
                    errorText: _titleError ? l.editorRequired : null,
                  ),
                  onChanged: (value) {
                    _draft.title = value;
                    if (_titleError && value.trim().isNotEmpty) {
                      setState(() => _titleError = false);
                    }
                    _changed();
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final value = await chooseTime(
                      context,
                      _draft.time,
                      excludeId: widget.eventId,
                    );
                    if (value != null && mounted) {
                      setState(() => _draft.time = value);
                      _changed();
                    }
                  },
                  label: Text(l.editorTimeValue(timeLabel)),
                ),
                ...[
                  TextFormField(
                    initialValue: _draft.category,
                    decoration: InputDecoration(labelText: l.editorCategory),
                    onChanged: (value) {
                      _draft.category = value;
                      _changed();
                    },
                  ),
                  _nameSuggestions(
                    label: l.editorPlace,
                    initial: _draft.place,
                    suggestions: (text) async =>
                        (await (await ref.read(placeRepositoryProvider.future))
                                .suggest(text))
                            .map((place) => place.name!)
                            .toList(),
                    onChanged: (value) {
                      _draft.place = value;
                      _changed();
                    },
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: _locating ? null : _currentLocation,
                        icon: const Icon(Icons.my_location),
                        label: Text(l.locationCurrent),
                      ),
                      TextButton.icon(
                        onPressed: _chooseLocation,
                        icon: const Icon(Icons.map_outlined),
                        label: Text(l.locationMapPick),
                      ),
                    ],
                  ),
                  if (_locating) ...[
                    Text(l.locationAwaitGps),
                    TextButton(
                      onPressed: () =>
                          ref.read(locationPlatformProvider).cancel(),
                      child: Text(l.timelineCancel),
                    ),
                  ],
                  if (_draft.latitude != null) ...[
                    Text(
                      l.locationCoordinates(
                        _draft.latitude!.toStringAsFixed(6),
                        _draft.longitude!.toStringAsFixed(6),
                      ),
                    ),
                    TextFormField(
                      key: ValueKey(
                        'radius-${_draft.latitude}-${_draft.longitude}',
                      ),
                      initialValue: _draft.radiusM?.toString() ?? '',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l.locationRadius,
                        errorText: _locationError ? l.locationInvalid : null,
                      ),
                      onChanged: (value) {
                        final number = double.tryParse(value);
                        setState(() {
                          _locationError =
                              value.trim().isNotEmpty &&
                              (number == null ||
                                  !number.isFinite ||
                                  number <= 0);
                          _draft.radiusM = number;
                        });
                        _changed();
                      },
                    ),
                  ],
                  _nameSuggestions(
                    label: l.editorPeople,
                    initial: '',
                    suggestions: (text) async =>
                        (await (await ref.read(personRepositoryProvider.future))
                                .suggest(text))
                            .map((person) => person.displayName)
                            .toList(),
                    onChanged: (value) => _pendingPerson = value,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      if (_pendingPerson.trim().isNotEmpty) {
                        setState(() {
                          _draft.people.add(_pendingPerson.trim());
                          _pendingPerson = '';
                        });
                        _changed();
                      }
                    },
                    icon: const Icon(Icons.person_add),
                    label: Text(l.editorAddPerson),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final person in _draft.people.toSet())
                        InputChip(
                          label: Text(person),
                          onDeleted: () {
                            setState(() => _draft.people.remove(person));
                            _changed();
                          },
                        ),
                    ],
                  ),
                  TextFormField(
                    initialValue: _draft.tags.join(', '),
                    decoration: InputDecoration(labelText: l.editorTags),
                    onChanged: (value) {
                      _draft.tags = value
                          .split(RegExp('[,，]'))
                          .map((v) => v.trim())
                          .where((v) => v.isNotEmpty)
                          .toList();
                      _changed();
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _draft.privacy,
                    decoration: InputDecoration(labelText: l.editorPrivacy),
                    items: [
                      DropdownMenuItem(
                        value: 'normal',
                        child: Text(l.editorNormal),
                      ),
                      DropdownMenuItem(
                        value: 'private',
                        child: Text(l.editorPrivate),
                      ),
                    ],
                    onChanged: (value) {
                      _draft.privacy = value!;
                      _changed();
                    },
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      final ids = await chooseEvents(
                        context,
                        selected: _draft.relatedIds,
                        excludeId: widget.eventId,
                      );
                      if (ids != null && mounted) {
                        setState(() => _draft.relatedIds = ids);
                        _changed();
                      }
                    },
                    child: Text(
                      '${l.editorRelated} (${_draft.relatedIds.length})',
                    ),
                  ),
                ],
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  onReorderItem: _move,
                  children: [
                    for (var i = 0; i < _draft.sections.length; i++)
                      _section(i, l),
                  ],
                ),
                TextButton.icon(
                  onPressed: _addSection,
                  icon: const Icon(Icons.add),
                  label: Text(l.editorAddSection),
                ),
                OutlinedButton.icon(
                  onPressed: _addAttachments,
                  icon: const Icon(Icons.attach_file),
                  label: Text(l.editorAttachments),
                ),
                for (final file in _draft.attachments)
                  ListTile(title: Text(file['name']!)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _store == null || _locating ? null : _save,
                  child: Text(l.editorSave),
                ),
                TextButton(onPressed: _discard, child: Text(l.editorDiscard)),
                const SizedBox(height: 32),
              ],
            ),
          );
    return widget.eventId == null
        ? SafeArea(child: body)
        : Scaffold(
            appBar: AppBar(title: Text(l.editorEdit)),
            body: body,
          );
  }
}
