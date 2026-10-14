class LocationAnchor {
  LocationAnchor(this.latitude, this.longitude, {this.radiusM}) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180 ||
        (radiusM != null && (!radiusM!.isFinite || radiusM! <= 0))) {
      throw ArgumentError('無效的地點座標或範圍');
    }
  }
  final double latitude, longitude;
  final double? radiusM;
  Map<String, Object?> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'radius_m': radiusM,
  };
  factory LocationAnchor.fromJson(Map<String, dynamic> json) => LocationAnchor(
    (json['latitude'] as num).toDouble(),
    (json['longitude'] as num).toDouble(),
    radiusM: (json['radius_m'] as num?)?.toDouble(),
  );
}
