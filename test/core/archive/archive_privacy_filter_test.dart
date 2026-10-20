import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/archive/archive_privacy_filter.dart';

void main() {
  test('排除兩層私密附屬資料、雙向關聯及孤立修訂，保持輸入與保留列不變', () {
    final source = {
      for (final name in [
        'events',
        'event_sections',
        'reflections',
        'attachments',
        'event_tags',
        'event_people',
        'event_life_periods',
        'story_events',
        'event_links',
        'blobs',
        'change_history',
      ])
        name: <Map<String, Object?>>[],
    };
    source['events'] = [
      {
        'event_id': 'public',
        'privacy': 'normal',
        'layer': 'original',
        'updated_at': 'unchanged',
      },
      {'event_id': 'private', 'privacy': 'private', 'layer': 'original'},
      {'event_id': 'family', 'privacy': 'private', 'layer': 'remembrance'},
    ];
    for (final name in [
      'event_sections',
      'reflections',
      'event_tags',
      'event_people',
      'event_life_periods',
      'story_events',
    ]) {
      source[name] = [
        {'event_id': 'private', 'layer': 'remembrance'},
        {'event_id': 'public', 'layer': 'original'},
      ];
    }
    source['event_links'] = [
      {'event_a_id': 'private', 'event_b_id': 'public'},
      {'event_a_id': 'public', 'event_b_id': 'family'},
      {'event_a_id': 'public', 'event_b_id': 'other'},
    ];
    source['change_history'] = [
      for (final id in ['public', 'private', 'family', 'old_unknown'])
        {'entity_id': id},
    ];
    final before = jsonEncode(source);
    final result = ArchivePrivacyFilter(source);
    expect(result.excludedEvents, 2);
    expect(result.data['events'], [source['events']!.first]);
    expect(result.data['event_sections'], [source['event_sections']!.last]);
    expect(result.data['reflections'], [source['reflections']!.last]);
    expect(result.data['event_links'], [source['event_links']!.last]);
    expect(result.data['change_history'], [
      {'entity_id': 'public'},
    ]);
    expect(result.excludedHistory, 3);
    result.data['events']!.first['updated_at'] = 'copy only';
    expect(jsonEncode(source), before);
  });

  test('共用與未引用媒體保留，只有私密專屬副本移除', () {
    final source = {
      for (final name in [
        'events',
        'event_sections',
        'reflections',
        'attachments',
        'event_tags',
        'event_people',
        'event_life_periods',
        'story_events',
        'event_links',
        'blobs',
        'change_history',
      ])
        name: <Map<String, Object?>>[],
    };
    source['events'] = [
      {'event_id': 'public', 'privacy': 'normal'},
      {'event_id': 'private', 'privacy': 'private'},
    ];
    source['attachments'] = [
      {'event_id': 'private', 'blob_id': 'shared'},
      {'event_id': 'public', 'blob_id': 'shared'},
      {'event_id': 'private', 'blob_id': 'exclusive'},
    ];
    source['blobs'] = [
      for (final id in ['shared', 'exclusive', 'warehouse']) {'blob_id': id},
    ];
    source['events']!.first['time_payload'] = jsonEncode({
      'type': 'relative',
      'event_id': 'purged',
      'relation': 'after',
      'deleted_reference': {'title': 'private title', 'private': true},
    });
    final result = ArchivePrivacyFilter(source);
    expect(result.data['blobs'], [
      {'blob_id': 'shared'},
      {'blob_id': 'warehouse'},
    ]);
    expect(result.excludedMedia, 1);
    expect(result.excludedSnapshots, 1);
    final time = jsonDecode(
      result.data['events']!.first['time_payload'] as String,
    );
    expect(time, {
      'type': 'relative',
      'event_id': 'purged',
      'relation': 'after',
    });
    expect(jsonEncode(result.manifest), isNot(contains('private title')));
  });
}
