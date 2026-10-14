import 'package:markdown/markdown.dart' as md;

import 'commonmark_writer.dart';

/// CommonMark 內容閱讀版。JSON 保留原文；封存標題下的內容標題從三級開始。
abstract final class MarkdownDocument {
  static final extensionSet = md.ExtensionSet([
    ...md.ExtensionSet.commonMark.blockSyntaxes,
    const md.TableSyntax(),
  ], md.ExtensionSet.commonMark.inlineSyntaxes);
  static List<md.Node> _parse(String source) =>
      md.Document(extensionSet: extensionSet, encodeHtml: false).parseLines(
        source.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n'),
      );

  static String source(String value) =>
      _parse(value).map(_block).join('\n\n').trimRight();
  static String html(String value) => _parse(value).map(_html).join('\n');

  static String? _href(md.Element element) {
    final value = element.attributes['href'];
    final uri = value == null ? null : Uri.tryParse(value);
    if (uri == null ||
        !['http', 'https', 'mailto'].contains(uri.scheme.toLowerCase()) ||
        RegExp(r'[\s<>]').hasMatch(value!)) {
      return null;
    }
    return value;
  }

  static String _inline(md.Node node) {
    if (node is md.Text) return CommonMarkWriter.text(node.text);
    final e = node as md.Element;
    final content = (e.children ?? []).map(_inline).join();
    return switch (e.tag) {
      'strong' => '**$content**',
      'em' => '*$content*',
      'code' => _code(e.textContent),
      'br' => '\\\n',
      'a' => _href(e) == null ? content : '[$content](<${_href(e)}>)',
      'img' => CommonMarkWriter.text(e.attributes['alt'] ?? ''),
      _ => content,
    };
  }

  static String _code(String value) {
    final longest = RegExp(r'`+')
        .allMatches(value)
        .fold(0, (int n, m) => m[0]!.length > n ? m[0]!.length : n);
    final fence = '`' * (longest + 1);
    final padding =
        value.startsWith('`') ||
            value.endsWith('`') ||
            value.startsWith(' ') && value.endsWith(' ')
        ? ' '
        : '';
    return '$fence$padding$value$padding$fence';
  }

  static String _block(md.Node node) {
    if (node is md.Text) return CommonMarkWriter.text(node.text);
    final e = node as md.Element;
    final children = e.children ?? [];
    if (RegExp(r'^h[1-6]$').hasMatch(e.tag)) {
      final level = (int.parse(e.tag[1]) + 2).clamp(3, 6);
      return '${'#' * level} ${children.map(_inline).join()}';
    }
    switch (e.tag) {
      case 'table':
        final headers = <md.Element>[];
        final rows = <md.Element>[];
        for (final part in children.whereType<md.Element>()) {
          for (final row in (part.children ?? []).whereType<md.Element>()) {
            if (part.tag == 'thead') {
              headers.addAll((row.children ?? []).whereType<md.Element>());
            } else if (part.tag == 'tbody') {
              rows.add(row);
            }
          }
        }
        if (rows.isEmpty) {
          return headers.map((h) => '- ${_inline(h)}').join('\n');
        }
        return [
          for (var r = 0; r < rows.length; r++)
            '${r + 1}. ${[for (var c = 0; c < headers.length; c++) '${_inline(headers[c]).isEmpty ? '${c + 1}' : _inline(headers[c])}: ${c < (rows[r].children ?? []).length ? _inline(rows[r].children![c]) : ''}'].join('\n   - ')}',
        ].join('\n\n');
      case 'pre':
        final value = e.textContent;
        final longest = RegExp(r'`+')
            .allMatches(value)
            .fold(2, (int n, m) => m[0]!.length > n ? m[0]!.length : n);
        final fence = '`' * (longest + 1);
        return '$fence\n$value${value.endsWith('\n') ? '' : '\n'}$fence';
      case 'blockquote':
        return children
            .map(_block)
            .join('\n\n')
            .split('\n')
            .map((line) => '> $line')
            .join('\n');
      case 'ul':
      case 'ol':
        var index = int.tryParse(e.attributes['start'] ?? '') ?? 1;
        return children
            .map((child) {
              final prefix = e.tag == 'ul' ? '- ' : '${index++}. ';
              final lines = _block(child).split('\n');
              return '$prefix${lines.first}${lines.skip(1).map((line) => '\n${' ' * prefix.length}$line').join()}';
            })
            .join('\n');
      case 'li':
        final parts = <String>[];
        var inline = '';
        for (final child in children) {
          if (child is md.Element &&
              ['p', 'ul', 'ol', 'blockquote', 'pre'].contains(child.tag)) {
            if (inline.isNotEmpty) {
              parts.add(inline);
              inline = '';
            }
            parts.add(_block(child));
          } else {
            inline += _inline(child);
          }
        }
        if (inline.isNotEmpty) parts.add(inline);
        return parts.join('\n\n');
      case 'hr':
        return '---';
      default:
        return children.map(_inline).join();
    }
  }

  static String _html(md.Node node) {
    if (node is md.Text) {
      return CommonMarkWriter.html(node.text).replaceAll('\n', '<br>\n');
    }
    final e = node as md.Element;
    if (e.tag == 'img') return CommonMarkWriter.html(e.attributes['alt'] ?? '');
    final content = (e.children ?? []).map(_html).join();
    if (e.tag == 'table') {
      return '<div style="overflow-x:auto"><table>$content</table></div>';
    }
    if (['thead', 'tbody', 'tr', 'th', 'td'].contains(e.tag)) {
      final align = e.attributes['align'];
      final style = ['left', 'center', 'right'].contains(align)
          ? ' style="text-align:$align"'
          : '';
      return '<${e.tag}$style>$content</${e.tag}>';
    }
    if (e.tag == 'a') {
      final href = _href(e);
      return href == null
          ? content
          : '<a href="${CommonMarkWriter.html(href)}">$content</a>';
    }
    if (e.tag == 'pre') {
      return '<pre><code>${CommonMarkWriter.html(e.textContent)}</code></pre>';
    }
    if (e.tag == 'code') {
      return '<code>${CommonMarkWriter.html(e.textContent)}</code>';
    }
    if (RegExp(r'^h[1-6]$').hasMatch(e.tag)) {
      final tag = 'h${(int.parse(e.tag[1]) + 2).clamp(3, 6)}';
      return '<$tag>$content</$tag>';
    }
    if (['br', 'hr'].contains(e.tag)) return '<${e.tag}>';
    if (![
      'p',
      'strong',
      'em',
      'ul',
      'ol',
      'li',
      'blockquote',
    ].contains(e.tag)) {
      return content;
    }
    final start = e.tag == 'ol'
        ? int.tryParse(e.attributes['start'] ?? '')
        : null;
    return '<${e.tag}${start == null ? '' : ' start="$start"'}>$content</${e.tag}>';
  }
}
