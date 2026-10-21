import 'dart:io';

import 'package:path/path.dart' as p;

import '../../data/repositories/photo_preferences_store.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/attachments/attachment_quota.dart';
import '../../core/attachments/storage_space.dart';
import '../../core/attachments/attachment_file_progress.dart';
import '../../core/attachments/photo_compression.dart';
import '../../data/platform/photo_platform.dart';
import '../../data/repositories/photo_import_session.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../l10n/app_localizations.dart';

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
  if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MiB';
  return '${(bytes / 1073741824).toStringAsFixed(2)} GiB';
}

/// 準備及匯入中皆有可見的取消按鈕。
Future<T> withImportProgress<T>(
  BuildContext context,
  ImportCancellation token,
  Future<T> Function(void Function(int, int) progress) action, {
  String? title,
}) async {
  return _withImportProgress(
    context,
    token,
    (bytes, files) => action(bytes),
    title: title,
  );
}

Future<T> withAttachmentProgress<T>(
  BuildContext context,
  ImportCancellation token,
  Future<T> Function(
    void Function(int, int),
    void Function(AttachmentFileProgress),
  )
  action,
) => _withImportProgress(context, token, action);

Future<T> _withImportProgress<T>(
  BuildContext context,
  ImportCancellation token,
  Future<T> Function(
    void Function(int, int),
    void Function(AttachmentFileProgress),
  )
  action, {
  String? title,
}) async {
  final files = ValueNotifier<AttachmentFileProgress?>(null);
  final progress = ValueNotifier<(int, int)>((0, 0));
  final l = AppLocalizations.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(title ?? l.attachmentImport),
        content: SingleChildScrollView(
          child: ValueListenableBuilder(
            valueListenable: progress,
            builder: (_, value, child) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: value.$2 > 0
                      ? (value.$1 / value.$2).clamp(0.0, 1.0)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(l.attachmentProgress(value.$1, value.$2)),
                ValueListenableBuilder(
                  valueListenable: files,
                  builder: (_, file, child) => file == null
                      ? const SizedBox.shrink()
                      : Text(
                          l.attachmentFileProgress(
                            file.name,
                            file.completed,
                            file.total,
                            file.remaining,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => token.cancelled = true,
            child: Text(l.attachmentCancel),
          ),
        ],
      ),
    ),
  );
  try {
    return await action(
      (done, total) => progress.value = (done, total),
      (value) => files.value = value,
    );
  } finally {
    navigator.pop();
    Future<void>.delayed(const Duration(seconds: 1), () {
      progress.dispose();
      files.dispose();
    });
  }
}

Future<AttachmentImportPlan?> pickImportPlan(
  BuildContext context,
  AttachmentRepository repository, {
  bool forDraft = false,
  String? eventId,
  List<AttachmentSource> pendingSources = const [],
}) async {
  final selected = await FilePicker.pickFiles();
  if (selected.isEmpty || !context.mounted) return null;
  final sources = [
    for (final file in selected) AttachmentSource(file.path ?? '', file.name),
  ];
  final token = ImportCancellation();
  final prepared = await withAttachmentProgress(context, token, (
    progress,
    files,
  ) async {
    final used = eventId == null ? 0 : await repository.usedBytes(eventId);
    final pendingPlan = await repository.prepare(
      pendingSources,
      cancellation: token,
      onProgress: progress,
      onFileProgress: files,
    );
    if (pendingPlan.rejected.isNotEmpty) {
      throw ImportMediaException(pendingPlan.rejected.first.reason);
    }
    final pending = await repository.pendingBytes(eventId, pendingPlan);
    token.check();
    final plan = await repository.prepare(
      sources,
      cancellation: token,
      onProgress: progress,
      onFileProgress: files,
    );
    return (plan: plan, used: used, pending: pending);
  });
  if (!context.mounted) return null;
  final preferences = await FilePhotoPreferencesStore(
    File(p.join(repository.directory.parent.path, 'photo_preferences.json')),
  ).load();
  if (!context.mounted) return null;
  final photos = PhotoImportSession(
    repository,
    DevicePhotoPlatform(),
    preferences: preferences,
  );
  AttachmentImportPlan? result;
  try {
    result = await showDialog<AttachmentImportPlan>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AttachmentImportDialog(
        plan: prepared.plan,
        usedBytes: prepared.used,
        pendingBytes: prepared.pending,
        forDraft: forDraft,
        photos: photos,
      ),
    );
    if (result == null) return null;
    return AttachmentImportPlan(
      result.files,
      result.originalBytes,
      result.addedBytes,
      result.freeBytes,
      result.duplicates,
      rejected: result.rejected,
      release: photos.dispose,
    );
  } finally {
    if (result == null) await photos.dispose();
  }
}

