import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/core/time/timeline_sort.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';
import 'package:life_chronicle/data/repositories/search_repository.dart';

import 'harness.dart';

void main() {
  late Harness h;
  late SearchRepository search;
  late EventContentRepository content;
  setUp(() async {
    h = await Harness.create();
    search = SearchRepository(h.context());
    content = EventContentRepository(h.context());
  });
  tearDown(() => h.close());
  test('中文部分兩字、單字、英文及標點為字面搜尋，不解讀 FTS 指令', () async {
    final id = await content.save(
      EventDraft(
        title: '第一次大學畢業',
        sections: [DraftSection(content: '工作 Project Alpha "OR"')],
        place: '臺北市',
        people: ['媽媽'],
        tags: ['旅行'],
      ),
    );
    for (final query in [
      '大學',
      '畢',
      '工作',
      'project',
      'Alpha',
      '"OR"',
      '臺北',
      '媽媽',
      '旅行',
    ]) {
      expect((await search.watch(query).first).single.id, id, reason: query);
    }
    expect(await search.watch('不存在 OR 大學').first, isEmpty);
    expect(await search.watch('第一次畢業').first, isEmpty);
  });
  test('年份與跨年區間以交集縮小，未定時間在沒有年份條件時出現', () async {
    final year = await content.save(
      EventDraft(title: '大學', time: YearTime(2003)),
    );
    final range = await content.save(
      EventDraft(
        title: '大學生活',
        time: RangeTime(YearTime(2002), YearTime(2004)),
      ),
    );
    final unknown = await content.save(EventDraft(title: '大學回憶'));
    expect(
      (await search.watch('大學').first).map((item) => item.id),
      contains(unknown),
    );
    expect(
      (await search.watch('大學', fromYear: 2003, toYear: 2003).first).map(
        (item) => item.id,
      ),
      containsAll([year, range]),
    );
    expect(await search.watch('大學', fromYear: 2005).first, isEmpty);
    expect(
      () => search.watch('', fromYear: 2004, toYear: 2003),
      throwsArgumentError,
    );
  });
  test('即時索引追蹤記述、回顧、刪除與復原，不改原始內容', () async {
    final id = await content.save(EventDraft(title: '事件'));
    final stream = StreamIterator(search.watch('領悟'));
    addTearDown(stream.cancel);
    expect(await stream.moveNext(), isTrue);
    expect(stream.current, isEmpty);
    await content.appendReflection(id, '得到新的領悟');
    expect(await stream.moveNext(), isTrue);
    expect(stream.current.single.id, id);
    await h.events().softDelete(id);
    expect(await stream.moveNext(), isTrue);
    expect(stream.current, isEmpty);
    await h.events().restore(id);
    expect(await stream.moveNext(), isTrue);
    expect(stream.current.single.id, id);
  });
  test('搜尋雙向排序沿用唯一比較器', () async {
    for (final time in [
      YearTime(2003),
      HalfYearTime(2003, 2),
      DayTime(2003, 9, 15),
    ]) {
      await content.save(EventDraft(title: '事件', time: time));
    }
    final all = await h.events().watchTimeline().first;
    for (final direction in SortDirection.values) {
      expect(
        (await search.watch('事件', direction: direction).first).map(
          (item) => item.id,
        ),
        TimelineSort.sort(all, direction).map((item) => item.id),
      );
    }
  });
}
