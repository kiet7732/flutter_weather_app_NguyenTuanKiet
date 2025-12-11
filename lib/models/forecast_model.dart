class ForecastModel {
  final DateTime dateTime;
  final double temperature;
  final String description;
  final String icon;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final double windSpeed;
  final String mainCondition;
  final int pressure;
  final double rainChance;
  
  ForecastModel({
    required this.dateTime,
    required this.temperature,
    required this.description,
    required this.icon,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.windSpeed,
    required this.mainCondition,
    required this.pressure,
    required this.rainChance,
  });
  
  factory ForecastModel.fromJson(Map<String, dynamic> json) {
    return ForecastModel(
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      temperature: json['main']['temp'].toDouble(),
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
      tempMin: json['main']['temp_min'].toDouble(),
      tempMax: json['main']['temp_max'].toDouble(),
      humidity: json['main']['humidity'],
      windSpeed: json['wind']['speed'].toDouble(),
      mainCondition: json['weather'][0]['main'],
      pressure: json['main']['pressure'],
      rainChance: (json['pop'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dt': dateTime.millisecondsSinceEpoch ~/ 1000,
      'main': {
        'temp': temperature,
        'temp_min': tempMin,
        'temp_max': tempMax,
        'humidity': humidity,
        'pressure': pressure,
      },
      'weather': [
        {'description': description, 'icon': icon, 'main': mainCondition}
      ],
      'wind': {'speed': windSpeed},
      'pop': rainChance,
    };
  }
}
