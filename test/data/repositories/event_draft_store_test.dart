import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/data/repositories/event_draft_store.dart';

void main() {
  test('重開草稿保留半年、段落順序及待匯入附件', () async {
    final directory = await Directory.systemTemp.createTemp('draft-test-');
    addTearDown(() => directory.delete(recursive: true));
    final store = FileEventDraftStore(directory);
    final draft = EventDraft(
      title: '大學',
      time: HalfYearTime(2003, 2),
      people: ['媽媽'],
      relatedIds: ['event'],
      attachments: [
        {'path': '/persistent/file', 'name': '照片.jpg'},
      ],
      sections: [
        DraftSection(title: '想對你說的話', content: '內容'),
        DraftSection(content: '未命名'),
      ],
    );
    await store.save('new', draft);
    expect(
      (await FileEventDraftStore(directory).load('new'))!.toJson(),
      draft.toJson(),
    );
    await store.remove('new');
    expect(await store.load('new'), isNull);
  });
  test('連續寫入快照後刪除，舊寫入不能復活草稿', () async {
    final directory = await Directory.systemTemp.createTemp('draft-test-');
    addTearDown(() => directory.delete(recursive: true));
    final store = FileEventDraftStore(directory);
    final draft = EventDraft(title: '舊');
    final first = store.save('new', draft);
    draft.title = '新';
    final second = store.save('new', draft);
    await Future.wait([first, second]);
    expect((await store.load('new'))!.title, '新');
    final writing = store.save('new', draft);
    final removal = store.remove('new');
    await Future.wait([writing, removal]);
    expect(await store.load('new'), isNull);
  });
}
