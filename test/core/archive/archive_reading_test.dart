import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/archive/archive_reading.dart';
import 'package:life_chronicle/core/archive/commonmark_writer.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/l10n/app_localizations_en.dart';
import 'package:life_chronicle/l10n/l10n_time_texts.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:path/path.dart' as p;

String id(int value) => '$value'.padLeft(26, '0');
final mediaPath = 'media/aa/${'a' * 64}.jpg';
const stamp = '2026-10-19T08:00:00.000Z';
final labels = {
  for (final name in [
    'timeline',
    'time',
    'layer',
    'author',
    'recorded',
    'category',
    'deleted',
    'original',
    'remembrance',
    'reflections',
    'attachments',
    'privacy',
    'private',
    'normal',
    'place',
    'people',
    'tags',
    'related',
    'coordinates',
    'radius',
    'captured',
    'imported',
    'filename',
    'unavailable',
    'selfAuthor',
    'narrative',
    'deletedReference',
    'periods',
  ])
    name: name,
};

Map<String, Object?> event(
  int value, {
  String layer = 'original',
  TimeValue? time,
}) => {
  'event_id': id(value),
  'subject_id': id(90),
  'title': 'event <$value> *literal*',
  'time_payload': jsonEncode((time ?? YearTime(2003)).toJson()),
  'sort_start': null,
  'sort_end': null,
  'manual_order': 0,
  'created_at': stamp,
  'layer': layer,
  'author_id': id(91),
  'category': null,
  'privacy': 'normal',
  'deleted_at': null,
  'place_id': null,
};
Map<String, Object?> attachment(int value, String layer) => {
  'attachment_id': id(value),
  'event_id': id(1),
  'blob_id': id(50),
  'display_name': 'photo <$value> [name]',
  'original_filename': 'original_$value.jpg',
  'layer': layer,
  'author_id': layer == 'original' ? id(91) : id(92),
  'created_at': stamp,
  'captured_at': '1990-01-01T00:00:00Z',
  'imported_at': stamp,
};
ArchiveRows fixture() => {
  'subjects': [
    {'subject_id': id(90), 'birth_date': null},
  ],
  'authors': [
    {'author_id': id(91), 'display_name': ''},
    {'author_id': id(92), 'display_name': 'Family <safe>'},
  ],
  'events': [event(1)],
  'event_sections': [
    {
      'event_section_id': id(20),
      'event_id': id(1),
      'position': 0,
      'title': 'Original *heading*',
      'content_md': 'Original narrative 🎉',
      'layer': 'original',
      'author_id': id(91),
      'created_at': stamp,
    },
  ],
  'reflections': [],
  'attachments': [],
  'blobs': [
    {
      'blob_id': id(50),
      'path': mediaPath,
      'media_type': 'image/jpeg',
      'verify_status': 'verified',
    },
  ],
};

