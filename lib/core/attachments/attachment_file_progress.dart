/// 單批處理件數；完成處理不代表資料庫交易已提交。
class AttachmentFileProgress {
  const AttachmentFileProgress(this.name, this.completed, this.total);
  final String name;
  final int completed, total;
  int get remaining => total - completed;
}