String _rejectionText(AppLocalizations l, AttachmentRejectionReason reason) =>
    switch (reason) {
      AttachmentRejectionReason.video => l.attachmentVideoUnsupported,
      AttachmentRejectionReason.unverified => l.attachmentTypeUnverified,
    };

class AttachmentImportDialog extends StatefulWidget {
  const AttachmentImportDialog({
    super.key,
    required this.plan,
    this.usedBytes = 0,
    this.pendingBytes = 0,
    this.forDraft = false,
    this.photos,
  });
  final AttachmentImportPlan plan;
  final int usedBytes;
  final int pendingBytes;
  final bool forDraft;
  final PhotoImportSession? photos;

  @override
  State<AttachmentImportDialog> createState() => _AttachmentImportDialogState();
}

class _AttachmentImportDialogState extends State<AttachmentImportDialog> {
  late final Set<int> _selected = {
    for (var i = 0; i < widget.plan.files.length; i++)
      if (widget.plan.files[i].size <= AttachmentQuota.limitBytes) i,
  };
  final _info = <int, PhotoInfo>{};
  final _thumbnails = <int, File>{};
  int _doneFiles = 0, _totalFiles = 0;
  String _processingName = '';
  bool _previewFailed = false;
  void _fileProgress(String name, int done, int total) {
    if (mounted) {
      setState(() {
        _processingName = name;
        _doneFiles = done;
        _totalFiles = total;
      });
    }
  }

  Future<void> _thumbnail(int i) async {
    try {
      _thumbnails[i] = await widget.photos!.preview(_current(i), 80, _token);
    } catch (_) {
      _token.check();
      _thumbnails.remove(i);
      _previewFailed = true;
    }
  }

  final _converted = <int, ({PreparedAttachment file, PhotoOutput output})>{};
  final _presets = <int, PhotoPreset>{};
  final _automatic = <int>{};
  final _failedFiles = <int>{};
  final _token = ImportCancellation();
  bool _busy = false, _cancelRequested = false, _failed = false;
  int? _freeBytes;

  PreparedAttachment _current(int i) =>
      _converted[i]?.file ?? widget.plan.files[i];

  @override
  void initState() {
    super.initState();
    if (widget.photos != null) {
      _busy = true;
      _inspect();
    }
  }

  @override
  void dispose() {
    _token.cancelled = true;
    super.dispose();
  }

