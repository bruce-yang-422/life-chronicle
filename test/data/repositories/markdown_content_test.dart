import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';

import 'harness.dart';

void main() {
  test('記述、草稿與追加回顧原樣保存 Markdown 和手機複合 emoji', () async {
    final h = await Harness.create();
    try {
      const text = '# 回憶 🎉\n\n**重要** 👍🏽 👨‍👩‍👧‍👦\n\n- 和家人旅行';
      final repository = EventContentRepository(h.context());
      final id = await repository.save(
        EventDraft(
          title: '生活 🙂',
          sections: [DraftSection(content: text)],
        ),
      );
      final restored = (await repository.load(id))!;
      expect(restored.sections.single.contentMd, text);
      final draft = EventDraft.fromJson(restored.toDraft().toJson());
      expect(draft.sections.single.content, text);
      await repository.appendReflection(id, text);
      final reflected = (await repository.load(id))!;
      expect(reflected.reflections.single.contentMd, text);
      expect(reflected.event.title, '生活 🙂');
    } finally {
      await h.close();
    }
  });
}
