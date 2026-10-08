import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 介面文字集中管理的自動化檢查（企劃書 4.7、驗收 #32）。

/// 畫面程式所在目錄：禁止硬編碼介面文字。
const _uiDirs = ['lib/app', 'lib/features'];

/// 中日韓文字（含日文假名、韓文）。
final _cjk = RegExp(r'[぀-ヿ㐀-䶿一-鿿가-힯]');

/// 以字串常值傳入常見文字參數，例如 `Text('…')`、`label: '…'`。
final _literalTextArg = RegExp(
  r'''(\bText\(\s*|\b(label|tooltip|title|hintText|labelText|helperText|semanticLabel|semanticsLabel|message|confirmText|cancelText)\s*:\s*)(['"])''',
);

/// 單行字串常值。
final _stringLiteral = RegExp(r'''('(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*")''');

Iterable<File> _dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));

/// 去除行尾註解（不處理字串內含 `//` 的少見情況）。
String _stripComment(String line) {
  final trimmed = line.trimLeft();
  if (trimmed.startsWith('//')) return '';
  final index = line.indexOf(RegExp(r'\s//'));
  return index >= 0 ? line.substring(0, index) : line;
}

Map<String, Object?> _readArb(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

void main() {
  test('畫面程式中的字串常值不含中日韓文字', () {
    final violations = <String>[];
    for (final dir in _uiDirs) {
      for (final file in _dartFiles(dir)) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final code = _stripComment(lines[i]);
          for (final m in _stringLiteral.allMatches(code)) {
            if (_cjk.hasMatch(m.group(0)!)) {
              violations.add('${file.path}:${i + 1}: ${lines[i].trim()}');
            }
          }
        }
      }
    }
    expect(violations, isEmpty, reason: '請改用 lib/l10n/ 的 ARB 介面文字');
  });

  test('畫面程式不以字串常值作為顯示文字', () {
    final violations = <String>[];
    for (final dir in _uiDirs) {
      for (final file in _dartFiles(dir)) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (_literalTextArg.hasMatch(_stripComment(lines[i]))) {
            violations.add('${file.path}:${i + 1}: ${lines[i].trim()}');
          }
        }
      }
    }
    expect(violations, isEmpty, reason: '請改用 lib/l10n/ 的 ARB 介面文字');
  });

  test('繁體中文與英文 ARB 的介面文字鍵值完全一致', () {
    Set<String> keys(Map<String, Object?> arb) =>
        arb.keys.where((k) => !k.startsWith('@')).toSet();
    final zh = keys(_readArb('lib/l10n/app_zh.arb'));
    final en = keys(_readArb('lib/l10n/app_en.arb'));
    expect(zh.difference(en), isEmpty, reason: '英文缺少的鍵值');
    expect(en.difference(zh), isEmpty, reason: '繁體中文缺少的鍵值');
  });

  test('英文 ARB 不含中日韓文字', () {
    final en = _readArb('lib/l10n/app_en.arb');
    final violations = [
      for (final MapEntry(:key, :value) in en.entries)
        if (!key.startsWith('@') && value is String && _cjk.hasMatch(value))
          key,
    ];
    expect(violations, isEmpty);
  });

  test('檢查規則本身有效', () {
    expect(_cjk.hasMatch("Text('人生時間軸')"), isTrue);
    expect(_literalTextArg.hasMatch("child: Text('Timeline')"), isTrue);
    expect(_literalTextArg.hasMatch("label: 'Timeline',"), isTrue);
    expect(_literalTextArg.hasMatch('label: l10n.navTimeline,'), isFalse);
    expect(_stripComment('  // 中文註解'), isEmpty);
  });
}
