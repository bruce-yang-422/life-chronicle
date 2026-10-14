import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

abstract interface class SecurityStorage {
  Future<String?> read();
  Future<void> write(String value);
}

class DeviceSecurityStorage implements SecurityStorage {
  static const _key = 'life_chronicle_security_v1';
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(resetOnError: false),
  );
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
}

class MemorySecurityStorage implements SecurityStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String text) async {
    value = text;
  }
}

abstract interface class SecurityPlatform {
  Future<bool> authenticate(
    String reason, {
    Map<String, String> prompt = const {},
  });
  Future<void> hidePreview(bool enabled);
}

class DeviceSecurityPlatform implements SecurityPlatform {
  final _auth = LocalAuthentication();
  @override
  Future<bool> authenticate(
    String reason, {
    Map<String, String> prompt = const {},
  }) async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      return await _auth.authenticate(
        localizedReason: reason,
        authMessages: [
          AndroidAuthMessages(
            signInTitle: prompt['title'],
            signInHint: reason,
            cancelButton: prompt['cancel'],
          ),
          IOSAuthMessages(
            cancelButton: prompt['cancel'],
            localizedFallbackTitle: prompt['fallback'],
          ),
        ],
        biometricOnly: false,
        persistAcrossBackgrounding: false,
      );
    } on LocalAuthException {
      return false;
    }
  }

  @override
  Future<void> hidePreview(bool enabled) async {
    if (Platform.isAndroid) {
      await const MethodChannel('life_chronicle/security')
          .invokeMethod<void>('hidePreview', {'enabled': enabled});
    }
  }
}
