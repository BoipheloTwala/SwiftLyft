/// Simple latitude/longitude coordinate class to replace google_maps_flutter LatLng
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatLng &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() => 'LatLng($latitude, $longitude)';

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory LatLng.fromJson(Map<String, dynamic> json) => LatLng(
    json['latitude'] as double,
    json['longitude'] as double,
  );
}

