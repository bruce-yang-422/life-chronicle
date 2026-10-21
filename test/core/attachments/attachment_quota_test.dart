import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/attachments/attachment_quota.dart';

void main() {
  test('十進位 25 MB 邊界與精確超額', () {
    AttachmentQuota.check(usedBytes: 22000000, addedBytes: 3000000);
    expect(
      () => AttachmentQuota.check(usedBytes: 22000000, addedBytes: 3000001),
      throwsA(
        isA<AttachmentQuotaExceeded>().having(
          (error) => error.excessBytes,
          '超額',
          1,
        ),
      ),
    );
  });

  test('既有超額時新增空檔也不能繞過規則', () {
    expect(
      () => AttachmentQuota.check(usedBytes: 30000000, addedBytes: 0),
      throwsA(isA<AttachmentQuotaExceeded>()),
    );
    expect(
      () => AttachmentQuota.check(usedBytes: 30000000, addedBytes: 1),
      throwsA(isA<AttachmentQuotaExceeded>()),
    );
  });

  test('不接受負數以免抵銷既有額度', () {
    expect(
      () => AttachmentQuota.check(usedBytes: -1, addedBytes: 1),
      throwsArgumentError,
    );
    expect(
      () => AttachmentQuota.check(usedBytes: 1, addedBytes: -1),
      throwsArgumentError,
    );
  });
}
