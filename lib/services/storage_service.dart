import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';
import '../models/forecast_model.dart';


class StorageService {
  static const String _weatherKey = 'cached_weather';
  static const String _forecastKey = 'cached_forecast';
  static const String _lastCacheTimeKey = 'last_cache_time';
  
  Future<void> saveWeatherData(WeatherModel weather, List<ForecastModel> forecast) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weatherKey, json.encode(weather.toJson()));
    
    // Encode a list of ForecastModel objects
    final forecastJson = forecast.map((f) => f.toJson()).toList();
    await prefs.setString(_forecastKey, json.encode(forecastJson));

    await prefs.setInt(_lastCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  }
  
  Future<WeatherModel?> getCachedWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final weatherJson = prefs.getString(_weatherKey);
    
    if (weatherJson != null) {
      return WeatherModel.fromJson(json.decode(weatherJson));
    }
    return null;
  }

  Future<List<ForecastModel>?> getCachedForecast() async {
    final prefs = await SharedPreferences.getInstance();
    final forecastJson = prefs.getString(_forecastKey);

    if (forecastJson != null) {
      final List<dynamic> forecastList = json.decode(forecastJson);
      return forecastList.map((item) => ForecastModel.fromJson(item)).toList();
    }
    return null;
  }
  
  Future<DateTime?> getLastCacheTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastCacheTimeKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }
}
