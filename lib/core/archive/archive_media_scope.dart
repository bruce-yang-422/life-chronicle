/// 僅決定是否納入媒體副本；附件與其他結構化資料仍保留。
class ArchiveMediaScope {
  ArchiveMediaScope({
    this.includeMedia = true,
    Set<String> excludedBlobIds = const {},
  }) : excludedBlobIds = Set.unmodifiable(excludedBlobIds);

  final bool includeMedia;
  final Set<String> excludedBlobIds;

  String get type => !includeMedia
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
