class HourlyWeatherModel {
  final DateTime time;
  final double temperature;
  final String iconCode;

  HourlyWeatherModel({
    required this.time,
    required this.temperature,
    required this.iconCode,
  });

  factory HourlyWeatherModel.fromJson(Map<String, dynamic> json) {
    return HourlyWeatherModel(
      time: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temperature: (json['main']['temp'] as num).toDouble(),
      iconCode: json['weather'][0]['icon'],
    );
  }
}