import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/archive/commonmark_writer.dart';
import 'package:life_chronicle/core/archive/archive_integrity.dart';

void main() {
  test('純文字跳脫格式、HTML 與清單並使用硬換行', () {
    expect(
      CommonMarkWriter.text('# * [x]\r\n1. <script>\\'),
      '\\# \\* \\[x\\]\\\n1\\. \\<script\\>\\\\',
    );
    expect(CommonMarkWriter.heading('one\ntwo'), '# one two\n\n');
    expect(CommonMarkWriter.section('empty', ' \n'), '');
    expect(CommonMarkWriter.section(null, 'body'), 'body\n\n');
    expect(
      CommonMarkWriter.html('<img a="x">&'),
      '&lt;img a=&quot;x&quot;&gt;&amp;',
    );
  });
  test('安全路徑與校驗清單拒絕逃逸、重複與自身', () {
    for (final path in [
      '/tmp/x',
      '../x',
      'media/../x',
      'C:/x',
      'a\\b',
      '.hidden',
      'a//b',
      'a/./b',
    ]) {
      expect(ArchiveIntegrity.safePath(path), isFalse, reason: path);
    }
    final hash = ArchiveIntegrity.hash([1, 2, 3]);
    expect(ArchiveIntegrity.parseSums('$hash  data/events.json\n'), {
      'data/events.json': hash,
    });
    expect(
      () => ArchiveIntegrity.parseSums(
        '$hash  data/events.json\n$hash  data/events.json\n',
      ),
      throwsA(isA<ArchiveIntegrityException>()),
    );
  });
  test('只有根目錄兩份標準控制檔可使用大寫', () {
    expect(ArchiveIntegrity.safePath('README.md'), isTrue);
    expect(ArchiveIntegrity.safePath('SHA256SUMS.txt'), isTrue);
    for (final path in [
      'Readme.md',
      'README.MD',
      'data/README.md',
      'data/Events.json',
      'SHA256SUMS.TXT',
      '../README.md',
      '/README.md',
    ]) {
      expect(ArchiveIntegrity.safePath(path), isFalse, reason: path);
    }
    final hash = ArchiveIntegrity.hash([1]);
    expect(ArchiveIntegrity.parseSums('$hash  README.md\n'), {
      'README.md': hash,
    });
    expect(
      () => ArchiveIntegrity.parseSums('$hash  SHA256SUMS.txt\n'),
      throwsA(isA<ArchiveIntegrityException>()),
    );
  });
}
