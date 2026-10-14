"""以 ADB 操作可見介面，保存 demo 驗證畫面與無障礙文字。"""
import re
import sys
import xml.etree.ElementTree as ET
from device_snapshot import adb, ROOT

ARTIFACTS = ROOT / 'build' / 'demo_archive_validation'


def dump(label='current'):
    adb('shell', 'uiautomator', 'dump', '/sdcard/lc_demo_ui.xml')
    raw = adb('shell', 'cat', '/sdcard/lc_demo_ui.xml')
    (ARTIFACTS / (label + '.xml')).write_bytes(raw)
    return ET.fromstring(raw)


def descriptions(tree):
    return [n.attrib.get('content-desc') or n.attrib.get('text') for n in tree.iter('node') if n.attrib.get('content-desc') or n.attrib.get('text')]


if __name__ == '__main__':
    action, text = sys.argv[1:3]
    if action == 'capture':
        print('\n'.join(descriptions(dump(text))))
        (ARTIFACTS / (text + '.png')).write_bytes(adb('exec-out', 'screencap', '-p'))
    elif action == 'tap':
        tree = dump()
        matches = [n for n in tree.iter('node') if text in (n.attrib.get('content-desc', '') + n.attrib.get('text', ''))]
        clickable = [n for n in matches if n.attrib.get('clickable') == 'true']
        matches = clickable or matches
        if not matches:
            raise RuntimeError(f'找不到可點擊的 {text}: {descriptions(tree)}')
        bounds = [int(v) for v in re.findall(r'\d+', matches[0].attrib['bounds'])]
        adb('shell', 'input', 'tap', str((bounds[0] + bounds[2]) // 2), str((bounds[1] + bounds[3]) // 2))
        print('Tapped:', text)
