import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/attachments/photo_compression.dart';
import '../../core/attachments/photo_preferences.dart';
import '../../data/repositories/photo_preferences_store.dart';
import '../../l10n/app_localizations.dart';
import '../shared/ios_group.dart';
import 'time_display_settings.dart';

final photoPreferencesStoreProvider = FutureProvider<PhotoPreferencesStore>(
  (ref) => FilePhotoPreferencesStore.open(),
);

class PhotoPreferencesController extends AsyncNotifier<PhotoPreferences> {
  @override
  Future<PhotoPreferences> build() async =>
      (await ref.watch(photoPreferencesStoreProvider.future)).load();
  Future<void> save(PhotoPreferences value) async {
    await (await ref.read(photoPreferencesStoreProvider.future)).save(value);
    state = AsyncData(value);
  }
}

final photoPreferencesProvider =
    AsyncNotifierProvider<PhotoPreferencesController, PhotoPreferences>(
      PhotoPreferencesController.new,
    );

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.appSettings)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          IosGroup(
            children: [
              ListTile(
                title: Text(l.displaySettings),
                leading: const Icon(Icons.schedule),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const TimeDisplaySettingsPage(),
                  ),
                ),
              ),
              ListTile(
                title: Text(l.photoSaveSettings),
                leading: const Icon(Icons.photo_outlined),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PhotoSettingsPage(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PhotoSettingsPage extends ConsumerStatefulWidget {
  const PhotoSettingsPage({super.key});
  @override
  ConsumerState<PhotoSettingsPage> createState() => _PhotoSettingsPageState();
}

class _PhotoSettingsPageState extends ConsumerState<PhotoSettingsPage> {
  bool _saving = false;
  Future<void> _save(PhotoPreferences value) async {
    setState(() => _saving = true);
    try {
      await ref.read(photoPreferencesProvider.notifier).save(value);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).photoSettingsError),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(photoPreferencesProvider);
    final value = state.value;
    return Scaffold(
      appBar: AppBar(title: Text(l.photoSaveSettings)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (state.isLoading || _saving) const LinearProgressIndicator(),
          if (state.hasError) ...[
            Text(l.photoSettingsError),
            TextButton(
              onPressed: () => ref.invalidate(photoPreferencesProvider),
              child: Text(l.photoSettingsRetry),
            ),
          ],
          if (value != null) ...[
            IosGroup(
              children: [
                SwitchListTile.adaptive(
                  title: Text(l.photoAlwaysCompress),
                  subtitle: Text(l.photoDefaultHelp),
                  value: value.alwaysCompress,
                  onChanged: _saving
                      ? null
                      : (enabled) => _save(
                          PhotoPreferences(
                            alwaysCompress: enabled,
                            preset: value.preset,
                            keepGps: value.keepGps,
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l.photoDefaultPreset,
                    ),
                    child: DropdownButton<PhotoPreset>(
                      value: value.preset,
                      isExpanded: true,
                      items: [
                        for (final preset in PhotoPreset.values)
                          DropdownMenuItem(
                            value: preset,
                            child: Text(
                              switch (preset) {
                                PhotoPreset.high => l.photoHigh,
                                PhotoPreset.standard => l.photoStandard,
                                PhotoPreset.compact => l.photoCompact,
                              },
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _saving
                          ? null
                          : (preset) {
                              if (preset != null) {
                                _save(
                                  PhotoPreferences(
                                    alwaysCompress: value.alwaysCompress,
                                    preset: preset,
                                    keepGps: value.keepGps,
                                  ),
                                );
                              }
                            },
                    ),
                  ),
                ),
              ],
            ),
            IosGroup(
              children: [
                SwitchListTile.adaptive(
                  title: Text(l.photoRemoveGps),
                  subtitle: Text(l.photoGpsRemovalHelp),
                  value: !value.keepGps,
                  onChanged: _saving
                      ? null
                      : (remove) => _save(
                          PhotoPreferences(
                            alwaysCompress: value.alwaysCompress,
                            preset: value.preset,
                            keepGps: !remove,
                          ),
                        ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.photoSettingsScope),
            ),
          ],
        ],
      ),
    );
  }
}
