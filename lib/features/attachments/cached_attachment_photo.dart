import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/platform/photo_platform.dart';
import '../../data/platform/attachment_platform.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../data/repositories/photo_import_session.dart';

final photoPreviewPlatformProvider = Provider<PhotoPlatform>(
  (ref) => DevicePhotoPlatform(),
);
final attachmentThumbnailProvider = FutureProvider.autoDispose
    .family<File, ({String eventId, String path})>((ref, key) async {
      final token = ImportCancellation();
      ref.onDispose(() => token.cancelled = true);
      final repository = await ref.watch(attachmentRepositoryProvider.future);
      // 在讀取附件或快取前重新確認主角與私密權限。
      await repository.usedBytes(key.eventId);
      final files = await repository.watch(key.eventId).first;
      final stored = files
          .where((file) => file.blob.path == key.path)
          .firstOrNull;
      if (stored == null) throw ImportIntegrityException();
      final source = PreparedAttachment(
        AttachmentSource(stored.blob.path, stored.attachment.originalFilename),
        stored.blob.byteSize,
        stored.blob.sha256,
        AttachmentMetadata(mediaType: stored.blob.mediaType),
        stored.blob,
        sourceBytes: stored.blob.byteSize,
      );
      final session = PhotoImportSession(
        repository,
        ref.watch(photoPreviewPlatformProvider),
      );
      return session.preview(source, 512, token);
    }, retry: (retryCount, error) => null);

class CachedAttachmentPhoto extends ConsumerWidget {
  const CachedAttachmentPhoto({
    super.key,
    required this.eventId,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.label,
  });
  final String eventId, path;
  final String? label;
  final double? width, height;
  final BoxFit fit;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref.watch(
      attachmentThumbnailProvider((eventId: eventId, path: path)),
    );
    final fallback = SizedBox(
      width: width,
      height: height,
      child: const Icon(Icons.image_not_supported_outlined),
    );
    return image.when(
      data: (file) => _CachedImage(
        file: file,
        width: width,
        height: height,
        fit: fit,
        label: label,
      ),
      error: (_, stack) => fallback,
      loading: () => fallback,
    );
  }
}

class _CachedImage extends StatefulWidget {
  const _CachedImage({
    required this.file,
    this.width,
    this.height,
    required this.fit,
    this.label,
  });
  final File file;
  final double? width, height;
  final BoxFit fit;
  final String? label;
  @override
  State<_CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<_CachedImage> {
  late ImageProvider _image = FileImage(widget.file);
  @override
  void didUpdateWidget(covariant _CachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _image.evict();
      _image = FileImage(widget.file);
    }
  }

  @override
  void dispose() {
    _image.evict();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Image(
    image: _image,
    width: widget.width,
    height: widget.height,
    fit: widget.fit,
    semanticLabel: widget.label,
    errorBuilder: (_, error, stack) => SizedBox(
      width: widget.width,
      height: widget.height,
      child: const Icon(Icons.image_not_supported_outlined),
    ),
  );
}
