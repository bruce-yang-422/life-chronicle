import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/attachments/attachment_quota.dart';
import '../../data/providers.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../l10n/app_localizations.dart';

/// 不寫入額外計數欄位，直接監聽 Repository 的引用容量。
class EventAttachmentQuota extends ConsumerStatefulWidget {
  const EventAttachmentQuota({
    super.key,
    this.eventId,
    this.pending = const [],
  });
  final String? eventId;
  final List<AttachmentSource> pending;

  @override
  ConsumerState<EventAttachmentQuota> createState() =>
      _EventAttachmentQuotaState();
}

class _EventAttachmentQuotaState extends ConsumerState<EventAttachmentQuota> {
  AttachmentRepository? _repository;
  String? _signature;
  Stream<AttachmentUsage>? _stream;

  @override
  Widget build(BuildContext context) {
    // 空白新事件不需等待資料庫，避免大字級表單載入後位移。
    if (widget.eventId == null && widget.pending.isEmpty) {
      return const AttachmentQuotaPanel(usage: AttachmentUsage());
    }
    final l = AppLocalizations.of(context);
    return ref
        .watch(attachmentRepositoryProvider)
        .when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(l.attachmentUsageUnavailable),
          data: (repository) {
            final signature = jsonEncode([
              widget.eventId,
              for (final source in widget.pending)
                [source.path, source.name, source.referenceId],
            ]);
            if (_repository != repository || _signature != signature) {
              _repository = repository;
              _signature = signature;
              _stream = repository.watchUsage(
                widget.eventId,
                pending: List.of(widget.pending),
              );
            }
            return StreamBuilder<AttachmentUsage>(
              // 切換事件／權限／草稿時，不沿用舊事件的快照。
              key: ValueKey((repository, signature)),
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(l.attachmentUsageUnavailable);
                }
                if (!snapshot.hasData) return const LinearProgressIndicator();
                return AttachmentQuotaPanel(usage: snapshot.requireData);
              },
            );
          },
        );
  }
}

class AttachmentQuotaPanel extends StatelessWidget {
  const AttachmentQuotaPanel({super.key, required this.usage});
  final AttachmentUsage usage;

  String _mb(int bytes) => (bytes / 1000000).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final warning = usage.isOverLimit || usage.isLow;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(l.attachmentUsage(_mb(usage.usedBytes), usage.count)),
          LinearProgressIndicator(
            value: (usage.totalBytes / AttachmentQuota.limitBytes).clamp(0, 1),
            color: usage.isOverLimit ? colors.error : null,
          ),
          if (usage.pendingCount > 0)
            Text(
              l.attachmentPendingUsage(
                _mb(usage.pendingBytes),
                usage.pendingCount,
              ),
            ),
          Text(
            l.attachmentRemaining(
              _mb(usage.remainingBytes.clamp(0, AttachmentQuota.limitBytes)),
            ),
          ),
          if (warning)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: colors.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    usage.isOverLimit
                        ? l.attachmentUsageOverLimit(
                            // 超額 1 byte 也要可見，不能顯示成零。
                            ((-usage.remainingBytes / 1000000 * 10).ceil() / 10)
                                .toStringAsFixed(1),
                          )
                        : l.attachmentQuotaLow,
                    style: TextStyle(color: colors.error),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
