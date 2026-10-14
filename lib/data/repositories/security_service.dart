import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../../core/security/password_crypto.dart';
import '../db/app_database.dart';
import '../platform/security_platform.dart';
import 'profile_repository.dart';
import 'repository_context.dart';

class SecurityConfig {
  const SecurityConfig({
    this.appLock = false,
    this.privateProtection = false,
    this.passwordOnly = false,
    this.hidePreview = false,
    this.timeoutSeconds = 60,
    this.familyPrivate = false,
  });
  final bool appLock,
      privateProtection,
      passwordOnly,
      hidePreview,
      familyPrivate;
  final int timeoutSeconds;
  Map<String, Object> toJson() => {
    'app_lock': appLock,
    'private_protection': privateProtection,
    'password_only': passwordOnly,
    'hide_preview': hidePreview,
    'timeout_seconds': timeoutSeconds,
    'family_private': familyPrivate,
  };
  factory SecurityConfig.fromJson(Map<String, dynamic> json) {
    final timeout = json['timeout_seconds'] as int;
    if (![0, 60, 300].contains(timeout)) {
      throw const FormatException('無效的自動鎖定時間');
    }
    return SecurityConfig(
      appLock: json['app_lock'] as bool,
      privateProtection: json['private_protection'] as bool,
      passwordOnly: json['password_only'] as bool,
      hidePreview: json['hide_preview'] as bool,
      timeoutSeconds: timeout,
      familyPrivate: json['family_private'] as bool,
    );
  }
}

class SecurityCodes {
  const SecurityCodes(
    this.recovery,
    this.family,
    this.appHash,
    this.recoveryHash,
    this.familyHash,
  );
  final String recovery, family;
  final Map<String, Object> appHash, recoveryHash, familyHash;
}

class SecurityPaused implements Exception {
  const SecurityPaused(this.remaining);
  final Duration remaining;
}