  Future<void> _inspect() async {
    try {
      var allocated = widget.usedBytes + widget.pendingBytes;
      for (var i = 0; i < widget.plan.files.length; i++) {
        _token.check();
        _fileProgress(
          widget.plan.files[i].source.name,
          i,
          widget.plan.files.length,
        );
        final info = await widget.photos!.inspect(widget.plan.files[i]);
        if (!mounted) return;
        if (info != null) {
          _info[i] = info;
          if (_selected.contains(i) &&
              (widget.photos!.preferences.alwaysCompress ||
                  allocated + widget.plan.files[i].size >
                      AttachmentQuota.limitBytes)) {
            await _convert(i, widget.photos!.preferences.preset);
            if (!widget.photos!.preferences.alwaysCompress) _automatic.add(i);
          }
        }
        if (info != null && !_converted.containsKey(i)) await _thumbnail(i);
        if (_selected.contains(i)) allocated += _current(i).size;
        _fileProgress(
          widget.plan.files[i].source.name,
          i + 1,
          widget.plan.files.length,
        );
      }
    } catch (_) {
      _failed = !_cancelRequested;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (_cancelRequested) Navigator.pop(context);
      }
    }
  }

  Future<void> _convert(int i, PhotoPreset preset) async {
    try {
      _converted[i] = await widget.photos!.compress(
        widget.plan.files[i],
        preset,
        _token,
      );
      _failedFiles.remove(i);
    } catch (_) {
      _failedFiles.add(i);
      rethrow;
    }
    _presets[i] = preset;
    await _thumbnail(i);
    _freeBytes = await widget.photos!.repository.platform.availableBytes(
      widget.photos!.repository.directory.path,
    );
  }

  Future<void> _compress(Iterable<int> indexes, PhotoPreset preset) async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final files = indexes.toList();
      for (var j = 0; j < files.length; j++) {
        final i = files[j];
        _fileProgress(widget.plan.files[i].source.name, j, files.length);
        await _convert(i, preset);
        _fileProgress(widget.plan.files[i].source.name, j + 1, files.length);
      }
    } catch (_) {
      _failed = !_cancelRequested;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (_cancelRequested) Navigator.pop(context);
      }
    }
  }

  Future<void> _useOriginal(int index) async {
    setState(() {
      _busy = true;
      _failedFiles.remove(index);
      _converted.remove(index);
      _thumbnails.remove(index);
      _presets.remove(index);
      _automatic.remove(index);
    });
    try {
      _fileProgress(widget.plan.files[index].source.name, 0, 1);
      await _thumbnail(index);
      _fileProgress(widget.plan.files[index].source.name, 1, 1);
    } catch (_) {
      if (mounted && !_cancelRequested) setState(() => _previewFailed = true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (_cancelRequested) Navigator.pop(context);
      }
    }
  }

  void _cancel() {
    if (_busy) {
      setState(() {
        _cancelRequested = true;
        _token.cancelled = true;
      });
    } else {
      Navigator.pop(context);
    }
  }

  String _presetName(AppLocalizations l, PhotoPreset preset) =>
      switch (preset) {
        PhotoPreset.high => l.photoHigh,
        PhotoPreset.standard => l.photoStandard,
        PhotoPreset.compact => l.photoCompact,
      };

  Future<void> _compare(int index) async {
    final photos = widget.photos;
    if (photos == null) return;
    setState(() => _busy = true);
    late final File originalPreview, currentPreview;
    try {
      _fileProgress(widget.plan.files[index].source.name, 0, 2);
      originalPreview = await photos.preview(
        widget.plan.files[index],
        1600,
        _token,
      );
      _fileProgress(widget.plan.files[index].source.name, 1, 2);
      currentPreview = await photos.preview(_current(index), 1600, _token);
      _fileProgress(widget.plan.files[index].source.name, 2, 2);
    } catch (_) {
      if (mounted && !_cancelRequested) setState(() => _previewFailed = true);
      return;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (_cancelRequested) Navigator.pop(context);
      }
    }
    if (!mounted || _cancelRequested) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        final l = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l.photoCompare),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.photoOriginal),
                  Image(
                    image: ResizeImage(
                      FileImage(originalPreview),
                      width: 1600,
                      height: 1600,
                      policy: ResizeImagePolicy.fit,
                    ),
                    errorBuilder: (_, error, stack) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
                  Text(l.photoCompressed),
                  Image(
                    image: ResizeImage(
                      FileImage(currentPreview),
                      width: 1600,
                      height: 1600,
                      policy: ResizeImagePolicy.fit,
                    ),
                    errorBuilder: (_, error, stack) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.attachmentCancel),
            ),
          ],
        );
      },
    );
  }

  String _mb(int bytes) => (bytes / 1000000).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final selection = widget.plan.select([
      for (var i = 0; i < widget.plan.files.length; i++)
        if (_selected.contains(i)) _current(i),
    ]);
    final plan = AttachmentImportPlan(
      selection.files,
      selection.originalBytes,
      selection.addedBytes,
      _freeBytes ?? selection.freeBytes,
      selection.duplicates,
      rejected: selection.rejected,
    );
    final total = widget.usedBytes + widget.pendingBytes + plan.originalBytes;
    final remaining = AttachmentQuota.limitBytes - total;
    final required =
        plan.addedBytes + (widget.forDraft ? plan.originalBytes : 0);
    final fitsSpace = StorageSpace.canAdd(plan.freeBytes, required);
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(l.attachmentPlan),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.attachmentQuotaPreview(
                    _mb(widget.usedBytes),
                    _mb(widget.pendingBytes + plan.originalBytes),
                    _mb(remaining < 0 ? 0 : remaining),
                  ),
                ),
                if (remaining < 0)
                  Text(
                    l.attachmentQuotaExceeded(
                      (-remaining / 1000000).toStringAsFixed(6),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (!fitsSpace) Text(l.attachmentSpaceReserve),
                Text(
                  l.attachmentPlanBody(
                    plan.files.length,
                    formatBytes(plan.originalBytes),
                    formatBytes(required),
                    formatBytes(plan.freeBytes),
                    plan.duplicates,
                  ),
                ),
                if (widget.photos?.preferences.keepGps == false)
                  Text(l.photoGpsRemovalNotice),
                if (_busy) ...[
                  LinearProgressIndicator(
                    value: _totalFiles > 0 ? _doneFiles / _totalFiles : null,
                  ),
                  if (_totalFiles > 0)
                    Text(
                      l.attachmentFileProgress(
                        _processingName,
                        _doneFiles,
                        _totalFiles,
                        _totalFiles - _doneFiles,
                      ),
                    ),
                ],
                if (_previewFailed) Text(l.photoPreviewUnavailable),
                if (_failed) Text(l.photoCompressionError),
                if (_info.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _compress(
                                _selected.where(_info.containsKey).toList(),
                                PhotoPreset.standard,
                              ),
                        child: Text(l.photoCompressAll),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _compress(
                                _selected.where(_info.containsKey).toList(),
                                PhotoPreset.compact,
                              ),
                        child: Text(l.photoUseCompact),
                      ),
                    ],
                  ),
                const Divider(),
                for (var i = 0; i < widget.plan.files.length; i++)
                  _file(context, i),
                for (final rejected in widget.plan.rejected)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l.attachmentExcludedFile(
                        rejected.source.name,
                        _rejectionText(l, rejected.reason),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _cancelRequested ? null : _cancel,
            child: Text(l.timelineCancel),
          ),
          FilledButton(
            onPressed:
                _busy ||
                    _failedFiles.any(_selected.contains) ||
                    plan.files.isEmpty ||
                    remaining < 0 ||
                    !fitsSpace
                ? null
                : () => Navigator.pop(context, plan),
            child: Text(l.attachmentImport),
          ),
        ],
      ),
    );
  }

  Widget _file(BuildContext context, int index) {
    final l = AppLocalizations.of(context);
    final file = _current(index);
    final overLimit = file.size > AttachmentQuota.limitBytes;
    final type = file.metadata.mediaType;
    const fallback = Icon(Icons.insert_drive_file_outlined);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _selected.contains(index),
          onChanged: overLimit || _busy
              ? null
              : (value) => setState(() {
                  if (value == true) {
                    _selected.add(index);
                  } else {
                    _selected.remove(index);
                  }
                }),
          title: Text(file.source.name),
          subtitle: Text(
            l.attachmentFileDescription(type, file.size, _mb(file.size)),
          ),
          secondary: SizedBox(
            width: 40,
            height: 40,
            child: _thumbnails[index] != null
                ? Image(
                    image: FileImage(_thumbnails[index]!),
                    fit: BoxFit.contain,
                    errorBuilder: (_, error, stack) => fallback,
                  )
                : fallback,
          ),
        ),
        if (_info[index] case final info?) ...[
          Text(l.photoDimensions(info.width, info.height)),
          DropdownButton<String>(
            isExpanded: true,
            value: _presets[index]?.name ?? 'original',
            items: [
              DropdownMenuItem(value: 'original', child: Text(l.photoOriginal)),
              for (final preset in PhotoPreset.values)
                DropdownMenuItem(
                  value: preset.name,
                  child: Text(
                    _presetName(l, preset),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _busy || overLimit
                ? null
                : (value) {
                    if (value == 'original') {
                      _useOriginal(index);
                    } else if (value != null) {
                      _compress([index], PhotoPreset.values.byName(value));
                    }
                  },
          ),
          if (_automatic.contains(index)) Text(l.photoAutomaticCompression),
          if (_converted[index] case final result?) ...[
            Text(
              result.output.keptOriginal
                  ? l.photoOriginalSmaller
                  : l.photoCompressionResult(
                      result.output.width,
                      result.output.height,
                      _mb(result.file.size),
                      result.output.quality?.toString() ?? l.photoLossless,
                    ),
            ),
            TextButton(
              onPressed: _busy ? null : () => _compare(index),
              child: Text(l.photoCompare),
            ),
          ],
        ],
        if (overLimit) Text(l.attachmentSingleOverLimit),
        if (file.staticImageOnly)
          Text(l.attachmentStaticImageOnly(file.source.name)),
        const Divider(),
      ],
    );
  }
}

void showImportError(BuildContext context, Object error) {
  if (error is ImportCancelled) return;
  final l = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        error is ImportMediaException
            ? l.attachmentRejectedImport(_rejectionText(l, error.reason))
            : error is AttachmentQuotaExceeded
            ? l.attachmentQuotaExceeded(
                (error.excessBytes / 1000000).toStringAsFixed(6),
              )
            : error is ImportSpaceException
            ? l.attachmentNoSpace
            : l.attachmentError,
      ),
    ),
  );
}
