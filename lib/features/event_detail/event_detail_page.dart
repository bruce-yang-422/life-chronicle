import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/time/time_format.dart';
import '../../core/time/time_value.dart';
import '../../data/providers.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/event_content_repository.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n_time_texts.dart';
import '../attachments/attachment_import.dart';
import '../attachments/cached_attachment_photo.dart';
import '../event_editor/new_event_page.dart';
import '../security/security_dialogs.dart';
import '../../core/location/location_anchor.dart';
import '../shared/markdown_content.dart';
import '../settings/time_display_settings.dart';
import '../../core/time/timestamp_display.dart';

Future<void> openEventDetail(
  BuildContext context,
  String id, {
  String? title,
}) async {
  final container = ProviderScope.containerOf(context);
  final event = await (await container.read(eventRepositoryProvider.future))
      .find(id);
  if (!context.mounted) return;
  if (event?.privacy == 'private' &&
      !container.read(securityProvider).canReadPrivate &&
      !await authorizePrivate(context)) {
    return;
  }
  if (!context.mounted) return;
  if (MediaQuery.sizeOf(context).width > 840) {
    ProviderScope.containerOf(context)
        .read(selectedEventProvider.notifier)
        .select(id, title);
    return Future.value();
  }
  return Navigator.of(context).push<void>(
    MediaQuery.disableAnimationsOf(context)
        ? PageRouteBuilder(
            pageBuilder: (context, animation, secondary) =>
                EventDetailPage(eventId: id, initialTitle: title),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          )
        : MaterialPageRoute(
            builder: (_) => EventDetailPage(eventId: id, initialTitle: title),
          ),
  );
}

