import 'package:flutter/services.dart';

import '../../core/attachments/photo_compression.dart';

class PhotoInfo {
  const PhotoInfo(this.width, this.height, {this.hasGps});
  final bool? hasGps;
  final int width, height;
}

class PhotoOutput {
  const PhotoOutput(
    this.path,
    this.width,
    this.height,
    this.bytes,
    this.mediaType,
    this.quality,
    this.keptOriginal,
  );
  final String path, mediaType;
  final int width, height, bytes;
  final int? quality;
  final bool keptOriginal;
}

abstract interface class PhotoPlatform {
  Future<PhotoInfo?> inspect(String path);
  Future<PhotoOutput> compress(
    String path,
    String output,
    PhotoPreset preset,
    String requestId, {
    bool keepGps = true,
  });
  Future<PhotoOutput> preview(
    String path,
    String output,
    int longEdge,
    String requestId,
  );
  Future<void> cancel(String requestId);
}

class DevicePhotoPlatform implements PhotoPlatform {
  static const channel = MethodChannel('life_chronicle/photos');
  @override
  Future<PhotoInfo?> inspect(String path) async {
    final info = await channel.invokeMapMethod<String, dynamic>('inspect', {
      'path': path,
    });
    return info == null
        ? null
        : PhotoInfo(
            info['width'] as int,
            info['height'] as int,
            hasGps: info['hasGps'] as bool?,
          );
  }

  @override
  Future<PhotoOutput> compress(
    String path,
    String output,
    PhotoPreset preset,
    String requestId, {
    bool keepGps = true,
  }) async {
    final info = (await channel.invokeMapMethod<String, dynamic>('compress', {
      'path': path,
      'output': output,
      'longEdge': preset.longEdge,
      'requestId': requestId,
      'keepGps': keepGps,
    }))!;
    return PhotoOutput(
      info['path'] as String,
      info['width'] as int,
      info['height'] as int,
      info['bytes'] as int,
      info['mediaType'] as String,
      info['quality'] as int?,
      info['keptOriginal'] as bool,
    );
  }

  @override
  Future<PhotoOutput> preview(
    String path,
    String output,
    int longEdge,
    String requestId,
  ) async {
    final info = (await channel.invokeMapMethod<String, dynamic>('preview', {
      'path': path,
      'output': output,
      'longEdge': longEdge,
      'requestId': requestId,
    }))!;
    return PhotoOutput(
      info['path'] as String,
      info['width'] as int,
      info['height'] as int,
      info['bytes'] as int,
      info['mediaType'] as String,
      info['quality'] as int?,
      info['keptOriginal'] as bool,
    );
  }

  @override
  Future<void> cancel(String requestId) =>
      channel.invokeMethod<void>('cancel', {'requestId': requestId});
}
