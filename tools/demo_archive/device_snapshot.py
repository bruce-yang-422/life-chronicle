"""保存 demo 匯入前後的裝置資料；不清除或覆寫裝置資料。"""
import datetime
import json
from pathlib import Path
import sqlite3
import subprocess
import sys

ADB = r'C:\Users\User\AppData\Local\Android\sdk\platform-tools\adb.exe'
PACKAGE = 'io.github.bruce_yang_422.life_chronicle'
ROOT = Path(__file__).resolve().parents[2]


def adb(*args):
    return subprocess.run([ADB, '-s', 'emulator-5554', *args], check=True, capture_output=True).stdout


def snapshot(label):
    target = ROOT / 'build' / 'demo_archive_validation' / (label + '_' + datetime.datetime.now().strftime('%Y%m%d_%H%M%S'))
    target.mkdir(parents=True)
    adb('shell', 'am', 'force-stop', PACKAGE)
    (target / 'files.tar').write_bytes(adb('exec-out', 'run-as', PACKAGE, 'tar', '-cf', '-', 'files'))
    database = target / 'life_chronicle.sqlite'
    database.write_bytes(adb('exec-out', 'run-as', PACKAGE, 'cat', 'files/life_chronicle.sqlite'))
    with sqlite3.connect(database) as db:
        db.row_factory = sqlite3.Row
        tables = [row[0] for row in db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'search_index%' AND name NOT LIKE 'sqlite_%'")]
        data = {table: [dict(row) for row in db.execute(f'SELECT * FROM "{table}"')] for table in tables}
        report = {'directory': str(target), 'counts': {k: len(v) for k, v in data.items()}, 'integrity': db.execute('PRAGMA integrity_check').fetchone()[0], 'foreign_keys': [list(r) for r in db.execute('PRAGMA foreign_key_check')], 'data': data}
        (target / 'snapshot.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
        if label == 'before':
            context = {name: data[name] for name in ['subjects', 'authors', 'archive_settings', 'archive_sessions']}
            (ROOT / 'build' / 'demo_archive_validation' / 'target_context.json').write_text(json.dumps(context, ensure_ascii=False, indent=2), encoding='utf-8')
        print(json.dumps({k: v for k, v in report.items() if k != 'data'}, ensure_ascii=False))
    return target


if __name__ == '__main__':
    snapshot(sys.argv[1])
