import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/archive/archive_reading.dart';
import 'package:life_chronicle/core/archive/archive_subject_policy.dart';

ArchiveRows profile(String id) => {
  'subjects': [
    {
      'subject_id': id,
      'display_name': '',
      'birth_date': null,
      'death_date': null,
    },
  ],
  'authors': [
    {
      'author_id': '$id-self',
      'display_name': '',
      'role': 'self',
      'is_subject_self': true,
    },
  ],
  'archive_settings': [
    {'subject_id': id, 'mode': 'normal', 'current_session_id': null},
  ],
};

void main() {
  test('相同主角的現有內容交給衝突處理，不取代主角', () {
    final local = profile('a')
      ..['events'] = [
        {'subject_id': 'a'},
      ];
    expect(
      ArchiveSubjectPolicy.replacesInitialProfile(local, profile('a')),
      isFalse,
    );
  });

  test('真正空白與 APP 初始狀態都可還原，只有初始狀態需要取代', () {
    expect(
      ArchiveSubjectPolicy.replacesInitialProfile({}, profile('b')),
      isFalse,
    );
    expect(
      ArchiveSubjectPolicy.replacesInitialProfile(profile('a'), profile('b')),
      isTrue,
    );
  });

  test('不能將不同主角資料藏在事件或典藏期間，也不能匯入多位主角', () {
    for (final table in ['subjects', 'events', 'archive_sessions']) {
      final incoming = profile('b');
      incoming[table] = [
        ...?incoming[table],
        {'subject_id': 'c'},
      ];
      expect(
        () => ArchiveSubjectPolicy.replacesInitialProfile({}, incoming),
        throwsA(
          isA<ArchiveSubjectException>().having(
            (e) => e.reason,
            'reason',
            ArchiveSubjectFailure.invalidArchive,
          ),
        ),
      );
    }
  });

  test('缺少或多個本人作者、缺少典藏設定都拒絕匯入', () {
    for (final invalid in ['no-self', 'two-self', 'no-settings']) {
      final incoming = profile('b');
      if (invalid == 'no-self') incoming['authors'] = [];
      if (invalid == 'two-self') {
        incoming['authors']!.add({...incoming['authors']!.single});
      }
      if (invalid == 'no-settings') incoming['archive_settings'] = [];
      expect(
        () => ArchiveSubjectPolicy.replacesInitialProfile({}, incoming),
        throwsA(isA<ArchiveSubjectException>()),
      );
    }
  });

  test('沒有事件但有已填主角資料、參考資料或修訂紀錄也不算空白', () {
    for (final field in ['display_name', 'birth_date', 'death_date']) {
      final local = profile('a');
      local['subjects']!.single[field] = '已填資料';
      expect(
        () => ArchiveSubjectPolicy.replacesInitialProfile(local, profile('b')),
        throwsA(isA<ArchiveSubjectException>()),
      );
    }
    for (final table in [
      'people',
      'places',
      'tags',
      'life_periods',
      'blobs',
      'change_history',
    ]) {
      final local = profile('a')
        ..[table] = [
          {'id': 'existing'},
        ];
      expect(
        () => ArchiveSubjectPolicy.replacesInitialProfile(local, profile('b')),
        throwsA(isA<ArchiveSubjectException>()),
      );
    }
  });
}
