import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import '../models/forecast_model.dart';
import '../models/air_quality_model.dart';

import '../config/api_config.dart';

class WeatherService {
  final String apiKey;
  final http.Client client;
  
  WeatherService({required this.apiKey, http.Client? client})
      : client = client ?? http.Client();
  
  // Get current weather by city name
  Future<WeatherModel> getCurrentWeatherByCity(String cityName) async {
    final url = ApiConfig.buildUrl(
      ApiConfig.currentWeather,
      {'q': cityName, 'appid': apiKey},
    );

    final response = await client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return WeatherModel.fromJson(json.decode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('City not found');
    } else {
      throw Exception('Failed to load weather data');
    }
  }
  
  // Get current weather by coordinates
  Future<WeatherModel> getCurrentWeatherByCoordinates(
    double lat, 
    double lon,
  ) async {
    final url = ApiConfig.buildUrl(
      ApiConfig.currentWeather,
      {'lat': lat.toString(), 'lon': lon.toString(), 'appid': apiKey},
    );

    final response = await client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return WeatherModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load weather data');
    }
  }
  
  // Get 5-day forecast
  Future<List<ForecastModel>> getForecast(String cityName) async {
    final url = ApiConfig.buildUrl(
      ApiConfig.forecast,
      {'q': cityName, 'appid': apiKey},
    );

    final response = await client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> forecastList = data['list'];

      return forecastList.map((item) => ForecastModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load forecast data');
    }
  }
  
  // Get weather icon URL
  String getIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  // Get air quality
  Future<AirQualityModel> getAirQuality(double lat, double lon) async {
    final url =
        'https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$apiKey';

    final response = await client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return AirQualityModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load air quality data');
    }
  }
}
