class AirQualityModel {
  final int aqi;
  final double co;
  final double no2;
  final double o3;
  final double pm2_5;

  AirQualityModel({
    required this.aqi,
    required this.co,
    required this.no2,
    required this.o3,
    required this.pm2_5,
  });

  factory AirQualityModel.fromJson(Map<String, dynamic> json) {
    final data = json['list'][0];
    return AirQualityModel(
      aqi: data['main']['aqi'],
      co: (data['components']['co'] as num).toDouble(),
      no2: (data['components']['no2'] as num).toDouble(),
      o3: (data['components']['o3'] as num).toDouble(),
      pm2_5: (data['components']['pm2_5'] as num).toDouble(),
    );
  }
}