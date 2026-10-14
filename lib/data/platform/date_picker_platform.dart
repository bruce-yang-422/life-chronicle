import 'dart:io';

import 'package:flutter/services.dart';

/// Android 使用原生日期對話框；其他平台由介面提供系統風格選擇器。
abstract final class DeviceDatePicker {
  static bool get supported => Platform.isAndroid;
  static const _channel = MethodChannel('life_chronicle/date_picker');
  static Future<DateTime?> choose(DateTime initial) async {
    final value = await _channel.invokeMapMethod<String, int>('choose', {
      'year': initial.year,
      'month': initial.month,
      'day': initial.day,
    });
    return value == null
        ? null
        : DateTime(value['year']!, value['month']!, value['day']!);
  }
}
