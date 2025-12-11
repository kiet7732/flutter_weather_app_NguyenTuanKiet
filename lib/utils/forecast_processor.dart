import 'package:weather_app/models/forecast_model.dart';

class DailyForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final String icon;
  final String description;
  final double windSpeed;
  final int humidity;
  final double rainChance;

  DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.icon,
    required this.description,
    required this.windSpeed,
    required this.humidity,
    required this.rainChance,
  });
}

class ForecastProcessor {
  static List<DailyForecast> process(List<ForecastModel> hourlyForecasts) {
    if (hourlyForecasts.isEmpty) return [];

    Map<DateTime, List<ForecastModel>> groupedByDay = {};
    for (var forecast in hourlyForecasts) {
      final date = DateTime(forecast.dateTime.year, forecast.dateTime.month, forecast.dateTime.day);
      if (groupedByDay[date] == null) {
        groupedByDay[date] = [];
      }
      groupedByDay[date]!.add(forecast);
    }

    return groupedByDay.entries.map((entry) {
      final dayForecasts = entry.value;
      return DailyForecast(
        date: entry.key,
        maxTemp: dayForecasts.map((f) => f.tempMax).reduce((a, b) => a > b ? a : b),
        minTemp: dayForecasts.map((f) => f.tempMin).reduce((a, b) => a < b ? a : b),
        icon: dayForecasts.firstWhere((f) => f.dateTime.hour >= 12, orElse: () => dayForecasts.first).icon,
        description: dayForecasts.firstWhere((f) => f.dateTime.hour >= 12, orElse: () => dayForecasts.first).description,
        windSpeed: dayForecasts.map((f) => f.windSpeed).reduce((a, b) => a > b ? a : b), // Max wind speed for the day
        humidity: (dayForecasts.map((f) => f.humidity).reduce((a, b) => a + b) / dayForecasts.length).round(), // Average humidity
        rainChance: dayForecasts.map((f) => f.rainChance).reduce((a, b) => a > b ? a : b),
      );
    }).toList();
  }
}
