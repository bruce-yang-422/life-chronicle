import 'package:flutter/services.dart';

class StorageSnapshot {
  const StorageSnapshot(this.appBytes, this.freeBytes);
  final int appBytes, freeBytes;
}

abstract interface class StoragePlatform {
  Future<StorageSnapshot> snapshot();
}

class DeviceStoragePlatform implements StoragePlatform {
  static const _channel = MethodChannel('life_chronicle/attachments');
  @override
  Future<StorageSnapshot> snapshot() async {
    final data = await _channel.invokeMapMethod<String, dynamic>(
      'storageUsage',
    );
    final app = (data?['appBytes'] as num?)?.toInt();
    final free = (data?['freeBytes'] as num?)?.toInt();
    if (app == null || free == null || app < 0 || free < 0) {
      throw const FormatException('Invalid storage snapshot');
    }
    return StorageSnapshot(app, free);
  }
}
