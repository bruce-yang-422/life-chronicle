/// 第一階段空間門檻採十進位 bytes，與事件的邏輯附件額度分開。
abstract final class StorageSpace {
  static const reserveBytes = 500000000;
  static const lowBytes = 1000000000;
  static bool canAdd(int freeBytes, int addedBytes) =>
      addedBytes >= 0 && freeBytes >= addedBytes + reserveBytes;
}
