import 'dart:convert';

import '../time/calendar_date.dart';
import '../time/sort_range.dart';
import '../time/time_format.dart';
import '../time/time_texts.dart';
import '../time/time_value.dart';
import '../time/timeline_sort.dart';
import 'commonmark_writer.dart';
import 'markdown_document.dart';

typedef ArchiveRows = Map<String, List<Map<String, Object?>>>;

class _ReadingSortContext implements SortContext {
  _ReadingSortContext(this.times, this.birth);
  final Map<String, TimeValue> times;
  final CalendarTime? birth;
  @override
  TimeValue? timeOfEvent(String id) => times[id];
  @override
  CalendarTime? subjectBirth() => birth;
}

/// 文字來源由多語系層注入；閱讀檔只衍生自權威 JSON。
class ArchiveReading {
  ArchiveReading(this.labels, this.timeTexts, {this.timestampFormat});
  final Map<String, String> labels;
  final TimeTexts timeTexts;
  final String Function(DateTime)? timestampFormat;
  String _timestamp(String raw) =>
      timestampFormat?.call(DateTime.parse(raw)) ?? raw;
  String label(String key) => labels[key]!;

  Map<String, String> generate(ArchiveRows data) {
    final events = data['events']!;
    final authors = {
      for (final row in data['authors']!) row['author_id']: row['display_name'],
    };
    final blobs = {for (final row in data['blobs']!) row['blob_id']: row};
    final subjects = {
      for (final row in data['subjects']!) row['subject_id']: row,
    };
    final times = {
      for (final row in events)
        row['event_id'] as String: TimeValue.fromJson(
          jsonDecode(row['time_payload'] as String) as Map<String, Object?>,
        ),
    };
    final items = <TimelineItem<Map<String, Object?>>>[];
    for (final event in events) {
      final birthPayload = subjects[event['subject_id']]?['birth_date'];
      final birth = birthPayload == null
          ? null
          : TimeValue.fromJson(
              jsonDecode(birthPayload as String) as Map<String, Object?>,
            );
      final id = event['event_id'] as String;
      final start = event['sort_start'] as String?;
      final end = event['sort_end'] as String?;
      items.add(
        TimelineItem(
          id: id,
          time: times[id]!,
          resolution: SortRangeResolver.resolve(
            times[id]!,
            _ReadingSortContext(times, birth is CalendarTime ? birth : null),
            selfId: id,
            previous: start == null || end == null
                ? null
                : SortResolved(
                    SortRange(
                      CalendarDate.parse(start),
                      CalendarDate.parse(end),
                    ),
                    TimeCertainty.exact,
                  ),
          ),
          recordedAt: DateTime.parse(event['created_at'] as String),
          manualOrder: event['manual_order'] as int,
          data: event,
        ),
      );
    }
    final ordered = TimelineSort.sort(items, SortDirection.oldestFirst);
    final files = <String, String>{};
    final paths = <String, String>{};
    for (final item in ordered) {
      if (!RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$').hasMatch(item.id)) {
        throw ArgumentError('事件識別碼不是完整 ULID');
      }
      final prefix = item.effective?.range.start.toIso() ?? 'undated';
      final folder = item.groupYear?.toString().padLeft(4, '0') ?? 'undated';
      paths[item.id] =
          'markdown/events/$folder/${prefix}_${item.id.toLowerCase()}.md';
    }
    final timeline = StringBuffer(CommonMarkWriter.heading(label('timeline')));
    final html = StringBuffer(
      '<!doctype html>\n<html><head><meta charset="utf-8">'
      '<meta name="viewport" content="width=device-width,initial-scale=1">'
      '<title>${CommonMarkWriter.html(label('timeline'))}</title>'
      '<style>body{max-width:56rem;margin:auto;padding:1rem;font:18px/1.6 sans-serif}'
      'pre{white-space:pre-wrap;overflow-wrap:anywhere}img{max-width:100%}'
      'article{border-top:1px solid #888;margin-top:2rem}a{overflow-wrap:anywhere}</style>'
      '</head><body><h1>${CommonMarkWriter.html(label('timeline'))}</h1>',
    );
    for (final item in ordered) {
      final event = item.data;
      final title = event['title'] as String;
      final md = StringBuffer(
        '<!-- life-chronicle event ${item.id}; format 1.0 -->\n\n',
      );
      md.write(CommonMarkWriter.heading(title));
      html.write(
        '<article id="${item.id.toLowerCase()}"><h2>${CommonMarkWriter.html(title)}</h2>',
      );
      final referenceId = item.time is RelativeTime
          ? (item.time as RelativeTime).eventId
          : null;
      final reference = events
          .where((e) => e['event_id'] == referenceId)
          .firstOrNull;
      final time = TimeFormat.full(
        item.time,
        timeTexts,
        relatedEventTitle: reference?['deleted_at'] == null
            ? (reference?['title'] as String?)
            : null,
      );
      final metadata = [
        '${label('time')}: $time',
        '${label('layer')}: ${label(event['layer'] as String)}',
        '${label('author')}: ${authors[event['author_id']] ?? ''}',
        '${label('recorded')}: ${_timestamp(event['created_at'] as String)}',
        if (event['category'] != null)
          '${label('category')}: ${event['category']}',
        if (event['deleted_at'] != null)
          '${label('deleted')}: ${event['deleted_at']}',
      ];
      for (final value in metadata) {
        md.writeln('- ${CommonMarkWriter.text(value)}');
        html.write('<p>${CommonMarkWriter.html(value)}</p>');
      }
      md.writeln();
      final sections =
          data['event_sections']!
              .where((s) => s['event_id'] == item.id)
              .toList()
            ..sort((a, b) {
              final order = (a['position'] as int).compareTo(
                b['position'] as int,
              );
              return order != 0
                  ? order
                  : (a['event_section_id'] as String).compareTo(
                      b['event_section_id'] as String,
                    );
            });
      for (final section in sections) {
        final content = section['content_md'] as String;
        if (content.trim().isEmpty) continue;
        final heading = section['title'] as String?;
        if (heading != null && heading.trim().isNotEmpty) {
          md.write(CommonMarkWriter.heading(heading, level: 2));
        }
        md.write('${MarkdownDocument.source(content)}\n\n');
        if (heading != null && heading.trim().isNotEmpty) {
          html.write('<h3>${CommonMarkWriter.html(heading)}</h3>');
        }
        html.write(MarkdownDocument.html(content));
      }
      final reflections =
          data['reflections']!.where((r) => r['event_id'] == item.id).toList()
            ..sort(
              (a, b) => (a['recorded_at'] as String).compareTo(
                b['recorded_at'] as String,
              ),
            );
      if (reflections.isNotEmpty) {
        md.write(CommonMarkWriter.heading(label('reflections'), level: 2));
      }
      for (final reflection in reflections) {
        final author = authors[reflection['author_id']] ?? '';
        final stamp =
            '$author · ${_timestamp(reflection['recorded_at'] as String)} · ${label(reflection['layer'] as String)}';
        md.write(
          '${CommonMarkWriter.text(stamp)}\n\n${MarkdownDocument.source(reflection['content_md'] as String)}\n\n',
        );
        html.write(
          '<h3>${CommonMarkWriter.html(label('reflections'))}</h3>'
          '<p>${CommonMarkWriter.html(stamp)}</p>${MarkdownDocument.html(reflection['content_md'] as String)}',
        );
      }
      final attachments = data['attachments']!.where(
        (a) => a['event_id'] == item.id,
      );
      if (attachments.isNotEmpty) {
        md.write(CommonMarkWriter.heading(label('attachments'), level: 2));
      }
      for (final attachment in attachments) {
        final blob = blobs[attachment['blob_id']]!;
        final path = blob['path'] as String;
        final name = attachment['display_name'] as String;
        final image = (blob['media_type'] as String).startsWith('image/');
        md.write(
          '${CommonMarkWriter.link(name, '../../../$path', image: image)}\n\n',
        );
        html.write('<p><a href="$path">${CommonMarkWriter.html(name)}</a></p>');
        if (image) {
          html.write('<img src="$path" alt="${CommonMarkWriter.html(name)}">');
        }
      }
      html.write('</article>');
      files[paths[item.id]!] = md.toString();
      timeline.write(
        '- ${CommonMarkWriter.link('$time · $title', paths[item.id]!.substring(9))}\n',
      );
    }
    html.write('</body></html>\n');
    files['markdown/timeline.md'] = timeline.toString();
    files['index.html'] = html.toString();
    return files;
  }
}
