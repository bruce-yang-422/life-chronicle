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

/// 額度顯示快照；草稿與已保存引用分開，實體去重不減免容量。
class AttachmentUsage {
  const AttachmentUsage({
    this.usedBytes = 0,
    this.count = 0,
    this.pendingBytes = 0,
    this.pendingCount = 0,
  });

  final int usedBytes, count, pendingBytes, pendingCount;
  int get totalBytes => usedBytes + pendingBytes;
  int get remainingBytes => AttachmentQuota.limitBytes - totalBytes;
  bool get isOverLimit => remainingBytes < 0;
  bool get isLow => remainingBytes >= 0 && remainingBytes < 5000000;
}
