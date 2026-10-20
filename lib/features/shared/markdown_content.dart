import 'package:flutter/material.dart';

import 'writing_field.dart';

import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../core/archive/markdown_document.dart';
import '../../core/archive/commonmark_writer.dart';

import '../../l10n/app_localizations.dart';

/// 不自動載入遠端或任意本機圖片；照片統一透過附件倉庫管理。
class MarkdownContent extends StatelessWidget {
  const MarkdownContent(this.source, {super.key});
  final String source;
  @override
  Widget build(BuildContext context) => MarkdownBody(
    data: source,
    selectable: true,
    extensionSet: MarkdownDocument.extensionSet,
    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      tableColumnWidth: const IntrinsicColumnWidth(),
      tableCellsPadding: const EdgeInsets.all(8),
    ),
    softLineBreak: true,
    imageBuilder: (uri, title, alt) => Text(
      alt?.isNotEmpty == true
          ? alt!
          : AppLocalizations.of(context).mdAttachmentImage,
    ),
    onTapLink: (text, href, title) async {
      if (href == null) return;
      await Clipboard.setData(ClipboardData(text: href));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).mdLinkCopied)),
        );
      }
    },
  );
}

/// TextFormField 保留手機鍵盤的 emoji、組字狀態及選取；預覽不修改原文。
class MarkdownEditor extends StatefulWidget {
  const MarkdownEditor({
    super.key,
    this.initialValue = '',
    this.controller,
    required this.onChanged,
    required this.label,
  });
  final String initialValue, label;
  final TextEditingController? controller;
  final ValueChanged<String> onChanged;
  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor> {
  late final TextEditingController _controller;
  bool _preview = false;
  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _wrap(String delimiter) {
    final selection = _controller.selection;
    final start = selection.isValid ? selection.start : _controller.text.length;
    final end = selection.isValid ? selection.end : start;
    final selected = _controller.text.substring(start, end);
    _controller.value = TextEditingValue(
      text: _controller.text.replaceRange(
        start,
        end,
        '$delimiter$selected$delimiter',
      ),
      selection: TextSelection(
        baseOffset: start + delimiter.length,
        extentOffset: start + delimiter.length + selected.length,
      ),
    );
    widget.onChanged(_controller.text);
    setState(() {});
  }

  void _table(String template) {
    final selection = _controller.selection;
    final start = selection.isValid ? selection.start : _controller.text.length;
    final end = selection.isValid ? selection.end : start;
    final inserted = '\n\n$template\n\n';
    _controller.value = TextEditingValue(
      text: _controller.text.replaceRange(start, end, inserted),
      selection: TextSelection.collapsed(offset: start + inserted.length),
    );
    widget.onChanged(_controller.text);
    setState(() {});
  }

  void _lines(String Function(String, int) transform) {
    final text = _controller.text;
    final selection = _controller.selection;
    final cursor = selection.isValid ? selection.start : text.length;
    final endCursor = selection.isValid ? selection.end : cursor;
    final start = cursor == 0 ? 0 : text.lastIndexOf('\n', cursor - 1) + 1;
    final searchEnd = endCursor > cursor ? endCursor - 1 : endCursor;
    final newline = text.indexOf('\n', searchEnd);
    final end = newline < 0 ? text.length : newline;
    final lines = text.substring(start, end).split('\n');
    final changed = [
      for (var i = 0; i < lines.length; i++) transform(lines[i], i),
    ].join('\n');
    _controller.value = TextEditingValue(
      text: text.replaceRange(start, end, changed),
      selection: TextSelection(
        baseOffset: start,
        extentOffset: start + changed.length,
      ),
    );
    widget.onChanged(_controller.text);
    setState(() {});
  }

  String _list(String line, String marker) {
    final indent = RegExp(r'^\s*').firstMatch(line)![0]!;
    final body = line
        .substring(indent.length)
        .replaceFirst(RegExp(r'^(?:[-+*]|\d+[.)])\s+'), '');
    return '$indent$marker $body';
  }

  Future<void> _link() async {
    final l = AppLocalizations.of(context);
    final selection = _controller.selection;
    final start = selection.isValid ? selection.start : _controller.text.length;
    final end = selection.isValid ? selection.end : start;
    final label = TextEditingController(
      text: _controller.text.substring(start, end),
    );
    final url = TextEditingController();
    var invalid = false;
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(l.mdLink),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: label,
                  decoration: InputDecoration(labelText: l.mdLinkText),
                ),
                TextField(
                  controller: url,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: l.mdLinkUrl,
                    errorText: invalid ? l.mdLinkInvalid : null,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.timelineCancel),
            ),
            FilledButton(
              onPressed: () {
                final uri = Uri.tryParse(url.text.trim());
                if (uri == null ||
                    !['http', 'https'].contains(uri.scheme) ||
                    uri.host.isEmpty ||
                    label.text.trim().isEmpty) {
                  setLocal(() => invalid = true);
                  return;
                }
                Navigator.pop(context, (label.text.trim(), uri.toString()));
              },
              child: Text(l.mdInsert),
            ),
          ],
        ),
      ),
    );
    Future<void>.delayed(const Duration(seconds: 1), () {
      label.dispose();
      url.dispose();
    });
    if (result == null || !mounted) return;
    final text =
        '[${CommonMarkWriter.text(result.$1.replaceAll('\n', ' '))}](<${result.$2.replaceAll('<', '%3C').replaceAll('>', '%3E')}>)';
    _controller.value = TextEditingValue(
      text: _controller.text.replaceRange(start, end, text),
      selection: TextSelection.collapsed(offset: start + text.length),
    );
    widget.onChanged(_controller.text);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final toolbar = DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Wrap(
          children: [
            PopupMenuButton<int>(
              tooltip: l.mdHeading,
              enabled: !_preview,
              icon: const Icon(Icons.title),
              itemBuilder: (context) => [
                for (var level = 1; level <= 6; level++)
                  PopupMenuItem(
                    value: level,
                    child: Text(l.mdHeadingLevel(level)),
                  ),
              ],
              onSelected: (level) => _lines(
                (line, index) =>
                    '${'#' * level} ${line.replaceFirst(RegExp(r'^#{1,6}\s+'), '')}',
              ),
            ),
            IconButton(
              tooltip: l.mdTable,
              onPressed: _preview ? null : () => _table(l.mdTableTemplate),
              icon: const Icon(Icons.table_chart_outlined),
            ),
            IconButton(
              tooltip: l.mdBold,
              onPressed: _preview ? null : () => _wrap('**'),
              icon: const Icon(Icons.format_bold),
            ),
            IconButton(
              tooltip: l.mdItalic,
              onPressed: _preview ? null : () => _wrap('*'),
              icon: const Icon(Icons.format_italic),
            ),
            IconButton(
              tooltip: l.mdBullets,
              onPressed: _preview
                  ? null
                  : () => _lines((line, index) => _list(line, '-')),
              icon: const Icon(Icons.format_list_bulleted),
            ),
            IconButton(
              tooltip: l.mdNumbers,
              onPressed: _preview
                  ? null
                  : () => _lines((line, index) => _list(line, '${index + 1}.')),
              icon: const Icon(Icons.format_list_numbered),
            ),
            IconButton(
              tooltip: l.mdIndent,
              onPressed: _preview
                  ? null
                  : () => _lines((line, index) => '    $line'),
              icon: const Icon(Icons.format_indent_increase),
            ),
            IconButton(
              tooltip: l.mdOutdent,
              onPressed: _preview
                  ? null
                  : () => _lines(
                      (line, index) =>
                          line.replaceFirst(RegExp(r'^(?: {1,4}|\t)'), ''),
                    ),
              icon: const Icon(Icons.format_indent_decrease),
            ),
            IconButton(
              tooltip: l.mdCode,
              onPressed: _preview ? null : () => _wrap('`'),
              icon: const Icon(Icons.code),
            ),
            IconButton(
              tooltip: l.mdLink,
              onPressed: _preview ? null : _link,
              icon: const Icon(Icons.link),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _preview = !_preview),
              icon: Icon(
                _preview ? Icons.edit_outlined : Icons.visibility_outlined,
              ),
              label: Text(_preview ? l.mdEdit : l.mdPreview),
            ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        if (_preview)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _controller.text.trim().isEmpty
                ? Text(l.mdEmptyPreview)
                : MarkdownContent(_controller.text),
          )
        else
          TextFormField(
            controller: _controller,
            minLines: 6,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            decoration: writingDecoration(context, l.editorBodyHint),
            onChanged: widget.onChanged,
          ),
        const SizedBox(height: 8),
        toolbar,
        const SizedBox(height: 8),
        Text(l.mdHint, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
