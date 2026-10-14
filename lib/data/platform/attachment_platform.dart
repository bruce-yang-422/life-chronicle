import 'dart:io';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class AttachmentMetadata {
  const AttachmentMetadata({
    this.mediaType = 'application/octet-stream',
    this.capturedAt,
    this.latitude,
    this.longitude,
  });
  final String mediaType;
  final DateTime? capturedAt;
  final double? latitude, longitude;
}

/// 平台差異集中於此；檔案複製及雜湊不依賴 Android。
abstract class AttachmentPlatform {
  Future<int> availableBytes(String directory);
  Future<AttachmentMetadata> metadata(String path);
  Future<void> open(String path, String mediaType);
}

class DeviceAttachmentPlatform implements AttachmentPlatform {
  static const _channel = MethodChannel('life_chronicle/attachments');
  @override
  Future<int> availableBytes(String directory) async =>
      (await _channel.invokeMethod<num>('availableBytes', {
        'path': directory,
      }))!.toInt();
  @override
  Future<AttachmentMetadata> metadata(String path) async {
    final values = await _channel.invokeMapMethod<String, dynamic>('metadata', {
      'path': path,
    });
    return AttachmentMetadata(
      mediaType: values?['mediaType'] as String? ?? 'application/octet-stream',
      capturedAt: values?['capturedAt'] == null
          ? null
          : DateTime.tryParse(values!['capturedAt'] as String),
      latitude: (values?['latitude'] as num?)?.toDouble(),
      longitude: (values?['longitude'] as num?)?.toDouble(),
    );
  }

  @override
  Future<void> open(String path, String mediaType) async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('open', {
        'path': path,
        'mediaType': mediaType,
      });
    } else {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path, mimeType: mediaType)]),
      );
    }
  }
}
