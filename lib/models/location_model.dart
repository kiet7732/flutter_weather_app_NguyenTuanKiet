class LocationModel {
  final double latitude;
  final double longitude;
  final String? cityName;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.cityName,
  });
}