class EventDetailPage extends ConsumerWidget {
  const EventDetailPage({
    super.key,
    required this.eventId,
    this.initialTitle,
    this.onClose,
    this.includeDeleted = false,
  });
  final String eventId;
  final String? initialTitle;
  final VoidCallback? onClose;
  final bool includeDeleted;
  Future<void> _reflect(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final l = AppLocalizations.of(context);
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.detailAddReflection),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 480,
            child: MarkdownEditor(
              controller: controller,
              label: l.editorNarrative,
              onChanged: (_) {},
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.timelineCancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text);
              }
            },
            child: Text(l.detailSaveReflection),
          ),
        ],
      ),
    );
    // 等候對話框退場後才釋放 controller。
    Future<void>.delayed(const Duration(seconds: 1), controller.dispose);
    if (text == null) return;
    try {
      await (await ref.read(eventContentRepositoryProvider.future))
          .appendReflection(eventId, text);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.editorError)));
      }
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    try {
      final repository = await ref.read(attachmentRepositoryProvider.future);
      if (!context.mounted) return;
      final plan = await pickImportPlan(context, repository, eventId: eventId);
      if (plan == null) return;
      if (!context.mounted) {
        await plan.release?.call();
        return;
      }
      final token = ImportCancellation();
      try {
        await withAttachmentProgress(
          context,
          token,
          (progress, files) => repository.importBatch(
            plan,
            eventId: eventId,
            cancellation: token,
            onProgress: progress,
            onFileProgress: files,
          ),
        );
      } finally {
        await plan.release?.call();
      }
    } catch (error) {
      if (context.mounted) showImportError(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final snapshot = ref.watch(
      includeDeleted
          ? deletedEventContentProvider(eventId)
          : eventContentProvider(eventId),
    );
    final protected =
        !ref.watch(securityProvider).canReadPrivate &&
        snapshot.value?.event.privacy != 'normal';
    return Scaffold(
      appBar: AppBar(
        leading: onClose == null
            ? null
            : IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(Icons.arrow_back),
                onPressed: onClose,
              ),
        actions: [
          IconButton(
            tooltip: l.recycleDelete,
            icon: const Icon(Icons.delete_outline),
            onPressed:
                protected ||
                    snapshot.value == null ||
                    snapshot.value?.event.deletedAt != null
                ? null
                : () async {
                    try {
                      final repository = await ref.read(
                        eventRepositoryProvider.future,
                      );
                      await repository.softDelete(eventId);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l.recycleDelete),
                          action: SnackBarAction(
                            label: l.recycleUndo,
                            onPressed: () async {
                              try {
                                await repository.restore(eventId);
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(l.editorError)),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      );
                      if (onClose != null) {
                        onClose!();
                      } else {
                        Navigator.pop(context);
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(l.editorError)));
                      }
                    }
                  },
          ),
          IconButton(
            tooltip: l.editorEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed:
                protected ||
                    snapshot.value == null ||
                    snapshot.value?.event.deletedAt != null
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => NewEventPage(eventId: eventId),
                    ),
                  ),
          ),
        ],
      ),
      body: protected
          ? Center(
              child: TextButton.icon(
                icon: const Icon(Icons.lock_outline),
                label: Text(l.securityPrivateUnlock),
                onPressed: () => authorizePrivate(context),
              ),
            )
          : snapshot.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text(l.timelineLoadError)),
              data: (data) => data == null
                  ? Center(child: Text(l.detailMissing))
                  : _body(context, ref, data),
            ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, EventContent data) {
    final l = AppLocalizations.of(context);
    final time = decodeTime(data.event.timePayload);
    final references = time is RelativeTime
        ? ref.watch(eventReferencesProvider)
        : null;
    final referenceEvent = time is RelativeTime
        ? references?.value
              ?.where((item) => item.id == time.eventId)
              .firstOrNull
        : null;
    final reference = referenceEvent == null
        ? L10nTimeTexts(l).deletedReferenceTitle(
            time,
            canReadPrivate: ref.watch(securityProvider).canReadPrivate,
          )
        : referenceEvent.privacy == 'private' &&
              !ref.watch(securityProvider).canReadPrivate
        ? l.securityPrivateEvent
        : referenceEvent.deletedAt == null
        ? referenceEvent.title
        : l.recycleDeletedTitle(referenceEvent.title);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HeroMode(
          enabled: !MediaQuery.disableAnimationsOf(context),
          child: Hero(
            tag: 'event-title-$eventId',
            child: Material(
              type: MaterialType.transparency,
              child: Text(
                data.event.title,
                softWrap: true,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (data.event.deletedAt != null)
          Text(l.recycleDeletedTitle(data.event.title)),
        Text(
          references?.isLoading == true
              ? l.pickerRelative
              : TimeFormat.full(
                  time,
                  L10nTimeTexts(l),
                  relatedEventTitle: reference,
                ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          '${l.detailRecorded}: ${readableTimestamp(ref, l, data.event.createdAt)}',
        ),
        if (data.event.privacy == 'private') Chip(label: Text(l.searchPrivate)),
        if (data.event.layer == 'remembrance')
          Chip(label: Text(l.detailRemembrance)),
        if (data.place?.name != null)
          Text(l.detailPlaceLabel(data.place!.name!)),
        if (data.place?.latitude != null) ...[
          Text(
            l.locationCoordinates(
              data.place!.latitude!.toStringAsFixed(6),
              data.place!.longitude!.toStringAsFixed(6),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.map_outlined),
            label: Text(l.locationOpenMap),
            onPressed: () async {
              try {
                await ref
                    .read(locationPlatformProvider)
                    .openMap(
                      LocationAnchor(
                        data.place!.latitude!,
                        data.place!.longitude!,
                        radiusM: data.place!.radiusM,
                      ),
                    );
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.locationUnavailable)),
                  );
                }
              }
            },
          ),
        ],
        if (data.people.isNotEmpty)
          Text(
            '${l.editorPeople}: ${data.people.map((p) => p.displayName).join(', ')}',
          ),
        if (data.tags.isNotEmpty)
          Wrap(
            spacing: 8,
            children: [
              for (final tag in data.tags) Chip(label: Text(tag.label)),
            ],
          ),
        const SizedBox(height: 16),
        for (final section in data.sections.where(
          (s) => s.contentMd.trim().isNotEmpty,
        )) ...[
          if (section.title != null && section.title!.trim().isNotEmpty)
            Text(
              section.title!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          MarkdownContent(section.contentMd),
          if (section.layer == 'remembrance') Text(l.detailRemembrance),
          const SizedBox(height: 16),
        ],
        Text(
          l.detailReflections,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        for (final reflection in data.reflections)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.detailReflectionYear(
                      '${TimestampDisplay.convert(reflection.recordedAt, ref.watch(timeZoneProvider).value ?? 'system').year}',
                    ),
                  ),
                  Text(
                    '${data.authors[reflection.authorId]?.isNotEmpty == true ? data.authors[reflection.authorId]! : l.detailAuthorSelf} · ${readableTimestamp(ref, l, reflection.recordedAt)}',
                  ),
                  MarkdownContent(reflection.contentMd),
                  if (reflection.layer == 'remembrance')
                    Text(l.detailRemembrance),
                ],
              ),
            ),
          ),
        if (data.event.deletedAt == null)
          TextButton.icon(
            onPressed: () => _reflect(context, ref),
            icon: const Icon(Icons.add),
            label: Text(l.detailAddReflection),
          ),
        const SizedBox(height: 16),
        Text(l.detailMedia, style: Theme.of(context).textTheme.titleLarge),
        ref
            .watch(eventAttachmentsProvider(eventId))
            .when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => Text(l.attachmentUnavailable),
              data: (attachments) => Column(
                children: [
                  for (final stored in attachments)
                    _AttachmentTile(
                      stored: stored,
                      readOnly: data.event.deletedAt != null,
                    ),
                ],
              ),
            ),
        if (data.event.deletedAt == null)
          OutlinedButton.icon(
            onPressed: () => _import(context, ref),
            icon: const Icon(Icons.attach_file),
            label: Text(l.editorAttachments),
          ),
        if (data.related.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l.editorRelated, style: Theme.of(context).textTheme.titleLarge),
          for (final event in data.related)
            ListTile(
              title: Text(event.title),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  openEventDetail(context, event.id, title: event.title),
            ),
        ],
      ],
    );
  }
}

