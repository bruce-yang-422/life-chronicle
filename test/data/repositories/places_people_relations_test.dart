import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/policy/layer_policy.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/data/db/tables.dart';
import 'package:life_chronicle/data/repositories/event_repository.dart';

import 'harness.dart';

void main() {
  late Harness h;

  setUp(() async => h = await Harness.create());
  tearDown(() => h.close());

  Future<String> create(String title, {String? as}) =>
      h.events(as: as).create(EventInput(title: title, time: YearTime(2003)));

  group('地點（驗收 #33 資料層）', () {
    test('「臺北市」與「台北市」為同一地點', () async {
      final a = await h.places.findOrCreateByName('臺北市');
      final b = await h.places.findOrCreateByName('台北市');
      final c = await h.places.findOrCreateByName(' 台北 市 ');
      expect(b, a);
      expect(c, a);
      expect((await h.places.find(a))!.name, '臺北市');
    });

    test('輸入「台北」時建議「臺北市」，開頭相同者排前面', () async {
      await h.places.findOrCreateByName('臺北市');
      await h.places.findOrCreateByName('新台北公園');
      await h.places.findOrCreateByName('高雄市');
      final names = (await h.places.suggest('台北')).map((p) => p.name);
      expect(names, ['臺北市', '新台北公園']);
    });

    test('空白名稱拒絕', () {
      expect(() => h.places.findOrCreateByName('  '), throwsArgumentError);
    });

    test('沒有名稱的 GPS 錨點', () async {
      final id = await h.places.createAnchor(
        latitude: 25.17,
        longitude: 121.56,
        radiusM: 300,
      );
      final place = (await h.places.find(id))!;
      expect(place.name, isNull);
      expect(place.radiusM, 300);
    });

    test('先用文字記錄，日後再補上釘選點', () async {
      final id = await h.places.findOrCreateByName('陽明山');
      await h.places.setAnchor(id, latitude: 25.16, longitude: 121.55);
      final place = (await h.places.find(id))!;
      expect([place.latitude, place.longitude], [25.16, 121.55]);
    });

    test('以名稱建立錨點時，若地點已存在則補上座標而不重複建立', () async {
      final id = await h.places.findOrCreateByName('臺北市');
      final anchored = await h.places.createAnchor(
        name: '台北市',
        latitude: 25.03,
        longitude: 121.56,
      );
      expect(anchored, id);
      expect(await h.db.select(h.db.places).get(), hasLength(1));
    });

    test('座標超出範圍時拒絕', () {
      expect(
        () => h.places.createAnchor(latitude: 91, longitude: 0),
        throwsArgumentError,
      );
      expect(
        () => h.places.createAnchor(latitude: 0, longitude: 0, radiusM: 0),
        throwsArgumentError,
      );
    });
  });

  group('參與人物', () {
    test('同名人物重用，建議清單可找到', () async {
      final mom = await h.people.findOrCreate('媽媽');
      expect(await h.people.findOrCreate(' 媽媽 '), mom);
      expect((await h.people.suggest('媽')).map((p) => p.id), [mom]);
    });

    test('事件與人物多對多', () async {
      final mom = await h.people.findOrCreate('媽媽');
      final e1 = await create('e1');
      final e2 = await create('e2');
      await h.relations().addPerson(e1, mom);
      await h.relations().addPerson(e1, mom); // 重複加入無效果
      await h.relations().addPerson(e2, mom);
      expect((await h.relations().peopleOf(e1)).map((p) => p.id), [mom]);
      expect(await h.db.select(h.db.eventPeople).get(), hasLength(2));
    });

    test('生命典藏期間家人補充人物為後續追憶，不可移除原始的人物', () async {
      final e1 = await create('e1');
      final mom = await h.people.findOrCreate('媽媽');
      final dad = await h.people.findOrCreate('爸爸');
      await h.relations().addPerson(e1, mom);
      await h.activateArchive();
      final family = h.relations(as: h.familyAuthorId);
      await family.addPerson(e1, dad);
      final rows = await h.db.select(h.db.eventPeople).get();
      expect(
        {for (final r in rows) r.personId: r.layer},
        {mom: Layer.original, dad: Layer.remembrance},
      );
      expect(
        () => family.removePerson(e1, mom),
        throwsA(isA<PermissionDeniedException>()),
      );
      await family.removePerson(e1, dad);
    });
  });

  group('關聯事件（驗收 #36 資料層）', () {
    test('一個事件關聯三個事件，從任一端都看得到', () async {
      final ids = [
        for (final t in ['A', 'B', 'C', 'D']) await create(t),
      ];
      await h.relations().linkAll(ids[0], ids.sublist(1));

      expect(
        (await h.relations().related(ids[0])).map((e) => e.title).toSet(),
        {'B', 'C', 'D'},
      );
      for (final other in ids.sublist(1)) {
        expect((await h.relations().related(other)).map((e) => e.title), ['A']);
      }
    });

    test('反向重複關聯不建立第二筆；不可自我關聯', () async {
      final a = await create('A');
      final b = await create('B');
      await h.relations().link(a, b);
      await h.relations().link(b, a);
      expect(await h.db.select(h.db.eventLinks).get(), hasLength(1));
      expect(() => h.relations().link(a, a), throwsArgumentError);
    });

    test('已刪除的事件不出現在關聯中，也不可新建關聯', () async {
      final a = await create('A');
      final b = await create('B');
      await h.relations().link(a, b);
      await h.events().softDelete(b);
      expect(await h.relations().related(a), isEmpty);
      final c = await create('C');
      expect(
        () => h.relations().link(c, b),
        throwsA(isA<EventStateException>()),
      );
    });

    test('取消關聯', () async {
      final a = await create('A');
      final b = await create('B');
      await h.relations().link(a, b);
      await h.relations().unlink(b, a);
      expect(await h.relations().related(a), isEmpty);
    });
  });
}
