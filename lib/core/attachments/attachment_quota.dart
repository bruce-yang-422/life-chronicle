/// 每篇附件依引用計算邏輯容量，與實體副本去重無關（企劃書 §7.1）。
abstract final class AttachmentQuota {
  static const limitBytes = 25000000;

  static void check({required int usedBytes, required int addedBytes}) {
    if (usedBytes < 0 || addedBytes < 0) {
      throw ArgumentError.value((usedBytes, addedBytes));
    }
    if (usedBytes + addedBytes > limitBytes) {
      throw AttachmentQuotaExceeded(usedBytes, addedBytes);
    }
  }
}

class AttachmentQuotaExceeded implements Exception {
  const AttachmentQuotaExceeded(this.usedBytes, this.addedBytes);

  final int usedBytes;
  final int addedBytes;
  int get excessBytes => usedBytes + addedBytes - AttachmentQuota.limitBytes;
}
