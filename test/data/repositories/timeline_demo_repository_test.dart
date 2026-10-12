import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/data/repositories/timeline_demo_repository.dart';
import 'package:life_chronicle/data/repositories/timeline_repository.dart';
import 'package:life_chronicle/data/repositories/event_repository.dart';
import 'package:life_chronicle/core/time/time_value.dart';

import 'harness.dart';

void main() {
  for (final count in [1000, 5000]) {
    test('debug 工具追加 $count 筆，50 年及十種精確度，保留原資料並記錄修訂', () async {
      final h = await Harness.create();
      addTearDown(h.close);
      final original = await h.events().create(
        const EventInput(title: 'original', time: UnknownTime()),
      );
      await TimelineDemoRepository(h.context())
          .generate(count, title: (number) => 'demo $number', category: 'demo');
      final rows = await h.db.select(h.db.events).get();
      expect(rows, hasLength(count + 1));
      expect(rows.map((row) => row.id).toSet(), hasLength(count + 1));
      expect(await h.events().find(original), isNotNull);
      expect(
        rows.map((row) => decodeTime(row.timePayload).type).toSet(),
        hasLength(10),
      );
      final years = await TimelineRepository(h.context()).watchYears().first;
      expect(years.where((year) => year.year != null), hasLength(50));
      expect(years.fold<int>(0, (sum, year) => sum + year.count), count + 1);
      expect(await h.db.select(h.db.changeHistory).get(), hasLength(count + 1));
    });
  }
}
