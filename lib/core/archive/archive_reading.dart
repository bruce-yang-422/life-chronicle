import 'dart:convert';

import '../time/calendar_date.dart';
import '../time/sort_range.dart';
import '../time/time_format.dart';
import '../time/time_texts.dart';
import '../time/time_value.dart';
import '../time/timeline_sort.dart';
import 'commonmark_writer.dart';
import 'markdown_document.dart';
import 'archive_integrity.dart';

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

  Map<String, String> generate(
    ArchiveRows data, {
    Set<String> excludedMedia = const {},
  }) {
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
      paths[item.id] = eventPath(
        item.data['layer'] as String,
        folder,
        '${prefix}_${item.id.toLowerCase()}.md',
      );
    }
    final timeline = StringBuffer(CommonMarkWriter.heading(label('timeline')));
    final html = StringBuffer(
      '<!doctype html>\n<html><head><meta charset="utf-8">'
      '<meta name="viewport" content="width=device-width,initial-scale=1">'
      '<title>${CommonMarkWriter.html(label('timeline'))}</title>'
      '<style>body{max-width:56rem;margin:auto;padding:1rem;font:18px/1.6 sans-serif}'
      'pre{white-space:pre-wrap;overflow-wrap:anywhere}img{max-width:100%}'
      'article{border-top:1px solid #888;margin-top:2rem}a{overflow-wrap:anywhere}'
      'table{display:block;overflow-x:auto;border-collapse:collapse}'
      'th,td{border:1px solid #888;padding:.4rem}p{overflow-wrap:anywhere}</style>'
      '</head><body><h1>${CommonMarkWriter.html(label('timeline'))}</h1>',
    );
    final remembranceHtml = StringBuffer();
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
        relatedEventTitle: reference == null ? null : _eventTitle(reference),
      );
      final metadata = [
        '${label('time')}: $time',
        '${label('layer')}: ${label(event['layer'] as String)}',
        '${label('author')}: ${_author(authors, event['author_id'])}',
        '${label('recorded')}: ${_timestamp(event['created_at'] as String)}',
        if (event['category'] != null)
          '${label('category')}: ${event['category']}',
        if (event['deleted_at'] != null)
          '${label('deleted')}: ${_timestamp(event['deleted_at'] as String)}',
        '${label('privacy')}: ${label(event['privacy'] as String)}',
        ..._eventMetadata(data, event),
      ];
      for (final value in metadata) {
        md.writeln('- ${CommonMarkWriter.text(value)}');
        html.write('<p>${CommonMarkWriter.html(value)}</p>');
      }
      md.writeln();
      final related = <String>{};
      for (final link
          in data['event_links'] ?? const <Map<String, Object?>>[]) {
        if (link['event_a_id'] == item.id) {
          related.add(link['event_b_id'] as String);
        }
        if (link['event_b_id'] == item.id) {
          related.add(link['event_a_id'] as String);
        }
      }
      if (related.isNotEmpty) {
        md.write(CommonMarkWriter.heading(label('related'), level: 2));
        html.write('<h3>${CommonMarkWriter.html(label('related'))}</h3>');
        for (final linked in ordered.where(
          (entry) => related.contains(entry.id),
        )) {
          final linkedTitle = _eventTitle(linked.data);
          md.writeln(
            '- ${CommonMarkWriter.link(linkedTitle, _relative(paths[item.id]!, paths[linked.id]!))}',
          );
          html.write(
            '<p><a href="#${linked.id.toLowerCase()}">${CommonMarkWriter.html(linkedTitle)}</a></p>',
          );
        }
        md.writeln();
      }
      final remembranceLinks = <String>[];
      final remembranceHtmlLinks = <String>[];
      void remember(
        Map<String, Object?> row,
        String idField,
        String kind,
        void Function(StringBuffer, StringBuffer, String) render,
      ) {
        final id = row[idField] as String;
        if (!RegExp(r'^[0-9A-HJKMNP-TV-Z]{26}$').hasMatch(id)) {
          throw ArgumentError('追憶識別碼不是完整 ULID');
        }
        final recorded = (row['recorded_at'] ?? row['created_at']) as String;
        final created = DateTime.parse(recorded).toUtc();
        final path =
            'markdown/remembrance/${created.toIso8601String().substring(0, 10)}_${id.toLowerCase()}.md';
        final name =
            '${label(kind)} · ${_author(authors, row['author_id'])} · ${_timestamp(recorded)}';
        final detailMd = StringBuffer(
          '<!-- life-chronicle event ${item.id}; content $id; format 1.0 -->\n\n'
          '${CommonMarkWriter.heading('${label('remembrance')} · $title')}',
        );
        final detailHtml = StringBuffer(
          '<article id="rem-${id.toLowerCase()}"><h2>${CommonMarkWriter.html('${label('remembrance')} · $title')}</h2>',
        );
        final stamp =
            '${label('author')}: ${_author(authors, row['author_id'])} · ${label('recorded')}: ${_timestamp(recorded)}';
        detailMd.writeln('${CommonMarkWriter.text(stamp)}\n');
        detailMd.writeln(
          '${CommonMarkWriter.link(_eventTitle(event), _relative(path, paths[item.id]!))}\n',
        );
        detailHtml.write(
          '<p>${CommonMarkWriter.html(stamp)}</p><p><a href="#${item.id.toLowerCase()}">${CommonMarkWriter.html(_eventTitle(event))}</a></p>',
        );
        render(detailMd, detailHtml, path);
        detailHtml.write('</article>');
        files[path] = detailMd.toString();
        remembranceHtml.write(detailHtml);
        remembranceLinks.add(
          CommonMarkWriter.link(name, _relative(paths[item.id]!, path)),
        );
        remembranceHtmlLinks.add(
          '<p><a href="#rem-${id.toLowerCase()}">${CommonMarkWriter.html(name)}</a></p>',
        );
      }

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
        if (section['layer'] == 'remembrance') {
          remember(section, 'event_section_id', 'narrative', (out, web, path) {
            if ((section['title'] as String?)?.trim().isNotEmpty == true) {
              out.write(
                CommonMarkWriter.heading(section['title'] as String, level: 2),
              );
              web.write(
                '<h3>${CommonMarkWriter.html(section['title'] as String)}</h3>',
              );
            }
            out.write('${MarkdownDocument.source(content)}\n\n');
            web.write(MarkdownDocument.html(content));
          });
          continue;
        }
        final heading = section['title'] as String?;
        if (heading != null && heading.trim().isNotEmpty) {
          md.write(CommonMarkWriter.heading(heading, level: 2));
          html.write('<h3>${CommonMarkWriter.html(heading)}</h3>');
        }
        final sectionStamp =
            '${label('author')}: ${_author(authors, section['author_id'])} · ${label('recorded')}: ${_timestamp(section['created_at'] as String)}';
        md.write('${CommonMarkWriter.text(sectionStamp)}\n\n');
        html.write('<p>${CommonMarkWriter.html(sectionStamp)}</p>');
        md.write('${MarkdownDocument.source(content)}\n\n');
        html.write(MarkdownDocument.html(content));
      }
      final reflections =
          data['reflections']!.where((r) => r['event_id'] == item.id).toList()
            ..sort(
              (a, b) => (a['recorded_at'] as String).compareTo(
                b['recorded_at'] as String,
              ),
            );
      if (reflections.any((row) => row['layer'] != 'remembrance')) {
        md.write(CommonMarkWriter.heading(label('reflections'), level: 2));
        html.write('<h3>${CommonMarkWriter.html(label('reflections'))}</h3>');
      }
      for (final reflection in reflections) {
        if (reflection['layer'] == 'remembrance') {
          remember(reflection, 'reflection_id', 'reflections', (
            out,
            web,
            path,
          ) {
            out.write(
              '${MarkdownDocument.source(reflection['content_md'] as String)}\n\n',
            );
            web.write(
              MarkdownDocument.html(reflection['content_md'] as String),
            );
          });
          continue;
        }
        final author = _author(authors, reflection['author_id']);
        final stamp =
            '$author · ${_timestamp(reflection['recorded_at'] as String)} · ${label(reflection['layer'] as String)}';
        md.write(
          '${CommonMarkWriter.text(stamp)}\n\n${MarkdownDocument.source(reflection['content_md'] as String)}\n\n',
        );
        html.write(
          '<p>${CommonMarkWriter.html(stamp)}</p>${MarkdownDocument.html(reflection['content_md'] as String)}',
        );
      }
      final attachments = data['attachments']!.where(
        (a) => a['event_id'] == item.id,
      );
      if (attachments.any((row) => row['layer'] != 'remembrance')) {
        md.write(CommonMarkWriter.heading(label('attachments'), level: 2));
        html.write('<h3>${CommonMarkWriter.html(label('attachments'))}</h3>');
      }
      for (final attachment in attachments) {
        final blob = blobs[attachment['blob_id']]!;
        if (attachment['layer'] == 'remembrance') {
          remember(
            attachment,
            'attachment_id',
            'attachments',
            (out, web, path) => _attachment(
              out,
              web,
              path,
              attachment,
              blob,
              excludedMedia,
              authors,
            ),
          );
        } else {
          _attachment(
            md,
            html,
            paths[item.id]!,
            attachment,
            blob,
            excludedMedia,
            authors,
          );
        }
      }
      if (remembranceLinks.isNotEmpty) {
        md.write(CommonMarkWriter.heading(label('remembrance'), level: 2));
        for (final link in remembranceLinks) {
          md.writeln('- $link');
        }
        md.writeln();
        html.write(
          '<h3>${CommonMarkWriter.html(label('remembrance'))}</h3>${remembranceHtmlLinks.join()}',
        );
      }
      html.write('</article>');
      files[paths[item.id]!] = md.toString();
      timeline.write(
        '- ${CommonMarkWriter.link('$time · $title', paths[item.id]!.substring(9))}\n',
      );
    }
    html.write('$remembranceHtml</body></html>\n');
    files['markdown/timeline.md'] = timeline.toString();
    files['index.html'] = html.toString();
    return files;
  }

  static String eventPath(String layer, String year, String filename) =>
      layer == 'remembrance'
      ? 'markdown/remembrance/$filename'
      : 'markdown/events/$year/$filename';

  String _author(Map<Object?, Object?> authors, Object? id) =>
      (authors[id] as String?)?.trim().isNotEmpty == true
      ? authors[id] as String
      : label('selfAuthor');

  String _eventTitle(Map<String, Object?> event) => event['deleted_at'] == null
      ? event['title'] as String
      : '${event['title']} (${label('deletedReference')})';

  static String _relative(String from, String to) {
    final source = from.split('/')..removeLast();
    final destination = to.split('/');
    var common = 0;
    while (common < source.length &&
        common < destination.length &&
        source[common] == destination[common]) {
      common++;
    }
    return [
      ...List.filled(source.length - common, '..'),
      ...destination.skip(common),
    ].join('/');
  }

  List<String> _eventMetadata(ArchiveRows data, Map<String, Object?> event) {
    final result = <String>[];
    final place = (data['places'] ?? const <Map<String, Object?>>[])
        .where((row) => row['place_id'] == event['place_id'])
        .firstOrNull;
    if (place != null) {
      if (place['name'] != null) {
        result.add('${label('place')}: ${place['name']}');
      }
      if (place['latitude'] != null) {
        result.add(
          '${label('coordinates')}: ${place['latitude']}, ${place['longitude']}',
        );
      }
      if (place['radius_m'] != null) {
        result.add('${label('radius')}: ${place['radius_m']}');
      }
    }
    for (final (table, links, id, name, caption) in [
      ('people', 'event_people', 'person_id', 'display_name', 'people'),
      ('tags', 'event_tags', 'tag_id', 'label', 'tags'),
    ]) {
      final linked = (data[links] ?? const <Map<String, Object?>>[]).where(
        (row) => row['event_id'] == event['event_id'],
      );
      final names = <String>[];
      for (final relation in linked) {
        final row = (data[table] ?? const <Map<String, Object?>>[])
            .where((row) => row[id] == relation[id])
            .firstOrNull;
        if (row != null) {
          names.add(
            '${row[name]}${relation['layer'] == 'remembrance' ? ' (${label('remembrance')})' : ''}',
          );
        }
      }
      if (names.isNotEmpty) {
        result.add('${label(caption)}: ${names.join(', ')}');
      }
    }
    for (final relation
        in data['event_life_periods'] ?? const <Map<String, Object?>>[]) {
      if (relation['event_id'] != event['event_id']) continue;
      final period = (data['life_periods'] ?? const <Map<String, Object?>>[])
          .where((row) => row['life_period_id'] == relation['life_period_id'])
          .firstOrNull;
      if (period == null) continue;
      final start = TimeFormat.full(
        TimeValue.fromJson(
          jsonDecode(period['start_time'] as String) as Map<String, Object?>,
        ),
        timeTexts,
      );
      final end = period['end_time'] == null
          ? null
          : TimeFormat.full(
              TimeValue.fromJson(
                jsonDecode(period['end_time'] as String)
                    as Map<String, Object?>,
              ),
              timeTexts,
            );
      result.add(
        '${label('periods')}: ${[period['organization'], period['role'], start, end].where((value) => value != null && value != '').join(' · ')}',
      );
    }
    return result;
  }

  void _attachment(
    StringBuffer md,
    StringBuffer html,
    String document,
    Map<String, Object?> attachment,
    Map<String, Object?> blob,
    Set<String> excluded,
    Map<Object?, Object?> authors,
  ) {
    final path = blob['path'] as String;
    if (!ArchiveIntegrity.safePath(path) || !path.startsWith('media/')) {
      throw ArgumentError('附件閱讀連結必須是封存媒體路徑');
    }
    final name = (attachment['display_name'] as String).isEmpty
        ? attachment['original_filename'] as String
        : attachment['display_name'] as String;
    final unavailable =
        excluded.contains(path) || blob['verify_status'] == 'excluded';
    final image = (blob['media_type'] as String).startsWith('image/');
    if (unavailable) {
      final text = '$name · ${label('unavailable')}';
      md.write('${CommonMarkWriter.text(text)}\n\n');
      html.write('<p>${CommonMarkWriter.html(text)}</p>');
    } else {
      md.write(
        '${CommonMarkWriter.link(name, _relative(document, path), image: image)}\n\n',
      );
      html.write(
        '<p><a href="${CommonMarkWriter.html(path)}">${CommonMarkWriter.html(name)}</a></p>',
      );
      if (image) {
        html.write(
          '<img src="${CommonMarkWriter.html(path)}" alt="${CommonMarkWriter.html(name)}">',
        );
      }
    }
    for (final value in [
      '${label('filename')}: ${attachment['original_filename']}',
      '${label('layer')}: ${label(attachment['layer'] as String)}',
      '${label('author')}: ${_author(authors, attachment['author_id'])}',
      if (attachment['captured_at'] != null)
        '${label('captured')}: ${_timestamp(attachment['captured_at'] as String)}',
      '${label('imported')}: ${_timestamp(attachment['imported_at'] as String)}',
    ]) {
      md.writeln('- ${CommonMarkWriter.text(value)}');
      html.write('<p>${CommonMarkWriter.html(value)}</p>');
    }
    md.writeln();
  }
}
