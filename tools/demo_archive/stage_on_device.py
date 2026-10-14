"""將已校驗的 demo ZIP 與取代前證據複製到 APP 專用目錄。"""
import json
from pathlib import Path
import subprocess
from device_snapshot import ADB, PACKAGE, ROOT


def run(*args):
    subprocess.run([ADB, '-s', 'emulator-5554', *args], check=True)


metadata = ROOT / 'demo_data' / 'demo_package.json'
package = json.loads(metadata.read_text(encoding='utf-8'))
backups = sorted((ROOT / 'build' / 'demo_archive_validation').glob('before_*'))
if not backups:
    raise RuntimeError('缺少匯入前備份，停止')
for source, target in [
    (Path(package['zip']), 'demo_fixture.zip'),
    (metadata, 'demo_package.json'),
    (ROOT / 'demo_data' / 'baseline_sections.json', 'demo_baseline_sections.json'),
    (backups[-1] / 'snapshot.json', 'demo_before.json'),
]:
    if not source.is_file():
        raise RuntimeError(f'缺少 {source}')
    staging = '/data/local/tmp/life_chronicle_' + target
    run('push', str(source), staging)
    run('shell', 'chmod', '644', staging)
    run('shell', 'run-as', PACKAGE, 'cp', staging, 'files/' + target)
run('shell', 'am', 'start', '-n', PACKAGE + '/.MainActivity')