/// 雜湊與設定僅保存於安全儲存區；驗證及家屬權限由共同服務處理。
class SecurityService extends ChangeNotifier {
  SecurityService(
    this.storage,
    this.platform,
    this.db, {
    DateTime Function()? clock,
    this.iterations = 600000,
  }) : clock = clock ?? DateTime.now;
  final SecurityStorage storage;
  final SecurityPlatform platform;
  final AppDatabase db;
  final DateTime Function() clock;
  final int iterations;
  bool loading = true,
      appUnlocked = false,
      privateUnlocked = false,
      family = false,
      background = false;
  Object? error;
  bool _manualLocked = false;
  SecurityConfig config = const SecurityConfig();
  PasswordAttempts attempts = PasswordAttempts();
  Map<String, Object?>? _app, _recovery, _family;
  DateTime? _leftAt;
  DateTime? _nativeSuccessAt;
  String? familyAuthorId;
  bool _ownerVerified = false, _authenticating = false, _disposed = false;
  bool get configured => _app != null;
  bool get ownerVerified => _ownerVerified && !family;
  bool get canReadPrivate =>
      !loading &&
      error == null &&
      (family
          ? config.familyPrivate
          : !config.privateProtection || privateUnlocked);
  bool get locked =>
      configured && (_manualLocked || (config.appLock && !appUnlocked));
  bool get hidden =>
      background && configured && (config.appLock || config.hidePreview);
  Duration get pauseRemaining => attempts.remaining(clock().toUtc());

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    _emit();
    try {
      final text = await storage.read();
      if (text != null) {
        final json = jsonDecode(text) as Map<String, dynamic>;
        if (json['version'] != 1) throw const FormatException('未知的安全性設定版本');
        config = SecurityConfig.fromJson(
          json['config'] as Map<String, dynamic>,
        );
        _app = Map<String, Object?>.from(json['app'] as Map);
        _recovery = Map<String, Object?>.from(json['recovery'] as Map);
        _family = Map<String, Object?>.from(json['family'] as Map);
        attempts = PasswordAttempts.fromJson(
          Map<String, Object?>.from(json['attempts'] as Map),
        );
        familyAuthorId = json['family_author_id'] as String?;
      }
      appUnlocked = !config.appLock;
      await platform.hidePreview(config.appLock || config.hidePreview);
    } catch (failure) {
      error = failure;
      appUnlocked = false;
    } finally {
      loading = false;
      _emit();
    }
  }

  Future<void> _save() async {
    await storage.write(
      jsonEncode({
        'version': 1,
        'config': config.toJson(),
        'app': _app,
        'recovery': _recovery,
        'family': _family,
        'attempts': attempts.toJson(),
        'family_author_id': familyAuthorId,
      }),
    );
  }

  void _checkPause() {
    if (pauseRemaining > Duration.zero) throw SecurityPaused(pauseRemaining);
  }

  void _ensureOwner() {
    if (family || !_ownerVerified) throw StateError('變更安全性設定必須先由本人驗證');
  }

  static Future<SecurityCodes> prepareCodes(
    String password, {
    int iterations = 600000,
  }) {
    if (!RegExp(r'^[A-Za-z0-9]{6,}$').hasMatch(password)) {
      throw ArgumentError('密碼至少六位英數字');
    }
    return Isolate.run(() {
      final recovery = PasswordCrypto.generateCode(),
          family = PasswordCrypto.generateCode();
      return SecurityCodes(
        recovery,
        family,
        PasswordCrypto.hash(password, iterations: iterations),
        PasswordCrypto.hash(
          PasswordCrypto.normalizeCode(recovery)!,
          iterations: iterations,
        ),
        PasswordCrypto.hash(
          PasswordCrypto.normalizeCode(family)!,
          iterations: iterations,
        ),
      );
    });
  }

  Future<void> install(SecurityCodes codes, SecurityConfig settings) async {
    if (configured) _ensureOwner();
    // 儲存前的抄寫確認由畫面完成；新資料只包含加鹽雜湊。
    final previous = (_app, _recovery, _family, config);
    _app = codes.appHash;
    _recovery = codes.recoveryHash;
    _family = codes.familyHash;
    config = settings;
    attempts.succeeded();
    try {
      await platform.hidePreview(config.appLock || config.hidePreview);
      await _save();
    } catch (_) {
      _app = previous.$1;
      _recovery = previous.$2;
      _family = previous.$3;
      config = previous.$4;
      rethrow;
    }
    appUnlocked = true;
    _manualLocked = false;
    family = false;
    privateUnlocked = false;
    _ownerVerified = true;
    _emit();
  }

  Future<void> updateConfig(SecurityConfig value) async {
    _ensureOwner();
    final previous = config;
    config = value;
    try {
      await platform.hidePreview(config.appLock || config.hidePreview);
      await _save();
    } catch (_) {
      config = previous;
      rethrow;
    }
    privateUnlocked = false;
    _emit();
  }

  Future<void> resetPassword(SecurityCodes codes) async {
    _ensureOwner();
    final previous = (_app, _recovery);
    _app = codes.appHash;
    _recovery = codes.recoveryHash;
    attempts.succeeded();
    try {
      await _save();
    } catch (_) {
      _app = previous.$1;
      _recovery = previous.$2;
      rethrow;
    }
    appUnlocked = true;
    privateUnlocked = false;
    family = false;
    _emit();
  }

  Future<(String, Map<String, Object>)> prepareCode() async {
    _ensureOwner();
    final code = PasswordCrypto.generateCode();
    final rounds = iterations;
    final hash = await Isolate.run(
      () => PasswordCrypto.hash(
        PasswordCrypto.normalizeCode(code)!,
        iterations: rounds,
      ),
    );
    return (code, hash);
  }

  Future<void> installCode(
    Map<String, Object> hash, {
    required bool recovery,
  }) async {
    _ensureOwner();
    final previous = recovery ? _recovery : _family;
    if (recovery) {
      _recovery = hash;
    } else {
      _family = hash;
    }
    try {
      await _save();
    } catch (_) {
      if (recovery) {
        _recovery = previous;
      } else {
        _family = previous;
      }
      rethrow;
    }
    _emit();
  }

  Future<bool> authenticateNative(
    String reason, {
    Map<String, String> prompt = const {},
    bool privateAccess = false,
    bool owner = false,
  }) async {
    _checkPause();
    if (family || (privateAccess && config.passwordOnly)) return false;
    if (_authenticating) return false;
    _authenticating = true;
    try {
      final succeeded = await platform.authenticate(reason, prompt: prompt);
      if (!succeeded) return false;
      _nativeSuccessAt = clock().toUtc();
      attempts.succeeded();
      await _save();
      appUnlocked = true;
      _manualLocked = false;
      if (privateAccess) privateUnlocked = true;
      if (owner) _ownerVerified = true;
      _emit();
      return true;
    } finally {
      _authenticating = false;
    }
  }

  Future<bool> authenticatePassword(
    String input, {
    bool privateAccess = false,
    bool owner = false,
    String familyName = '',
  }) async {
    _checkPause();
    if (_authenticating || !configured) return false;
    _authenticating = true;
    final appHash = _app!, familyHash = _family!;
    try {
      final result = await Isolate.run(
        () => PasswordCrypto.verify(input, appHash)
            ? 1
            : (!owner &&
                  PasswordCrypto.normalizeCode(input) != null &&
                  PasswordCrypto.verify(
                    PasswordCrypto.normalizeCode(input)!,
                    familyHash,
                  ))
            ? 2
            : 0,
      );
      if (result == 0 ||
          (result == 2 && privateAccess && !config.familyPrivate)) {
        attempts.failed(clock().toUtc());
        await _save();
        _emit();
        return false;
      }
      attempts.succeeded();
      family = result == 2;
      appUnlocked = true;
      _manualLocked = false;
      if (family) {
        _ownerVerified = false;
        privateUnlocked = config.familyPrivate;
        final profiles = ProfileRepository(db);
        final profile = await profiles.ensureDefaultProfile();
        familyAuthorId ??= await profiles.addAuthor(
          familyName,
          role: AuthorRole.family,
        );
        await RepositoryContext(
          db,
          subjectId: profile.subjectId,
          actingAuthorId: familyAuthorId!,
        ).recordChange(profile.subjectId, 'family_unlock');
      } else {
        if (owner) _ownerVerified = true;
        if (privateAccess) privateUnlocked = true;
      }
      await _save();
      _emit();
      return true;
    } finally {
      _authenticating = false;
    }
  }

  Future<bool> authorizeRecovery(String code) async {
    _checkPause();
    if (family || _authenticating || _recovery == null) return false;
    _authenticating = true;
    final record = _recovery!;
    try {
      final normalized = PasswordCrypto.normalizeCode(code);
      final success =
          normalized != null &&
          await Isolate.run(() => PasswordCrypto.verify(normalized, record));
      if (success) {
        attempts.succeeded();
        _ownerVerified = true;
      } else {
        attempts.failed(clock().toUtc());
      }
      await _save();
      _emit();
      return success;
    } finally {
      _authenticating = false;
    }
  }

  Future<String> regenerateCode({required bool recovery}) async {
    _ensureOwner();
    final code = PasswordCrypto.generateCode();
    final rounds = iterations;
    final hash = await Isolate.run(
      () => PasswordCrypto.hash(
        PasswordCrypto.normalizeCode(code)!,
        iterations: rounds,
      ),
    );
    if (recovery) {
      _recovery = hash;
    } else {
      _family = hash;
    }
    await _save();
    _emit();
    return code;
  }

  void lock() {
    _manualLocked = true;
    appUnlocked = false;
    privateUnlocked = false;
    _ownerVerified = false;
    family = false;
    _emit();
  }

  void leave() {
    background = true;
    _leftAt ??= clock().toUtc();
    _emit();
  }

  void resume() {
    final left = _leftAt;
    _leftAt = null;
    background = false;
    final nativeJustSucceeded =
        _nativeSuccessAt != null &&
        clock().toUtc().difference(_nativeSuccessAt!) <
            const Duration(seconds: 2);
    if (left != null &&
        configured &&
        !nativeJustSucceeded &&
        clock().toUtc().difference(left) >=
            Duration(seconds: config.timeoutSeconds)) {
      privateUnlocked = false;
      _ownerVerified = false;
      if (config.appLock) appUnlocked = false;
    }
    _emit();
  }
}
