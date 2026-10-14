import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/data/platform/security_platform.dart';
import 'package:life_chronicle/data/repositories/security_service.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';
import 'package:life_chronicle/data/repositories/search_repository.dart';
import 'package:life_chronicle/data/repositories/repository_context.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';

import '../../support/security_stub.dart';
import 'harness.dart';

void main() {
  late Harness h;
  late MemorySecurityStorage storage;
  late SecurityStub platform;
  late SecurityService service;
  late DateTime now;
  late SecurityCodes codes;
  setUp(() async {
    h = await Harness.create();
    storage = MemorySecurityStorage();
    platform = SecurityStub();
    now = DateTime.utc(2026);
    service = SecurityService(
      storage,
      platform,
      h.db,
      clock: () => now,
      iterations: 2,
    );
    await service.load();
    codes = await SecurityService.prepareCodes('abc123', iterations: 2);
    await service.install(
      codes,
      const SecurityConfig(appLock: true, privateProtection: true),
    );
  });
  tearDown(() async {
    service.dispose();
    await h.close();
  });
  test('重新開啟先鎖定；五次錯誤與暫停在重新開啟後仍保留，資料不清除', () async {
    await EventContentRepository(h.context())
        .save(EventDraft(title: 'unchanged'));
    final reopened = SecurityService(
      storage,
      platform,
      h.db,
      clock: () => now,
      iterations: 2,
    );
    try {
      await reopened.load();
      expect(reopened.locked, isTrue);
      expect(reopened.canReadPrivate, isFalse);
      for (var i = 0; i < 5; i++) {
        expect(await reopened.authenticatePassword('wrong'), isFalse);
      }
      expect(reopened.pauseRemaining, const Duration(seconds: 30));
      await expectLater(
        reopened.authenticatePassword('abc123'),
        throwsA(isA<SecurityPaused>()),
      );
      final second = SecurityService(
        storage,
        platform,
        h.db,
        clock: () => now,
        iterations: 2,
      );
      try {
        await second.load();
        expect(second.pauseRemaining, const Duration(seconds: 30));
      } finally {
        second.dispose();
      }
      now = now.add(const Duration(seconds: 30));
      expect(await reopened.authenticatePassword('abc123'), isTrue);
      expect(reopened.locked, isFalse);
      expect(reopened.canReadPrivate, isFalse);
      expect((await h.db.select(h.db.events).getSingle()).title, 'unchanged');
    } finally {
      reopened.dispose();
    }
    expect(storage.value, isNot(contains('abc123')));
    expect(storage.value, isNot(contains(codes.recovery)));
    expect(storage.value, isNot(contains(codes.family)));
    expect(platform.previewHidden, isTrue);
  });
  test('私密指定密碼時不接受原生驗證；離開逾時恢復隱藏', () async {
    await service.updateConfig(
      const SecurityConfig(privateProtection: true, passwordOnly: true),
    );
    platform.succeeds = true;
    expect(
      await service.authenticateNative('reason', privateAccess: true),
      isFalse,
    );
    expect(
      await service.authenticatePassword('abc123', privateAccess: true),
      isTrue,
    );
    expect(service.canReadPrivate, isTrue);
    service.leave();
    now = now.add(const Duration(seconds: 60));
    service.resume();
    expect(service.canReadPrivate, isFalse);
  });
  test('家屬預設不可讀私密、不可看或改安全性；登入留下修訂紀錄', () async {
    service.lock();
    expect(
      await service.authenticatePassword(codes.family, familyName: '家屬'),
      isTrue,
    );
    expect(service.family, isTrue);
    expect(service.canReadPrivate, isFalse);
    expect(service.ownerVerified, isFalse);
    await expectLater(
      service.updateConfig(const SecurityConfig(familyPrivate: true)),
      throwsStateError,
    );
    expect(await service.authenticateNative('reason', owner: true), isFalse);
    expect(
      (await h.db.select(h.db.changeHistory).get()).last.operation,
      'family_unlock',
    );
    expect(
      (await h.db.select(h.db.changeHistory).get()).last.authorId,
      service.familyAuthorId,
    );
  });
  test('復原重設換新復原碼並保留固定遺族密碼；手動重新產生後舊碼失效', () async {
    service.lock();
    expect(
      await service.authorizeRecovery(codes.recovery.toLowerCase()),
      isTrue,
    );
    final newCodes = await SecurityService.prepareCodes(
      'new123',
      iterations: 2,
    );
    await service.resetPassword(newCodes);
    expect(await service.authorizeRecovery(codes.recovery), isFalse);
    expect(await service.authorizeRecovery(newCodes.recovery), isTrue);
    expect(await service.authenticatePassword('abc123'), isFalse);
    expect(await service.authenticatePassword('new123', owner: true), isTrue);
    final staged = await service.prepareCode();
    await service.installCode(staged.$2, recovery: false);
    expect(await service.authenticatePassword(codes.family), isFalse);
    expect(
      await service.authenticatePassword(staged.$1, familyName: '家屬'),
      isTrue,
    );
  });
  test('私密內容在資料層搜尋與詳情都被拒絕，授權後可以讀取', () async {
    final id = await EventContentRepository(h.context()).save(
      EventDraft(
        title: 'secret title',
        privacy: 'private',
        sections: [DraftSection(content: 'private narrative')],
      ),
    );
    final restricted = RepositoryContext(
      h.db,
      subjectId: h.profile.subjectId,
      actingAuthorId: h.profile.selfAuthorId,
      canReadPrivate: false,
    );
    expect(await EventContentRepository(restricted).load(id), isNull);
    expect(await SearchRepository(restricted).watch('secret').first, isEmpty);
    await expectLater(
      EventContentRepository(restricted)
          .save(EventDraft(eventId: id, title: 'overwrite')),
      throwsA(anything),
    );
    expect(
      (await EventContentRepository(h.context()).load(id))!.event.title,
      'secret title',
    );
    expect(
      await SearchRepository(h.context()).watch('secret').first,
      hasLength(1),
    );
  });
}
