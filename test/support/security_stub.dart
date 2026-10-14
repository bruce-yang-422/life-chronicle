import 'package:life_chronicle/data/platform/security_platform.dart';
import 'package:life_chronicle/data/providers.dart';
import 'package:life_chronicle/data/repositories/time_display_store.dart';
import 'package:life_chronicle/features/settings/time_display_settings.dart';

class SecurityStub implements SecurityPlatform {
  bool succeeds = false;
  bool previewHidden = false;
  @override
  Future<bool> authenticate(
    String reason, {
    Map<String, String> prompt = const {},
  }) async => succeeds;
  @override
  Future<void> hidePreview(bool enabled) async {
    previewHidden = enabled;
  }
}

final securityTestOverrides = [
  timeDisplayStoreProvider.overrideWith((ref) async => MemoryTimeDisplayStore()),
  securityStorageProvider.overrideWith((ref) => MemorySecurityStorage()),
  securityPlatformProvider.overrideWith((ref) => SecurityStub()),
];
