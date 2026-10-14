import 'package:flutter/services.dart';

import '../../core/location/location_anchor.dart';

abstract interface class LocationPlatform {
  Future<LocationAnchor> current();
  Future<void> cancel();
  Future<void> openMap(LocationAnchor anchor);
  Future<void> openCopyright();
}

class DeviceLocationPlatform implements LocationPlatform {
  static const _channel = MethodChannel('life_chronicle/location');
  @override
  Future<LocationAnchor> current() async {
    final values = await _channel.invokeMapMethod<String, dynamic>('current');
    return LocationAnchor.fromJson(values!);
  }

  @override
  Future<void> cancel() => _channel.invokeMethod<void>('cancel');
  @override
  Future<void> openMap(LocationAnchor anchor) =>
      _channel.invokeMethod<void>('openMap', anchor.toJson());
  @override
  Future<void> openCopyright() => _channel.invokeMethod<void>('openCopyright');
}
