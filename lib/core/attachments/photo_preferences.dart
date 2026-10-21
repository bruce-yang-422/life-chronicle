import 'photo_compression.dart';

class PhotoPreferences {
  const PhotoPreferences({
    this.alwaysCompress = false,
    this.preset = PhotoPreset.standard,
    this.keepGps = true,
  });
  final bool alwaysCompress, keepGps;
  final PhotoPreset preset;
}
