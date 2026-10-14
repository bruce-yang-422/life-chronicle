import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/timestamp_display.dart';
import '../../data/repositories/time_display_store.dart';
import '../../l10n/app_localizations.dart';

final timeDisplayStoreProvider = FutureProvider<TimeDisplayStore>(
  (ref) => FileTimeDisplayStore.open(),
);

class TimeZoneController extends AsyncNotifier<String> {
  @override
  Future<String> build() async =>
      (await ref.watch(timeDisplayStoreProvider.future)).load();
  Future<void> select(String zone) async {
    await (await ref.read(timeDisplayStoreProvider.future)).save(zone);
    state = AsyncData(zone);
  }
}

final timeZoneProvider = AsyncNotifierProvider<TimeZoneController, String>(
  TimeZoneController.new,
);

String readableTimestamp(WidgetRef ref, AppLocalizations l, DateTime value) =>
    TimestampDisplay.format(
      value,
      ref.watch(timeZoneProvider).value ?? 'system',
      l.timestampPattern,
      l.localeName,
    );

class TimeDisplaySettingsPage extends ConsumerStatefulWidget {
  const TimeDisplaySettingsPage({super.key});
  @override
  ConsumerState<TimeDisplaySettingsPage> createState() =>
      _TimeDisplaySettingsPageState();
}

class _TimeDisplaySettingsPageState
    extends ConsumerState<TimeDisplaySettingsPage> {
  bool _saving = false;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = [
      l.zoneSystem,
      l.zoneTaipei,
      l.zoneTokyo,
      l.zoneShanghai,
      l.zoneHongKong,
      l.zoneSingapore,
      l.zoneSydney,
      l.zoneLondon,
      l.zoneParis,
      l.zoneNewYork,
      l.zoneLosAngeles,
      l.zoneUtc,
    ];
    final current = ref.watch(timeZoneProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.displaySettings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l.timeZoneSetting,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(l.timeZoneHelp),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(readableTimestamp(ref, l, DateTime.now())),
          ),
          if (current.hasError) Text(l.editorError),
          for (var i = 0; i < labels.length; i++)
            ListTile(
              title: Text(labels[i]),
              trailing: (current.value ?? 'system') == TimestampDisplay.zones[i]
                  ? const Icon(Icons.check)
                  : null,
              enabled: !_saving && !current.isLoading,
              onTap: () async {
                setState(() => _saving = true);
                try {
                  await ref
                      .read(timeZoneProvider.notifier)
                      .select(TimestampDisplay.zones[i]);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(l.editorError)));
                  }
                } finally {
                  if (mounted) setState(() => _saving = false);
                }
              },
            ),
        ],
      ),
    );
  }
}
