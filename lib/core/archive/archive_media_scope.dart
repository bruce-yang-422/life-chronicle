/// 匯出選擇；私密事件過濾與個別媒體副本排除分別處理。
class ArchiveMediaScope {
  ArchiveMediaScope({
    this.includeMedia = true,
    this.excludePrivateEvents = false,
    this.maxPartBytes,
    Set<String> excludedBlobIds = const {},
  }) : excludedBlobIds = Set.unmodifiable(excludedBlobIds);

  final bool includeMedia;
  final bool excludePrivateEvents;
  final int? maxPartBytes;
  final Set<String> excludedBlobIds;

  String get type => excludePrivateEvents
      ? 'custom'
      : !includeMedia
      ? 'no_media'
      : excludedBlobIds.isEmpty
      ? 'full'
      : 'custom';

  String? reasonFor(String blobId) => !includeMedia
      ? 'no_media'
      : excludedBlobIds.contains(blobId)
      ? 'user_excluded'
      : null;
}
