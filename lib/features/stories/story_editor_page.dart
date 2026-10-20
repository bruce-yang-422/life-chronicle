import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/stories/theme_rule.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../data/repositories/story_repository.dart';
import '../../l10n/app_localizations.dart';
import '../shared/ios_group.dart';

class StoryEditorPage extends ConsumerStatefulWidget {
  const StoryEditorPage({super.key, this.initial});
  final StoryContent? initial;
  @override
  ConsumerState<StoryEditorPage> createState() => _StoryEditorPageState();
}

class _StoryEditorPageState extends ConsumerState<StoryEditorPage> {
  late final _title = TextEditingController(
    text: widget.initial?.summary.story.title ?? '',
  );
  late final ThemeRule? _initialRule =
      widget.initial?.summary.story.rulesJson == null
      ? null
      : ThemeRule.decode(widget.initial!.summary.story.rulesJson!);
  late TagMatchMode _mode = _initialRule?.mode ?? TagMatchMode.all;
  late final _include = {...?_initialRule?.include};
  late final _exclude = {...?_initialRule?.exclude};
  bool _busy = false, _required = false, _tagRequired = false;
  String _query = '';

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _include.isEmpty) {
      setState(() {
        _required = _title.text.trim().isEmpty;
        _tagRequired = _include.isEmpty;
      });
      return;
    }
    setState(() => _busy = true);
    final l = AppLocalizations.of(context);
    try {
      await (await ref.read(storyRepositoryProvider.future)).save(
        id: widget.initial?.summary.story.id,
        title: _title.text,
        rule: ThemeRule(mode: _mode, include: _include, exclude: _exclude),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.storiesError)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _tags(AppLocalizations l, List<Tag> tags, bool exclude, bool enabled) {
    final selected = exclude ? _exclude : _include;
    final other = exclude ? _include : _exclude;
    final names = {for (final t in tags) t.id: t.label};
    return IosGroup(
      title: exclude ? l.themesExclude : l.themesInclude,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in tags.where(
                (t) => t.label.toLowerCase().contains(_query.toLowerCase()),
              ))
                FilterChip(
                  key: ValueKey('${exclude ? 'exclude' : 'include'}-${tag.id}'),
                  label: Text(tag.label),
                  selected: selected.contains(tag.id),
                  onSelected: !enabled || other.contains(tag.id)
                      ? null
                      : (value) => setState(() {
                          if (value) {
                            selected.add(tag.id);
                          } else {
                            selected.remove(tag.id);
                          }
                          if (_include.isNotEmpty) _tagRequired = false;
                        }),
                ),
              for (final id in selected.where((id) => !names.containsKey(id)))
                InputChip(
                  label: Text(l.themesMissingTag),
                  onDeleted: enabled
                      ? () => setState(() => selected.remove(id))
                      : null,
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tags = ref.watch(storyTagsProvider);
    final storyId = widget.initial?.summary.story.id;
    final current = storyId == null
        ? null
        : ref.watch(storyContentProvider(storyId));
    final enabled =
        storyId == null || current?.value?.summary.canModify == true;
    return Scaffold(
      appBar: AppBar(
        title: Text(storyId == null ? l.storiesCreate : l.storiesEdit),
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (!enabled) Text(l.storiesReadOnly),
            if (widget.initial != null && _initialRule == null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(l.themesLegacy),
              ),
            IosGroup(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    key: const ValueKey('story-title'),
                    controller: _title,
                    enabled: enabled,
                    decoration: InputDecoration(
                      labelText: l.storiesTitle,
                      errorText: _required ? l.editorRequired : null,
                    ),
                    onChanged: (_) {
                      if (_required) setState(() => _required = false);
                    },
                  ),
                ),
              ],
            ),
            IosGroup(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonFormField<TagMatchMode>(
                    key: const ValueKey('theme-mode'),
                    initialValue: _mode,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.themesMode),
                    items: [
                      DropdownMenuItem(
                        value: TagMatchMode.all,
                        child: Text(l.themesAll),
                      ),
                      DropdownMenuItem(
                        value: TagMatchMode.any,
                        child: Text(l.themesAny),
                      ),
                    ],
                    onChanged: !enabled
                        ? null
                        : (value) => setState(() => _mode = value!),
                  ),
                ),
              ],
            ),
            Text(l.themesAutoUpdate),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('theme-tag-search'),
              decoration: InputDecoration(labelText: l.themesSearchTags),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 12),
            tags.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => TextButton(
                onPressed: () => ref.invalidate(storyTagsProvider),
                child: Text(l.timelineRetry),
              ),
              data: (values) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (values.isEmpty) Text(l.themesNoTags),
                  _tags(l, values, false, enabled),
                  _tags(l, values, true, enabled),
                ],
              ),
            ),
            if (_tagRequired)
              Semantics(
                liveRegion: true,
                child: Text(
                  l.themesChooseTag,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton(
              onPressed: enabled && !_busy && tags.hasValue ? _save : null,
              child: Text(l.storiesSave),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