void main() {
  late ArchiveRows data;
  late ArchiveReading reading;
  setUp(() {
    data = fixture();
    reading = ArchiveReading(
      labels,
      L10nTimeTexts(AppLocalizationsEn()),
      timestampFormat: (time) => 'display:${time.toUtc().toIso8601String()}',
    );
  });

  test('閱讀版完整呈現地點、座標、人物、標籤與明確階段，純文字不變成 HTML', () {
    data['events']!.single['place_id'] = id(60);
    data['places'] = [
      {
        'place_id': id(60),
        'name': 'Place <script>',
        'latitude': 25.03,
        'longitude': 121.56,
        'radius_m': 100,
      },
    ];
    data['people'] = [
      {'person_id': id(61), 'display_name': 'Person *name*'},
      {'person_id': id(62), 'display_name': 'Unlinked person'},
    ];
    data['event_people'] = [
      {'event_id': id(1), 'person_id': id(61), 'layer': 'original'},
    ];
    data['tags'] = [
      {'tag_id': id(63), 'label': 'Tag [name]'},
    ];
    data['event_tags'] = [
      {'event_id': id(1), 'tag_id': id(63), 'layer': 'remembrance'},
    ];
    data['life_periods'] = [
      for (final value in [64, 65])
        {
          'life_period_id': id(value),
          'organization': value == 64 ? 'Linked university' : 'Unlinked school',
          'role': 'student',
          'start_time': jsonEncode(YearTime(2001).toJson()),
          'end_time': null,
        },
    ];
    data['event_life_periods'] = [
      {'event_id': id(1), 'life_period_id': id(64)},
    ];
    final before = jsonEncode(data);
    final files = reading.generate(data);
    final html = files['index.html']!;
    expect(html, contains('Place &lt;script&gt;'));
    expect(html, contains('25.03, 121.56'));
    expect(html, contains('radius: 100'));
    expect(html, contains('Person *name*'));
    expect(html, contains('Tag [name] (remembrance)'));
    expect(html, contains('Linked university'));
    expect(html, isNot(contains('Unlinked')));
    expect(html, isNot(contains('<script>')));
    expect(html, contains('selfAuthor'));
    expect(jsonEncode(data), before);
  });

  test('後續追憶分檔保存作者、時間與原事件連結，原始段落不混入追憶內容', () {
    data['event_sections']!.add({
      'event_section_id': id(21),
      'event_id': id(1),
      'position': 1,
      'title': 'Memory section',
      'content_md': '**Memory narrative**',
      'layer': 'remembrance',
      'author_id': id(92),
      'created_at': stamp,
    });
    data['reflections']!.add({
      'reflection_id': id(22),
      'event_id': id(1),
      'recorded_at': '2026-10-20T08:00:00Z',
      'created_at': stamp,
      'content_md': 'Memory reflection 👍🏽',
      'layer': 'remembrance',
      'author_id': id(92),
    });
    data['attachments']!.addAll([
      attachment(23, 'original'),
      attachment(24, 'remembrance'),
    ]);
    final files = reading.generate(data);
    final original = files.entries.singleWhere(
      (entry) => entry.key.startsWith('markdown/events/'),
    );
    expect(original.value, contains('Original narrative'));
    expect(original.value, isNot(contains('Memory narrative')));
    expect(original.value, isNot(contains('Memory reflection')));
    expect(original.value, contains('## remembrance'));
    final memories = files.entries
        .where((entry) => entry.key.startsWith('markdown/remembrance/'))
        .toList();
    expect(memories, hasLength(3));
    expect(
      memories.any(
        (entry) => entry.key.startsWith('markdown/remembrance/2026-10-20_'),
      ),
      isTrue,
    );
    expect(
      memories.map((entry) => entry.value).join(),
      contains('Family \\<safe\\>'),
    );
    expect(memories.map((entry) => entry.value).join(), contains('display'));
    expect(files['index.html'], contains('<strong>Memory narrative</strong>'));
    expect(files['index.html'], contains('Family &lt;safe&gt;'));
    _checkLinks(files, {mediaPath});
  });

  test('排除照片時兩種閱讀版顯示提示，不產生破圖或失效媒體連結', () {
    data['attachments']!.addAll([
      attachment(23, 'original'),
      attachment(24, 'remembrance'),
    ]);
    final files = reading.generate(data, excludedMedia: {mediaPath});
    expect(files['index.html'], contains('unavailable'));
    expect(files['index.html'], isNot(contains('<img')));
    expect(files['index.html'], isNot(contains('href="media/')));
    final source = files.values.join();
    expect(source, contains('original_23'));
    expect(source, contains('original_24'));
    _checkLinks(files, {});
  });

  test('已刪除的相對參照與關聯事件保留標題；追憶事件依層級分檔', () {
    data['events']!.single['deleted_at'] = stamp;
    data['events']!.add(
      event(
        2,
        layer: 'remembrance',
        time: RelativeTime(id(1), RelativeRelation.after),
      ),
    );
    data['event_links'] = [
      {'event_a_id': id(1), 'event_b_id': id(2), 'layer': 'original'},
    ];
    final files = reading.generate(data);
    final memoryEvent = files.entries.singleWhere(
      (entry) => entry.key.startsWith('markdown/remembrance/'),
    );
    expect(
      memoryEvent.value,
      contains(CommonMarkWriter.text('event <1> *literal* (deletedReference)')),
    );
    expect(
      files['index.html'],
      contains('event &lt;1&gt; *literal* (deletedReference)'),
    );
    expect(files['index.html'], contains('display:2026-10-19'));
    _checkLinks(files, {});
  });

  test('拒絕以媒體路徑插入外部請求或 HTML', () {
    data['attachments']!.add(attachment(23, 'original'));
    for (final path in [
      'https://example.com/track.jpg',
      'media/../evil.jpg',
      'media/x" onerror="bad',
    ]) {
      data['blobs']!.single['path'] = path;
      expect(() => reading.generate(data), throwsArgumentError);
    }
  });

  test('段落依使用者順序輸出，空白段落不產生標題', () {
    data['event_sections']!.addAll([
      {
        'event_section_id': id(22),
        'event_id': id(1),
        'position': 2,
        'title': 'Second section',
        'content_md': 'Second content',
        'layer': 'original',
        'author_id': id(91),
        'created_at': stamp,
      },
      {
        'event_section_id': id(21),
        'event_id': id(1),
        'position': 1,
        'title': 'First section',
        'content_md': 'First content',
        'layer': 'original',
        'author_id': id(91),
        'created_at': stamp,
      },
      {
        'event_section_id': id(23),
        'event_id': id(1),
        'position': 3,
        'title': 'Empty section',
        'content_md': ' \n ',
        'layer': 'original',
        'author_id': id(91),
        'created_at': stamp,
      },
    ]);
    final files = reading.generate(data);
    final source = files.entries
        .singleWhere((entry) => entry.key.startsWith('markdown/events/'))
        .value;
    for (final text in [source, files['index.html']!]) {
      expect(
        text.indexOf('First section'),
        lessThan(text.indexOf('Second section')),
      );
      expect(text, isNot(contains('Empty section')));
    }
  });
}

void _checkLinks(Map<String, String> files, Set<String> media) {
  for (final entry in files.entries.where(
    (entry) => entry.key.endsWith('.md'),
  )) {
    final html = markdown.markdownToHtml(
      entry.value,
      extensionSet: markdown.ExtensionSet.commonMark,
    );
    expect(RegExp('<h1>').allMatches(html), hasLength(1), reason: entry.key);
    for (final match in RegExp(r'(?:href|src)="([^"]+)"').allMatches(html)) {
      final link = match[1]!;
      if (Uri.parse(link).hasScheme || link.startsWith('#')) continue;
      final resolved = p.posix.normalize(
        p.posix.join(p.posix.dirname(entry.key), link),
      );
      expect(
        {...files.keys, ...media},
        contains(resolved),
        reason: '${entry.key}: $link',
      );
    }
  }
  final html = files['index.html']!;
  final anchors = RegExp(r'id="([^"]+)"')
      .allMatches(html)
      .map((match) => match[1])
      .toSet();
  for (final match in RegExp(r'href="#([^"]+)"').allMatches(html)) {
    expect(anchors, contains(match[1]));
  }
}
