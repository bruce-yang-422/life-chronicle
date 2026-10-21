import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/attachments/storage_space.dart';
import '../../data/platform/storage_platform.dart';
import '../../l10n/app_localizations.dart';
import '../attachments/attachment_import.dart';

final storagePlatformProvider = Provider<StoragePlatform>(
  (ref) => DeviceStoragePlatform(),
);
final storageSnapshotProvider = StreamProvider.autoDispose<StorageSnapshot>((
  ref,
) async* {
  final platform = ref.watch(storagePlatformProvider);
  yield await platform.snapshot();
  yield* Stream.periodic(const Duration(seconds: 30))
      .asyncMap((_) => platform.snapshot());
}, retry: (_, _) => null);

/// 返回前景時刷新；暫時的查詢失敗不影響文字記錄。
class StorageStatus extends ConsumerStatefulWidget {
  const StorageStatus({super.key, this.banner = false});
  final bool banner;
  @override
  ConsumerState<StorageStatus> createState() => _StorageStatusState();
}

class _StorageStatusState extends ConsumerState<StorageStatus>
    with WidgetsBindingObserver {
  bool _dismissed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(storageSnapshotProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final snapshot = ref.watch(storageSnapshotProvider);
    return snapshot.when(
      loading: () =>
          widget.banner ? const SizedBox.shrink() : Text(l.storageLoading),
      error: (_, _) =>
          widget.banner ? const SizedBox.shrink() : Text(l.storageUnavailable),
      data: (data) {
        if (widget.banner) {
          if (_dismissed || data.freeBytes >= StorageSpace.lowBytes) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.info_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l.storageLow(formatBytes(data.freeBytes))),
                ),
                IconButton(
                  tooltip: l.storageDismiss,
                  onPressed: () => setState(() => _dismissed = true),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(l.storageApp),
              subtitle: Text(formatBytes(data.appBytes)),
            ),
            ListTile(
              title: Text(l.storageFree),
              subtitle: Text(formatBytes(data.freeBytes)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l.storageEstimate),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => ref.invalidate(storageSnapshotProvider),
                icon: const Icon(Icons.refresh),
                label: Text(l.storageRefresh),
              ),
            ),
          ],
        );
      },
    );
  }
}