class _AttachmentTile extends ConsumerWidget {
  const _AttachmentTile({required this.stored, this.readOnly = false});
  final StoredAttachment stored;
  final bool readOnly;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Card(
      child: Column(
        children: [
          if (stored.blob.mediaType.startsWith('image/'))
            CachedAttachmentPhoto(
              eventId: stored.attachment.eventId,
              path: stored.blob.path,
              height: 160,
            ),
          ListTile(
            title: Text(stored.attachment.originalFilename),
            subtitle: Text(
              '${formatBytes(stored.blob.byteSize)} · ${readableTimestamp(ref, l, stored.attachment.importedAt)}',
            ),
            trailing: IconButton(
              tooltip: l.detailOpen,
              icon: const Icon(Icons.open_in_new),
              onPressed: () async {
                try {
                  await (await ref.read(attachmentRepositoryProvider.future))
                      .openAttachment(stored);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.attachmentUnavailable)),
                    );
                  }
                }
              },
            ),
          ),
          if (stored.attachment.capturedAt != null)
            Text(readableTimestamp(ref, l, stored.attachment.capturedAt!)),
          if (stored.attachment.capturedLatitude != null)
            TextButton.icon(
              icon: const Icon(Icons.location_on_outlined),
              label: Text(l.locationOpenMap),
              onPressed: () async {
                try {
                  await ref
                      .read(locationPlatformProvider)
                      .openMap(
                        LocationAnchor(
                          stored.attachment.capturedLatitude!,
                          stored.attachment.capturedLongitude!,
                        ),
                      );
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.locationUnavailable)),
                    );
                  }
                }
              },
            ),
          if (stored.attachment.layer == 'remembrance')
            Text(l.detailRemembrance),
          if (!readOnly)
            TextButton(
              onPressed: () async {
                try {
                  await (await ref.read(attachmentRepositoryProvider.future))
                      .removeReference(stored.attachment.id);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(l.editorError)));
                  }
                }
              },
              child: Text(l.detailRemoveAttachment),
            ),
        ],
      ),
    );
  }
}
