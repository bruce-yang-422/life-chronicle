/// Photo policy uses integer pixels and decimal bytes; no platform dependencies.
enum PhotoPreset {
  high(4096),
  standard(3072),
  compact(2048);

  const PhotoPreset(this.longEdge);
  final int longEdge;
}

abstract final class PhotoCompressionPolicy {
  static const targetBytes = 3000000;
  static const qualities = [90, 85, 80, 75];

  static ({int width, int height}) dimensions(
    int width,
    int height,
    PhotoPreset preset,
  ) {
    if (width <= 0 || height <= 0) throw ArgumentError('Invalid dimensions');
    final edge = width > height ? width : height;
    if (edge <= preset.longEdge) return (width: width, height: height);
    int scale(int value) => ((value * preset.longEdge * 2 + edge) ~/ (edge * 2))
        .clamp(1, preset.longEdge);
    return (width: scale(width), height: scale(height));
  }
}
