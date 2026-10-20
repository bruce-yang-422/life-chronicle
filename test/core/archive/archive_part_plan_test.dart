import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/archive/archive_part_plan.dart';

void main() {
  test('文字留在第一包，媒體完整分配一次，包名與順序穩定', () {
    final sizes = {
      'data/events.json': 500,
      'media/a': 3000,
      'media/b': 3000,
      'media/c': 3000,
    };
    final result = ArchivePartPlan(
      sizes: sizes,
      base: 'backup',
      manifestBytes: 1000,
      maxBytes: 7000,
    );
    expect(result.files, [
      ['data/events.json', 'media/a'],
      ['media/b'],
      ['media/c'],
    ]);
    expect(result.names, [
      'backup_part01-of-03.zip',
      'backup_part02-of-03.zip',
      'backup_part03-of-03.zip',
    ]);
    expect(result.files.expand((part) => part).toSet(), sizes.keys.toSet());
    expect(sizes, hasLength(4));
  });

  test('單包、零媒體、首包太大、單檔太大與無效上限', () {
    final single = ArchivePartPlan(
      sizes: {'data/events.json': 20, 'media/a': 30},
      base: 'backup',
      manifestBytes: 100,
    );
    expect(single.names, ['backup.zip']);
    expect(
      ArchivePartPlan(
        sizes: {'data/events.json': 20},
        base: 'backup',
        manifestBytes: 100,
        maxBytes: 6000,
      ).files,
      [
        ['data/events.json'],
      ],
    );
    expect(
      () => ArchivePartPlan(
        sizes: {'data/events.json': 5000},
        base: 'backup',
        manifestBytes: 1000,
        maxBytes: 2000,
      ),
      throwsA(isA<ArchivePartSizeException>()),
    );
    expect(
      () => ArchivePartPlan(
        sizes: {'media/a': 10000},
        base: 'backup',
        manifestBytes: 1000,
        maxBytes: 6000,
      ),
      throwsA(isA<ArchivePartSizeException>()),
    );
    expect(
      () => ArchivePartPlan(
        sizes: {},
        base: 'backup',
        manifestBytes: 1,
        maxBytes: 0,
      ),
      throwsArgumentError,
    );
  });

  test('索引超過兩位數仍唯一，文字膨脹與 ZIP64 標頭預算不截斷', () {
    expect(
      ArchivePartPlan.partName('backup', 101, 120),
      'backup_part101-of-120.zip',
    );
    expect(
      ArchivePartPlan.bound('media/large', 0x100000000),
      greaterThan(0x100000000),
    );
    expect(ArchivePartPlan.bound('data/text', 4096), greaterThan(4096));
  });
}
