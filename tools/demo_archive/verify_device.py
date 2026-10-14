"""核對匯入後的 50 筆事件、來源設定及五個 APP 媒體副本。"""
from collections import Counter
import hashlib
import json
import re
from pathlib import Path
import zipfile
from device_snapshot import adb, PACKAGE, ROOT

validation = ROOT / 'build' / 'demo_archive_validation'
before = json.loads((sorted(validation.glob('before_20*'))[-1] / 'snapshot.json').read_text(encoding='utf-8'))
after = json.loads((max(validation.glob('after_*'), key=lambda path: path.stat().st_mtime) / 'snapshot.json').read_text(encoding='utf-8'))
metadata = json.loads((ROOT / 'demo_data' / 'demo_package.json').read_text(encoding='utf-8'))
data = after['data']
assert after['integrity'] == 'ok' and not after['foreign_keys']
assert set(metadata['event_ids']) == {e['event_id'] for e in data['events']}
assert not {e['event_id'] for e in before['data']['events']} & set(metadata['event_ids'])
assert len(data['events']) == 50 and len(data['attachments']) == 5 and len(data['event_sections']) == 100
assert data['subjects'] == before['data']['subjects'] and data['authors'] == before['data']['authors']
assert data['archive_settings'] == before['data']['archive_settings']
ages = Counter(int(re.search(r'模擬・(\d+)歲', e['title'])[1]) for e in data['events'])
assert set(ages) == set(range(16, 36)) and all(v in [2, 3] for v in ages.values())
blobs = {b['blob_id']: b for b in data['blobs']}
media = []
with zipfile.ZipFile(metadata['zip']) as archive:
    expected_sections = {s['event_section_id']: s['content_md'] for s in json.loads(archive.read('data/event_sections.json'))}
    assert expected_sections == {s['event_section_id']: s['content_md'] for s in data['event_sections']}
    manifest = json.loads(archive.read('manifest.json'))
    entries = {e['sha256']: e for e in manifest['files'] if e['path'].startswith('media/')}
    assert len(entries) == 5
    for attachment in data['attachments']:
        blob = blobs[attachment['blob_id']]
        content = adb('exec-out', 'run-as', PACKAGE, 'cat', blob['path'])
        assert blob['media_type'] == 'image/jpeg' and content[:2] == b'\xff\xd8'
        digest = hashlib.sha256(content).hexdigest()
        assert digest == blob['sha256'] and len(content) == blob['byte_size']
        assert archive.read(entries[digest]['path']) == content
        media.append({'name': attachment['original_filename'], 'bytes': len(content), 'sha256': digest, 'device_copy_matches_zip': True})
result = {
    'status': 'passed', 'removed_invalid_events': len(before['data']['events']),
    'events': 50, 'sections': 100, 'attachments': 5,
    'ages': dict(sorted(ages.items())), 'years': [2006, 2025],
    'profile_preserved': True, 'integrity': 'ok', 'foreign_key_errors': 0,
    'media': media, 'zip_sha256': metadata['sha256'],
    'unused_old_blobs_preserved': len(data['blobs']) - len(media),
    'device': 'emulator-5554 / Android 16 API 36',
    'interface_checks': ['繁中時間軸縮圖', '新居事件詳情與段落', '系統圖片檢視器開啟新居照片', '搜尋頁預設顯示可讀紀錄'],
    'local_checks': ['50 筆 ZIP 還原', '重複匯入不增加事件', '中文搜尋與附件名稱搜尋', '五份 JPG SHA-256'],
    'limitations': ['使用 debug 工具經正式還原核心匯入；正式匯入介面未完成', '包綁定目前模擬器主角 ID；不支援任意主角匯入', '故事篇章屬第二階段，未實作', '未進行 Android 實機驗收'],
}
(ROOT / 'demo_data' / 'demo_validation.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps(result, ensure_ascii=False))
