import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/editor/event_draft.dart';

abstract class EventDraftStore {
  Future<EventDraft?> load(String key);
  Future<void> save(String key, EventDraft draft);
  Future<void> remove(String key);
}

/// 草稿寫入持久性目錄，依序原子替換，避免較舊的輸入蓋掉新輸入。
class FileEventDraftStore implements EventDraftStore {
  FileEventDraftStore(this.directory);
  final Directory directory;
  Future<void> _writes = Future.value();
  static Future<FileEventDraftStore> open() async => FileEventDraftStore(
    Directory(p.join((await getApplicationSupportDirectory()).path, 'drafts')),
  );
  File _file(String key) {
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(key)) {
      throw ArgumentError.value(key);
    }
    return File(p.join(directory.path, '$key.json'));
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _writes.then((_) => action());
    _writes = next.catchError((Object error) {});
    return next;
  }

  @override
  Future<EventDraft?> load(String key) async {
    await _writes;
    final file = _file(key);
    if (!await file.exists()) return null;
    return EventDraft.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> save(String key, EventDraft draft) {
    final payload = jsonEncode(draft.toJson());
    return _enqueue(() async {
      final file = _file(key);
      await directory.create(recursive: true);
      final temporary = File('${file.path}.partial');
      await temporary.writeAsString(payload, flush: true);
      await temporary.rename(file.path);
    });
  }

  @override
  Future<void> remove(String key) => _enqueue(() async {
    final file = _file(key);
    if (await file.exists()) await file.delete();
  });
}

class MemoryEventDraftStore implements EventDraftStore {
  final _drafts = <String, String>{};
  @override
  Future<EventDraft?> load(String key) async => _drafts[key] == null
      ? null
      : EventDraft.fromJson(jsonDecode(_drafts[key]!) as Map<String, dynamic>);
  @override
  Future<void> save(String key, EventDraft draft) async {
    _drafts[key] = jsonEncode(draft.toJson());
  }

  @override
  Future<void> remove(String key) async {
    _drafts.remove(key);
  }
}
