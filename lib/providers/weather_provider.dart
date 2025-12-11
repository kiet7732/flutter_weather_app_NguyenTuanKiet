import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';
import 'package:http/http.dart';
import 'dart:async';
import '../models/forecast_model.dart';
import '../models/air_quality_model.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';

enum WeatherState { initial, loading, loaded, error }

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService;
  final LocationService _locationService;
  final StorageService _storageService;
  
  // Dùng Map để lưu state cho từng location (key là "CURRENT_LOCATION" hoặc tên thành phố).
  final Map<String, WeatherModel> _weatherData = {};
  final Map<String, List<ForecastModel>> _forecastData = {};
  final Map<String, AirQualityModel> _airQualityData = {};
  final Map<String, WeatherState> _states = {};
  final Map<String, String> _errorMessages = {};
  
  List<String> _searchHistory = [];
  List<String> _favoriteCities = [];
  bool _isCelsius = true;
  bool _is24HourFormat = true;
  String _windSpeedUnit = 'm/s';
  bool _isOffline = false;
  DateTime? _lastUpdated;
  StreamSubscription<dynamic>? _locationSubscription;
  
  WeatherProvider(
    this._weatherService,
    this._locationService,
    this._storageService,
  ) {
    _loadUserData();
    listenToLocationChanges();
  }
  
  // Getters để các widget truy cập data.
  WeatherModel? get currentWeather => _weatherData['CURRENT_LOCATION']; // Giữ để tương thích với code cũ nếu cần.
  List<ForecastModel> get forecast => _forecastData['CURRENT_LOCATION'] ?? [];
  AirQualityModel? get airQuality => _airQualityData['CURRENT_LOCATION'];
  WeatherState get state => _states['CURRENT_LOCATION'] ?? WeatherState.initial;
  String get errorMessage => _errorMessages['CURRENT_LOCATION'] ?? '';
  List<String> get searchHistory => _searchHistory;
  List<String> get favoriteCities => _favoriteCities;
  bool get isCelsius => _isCelsius;
  bool get is24HourFormat => _is24HourFormat;
  String get windSpeedUnit => _windSpeedUnit;
  bool get isOffline => _isOffline;
  DateTime? get lastUpdated => _lastUpdated;
  
  // Lấy thời tiết theo tên thành phố.
  Future<void> fetchWeatherByCity(String cityName) async {
    await fetchDataForLocation(cityName);
  }

  // Lấy thời tiết theo vị trí hiện tại.
  Future<void> fetchWeatherByLocation() async {
    await fetchDataForLocation('CURRENT_LOCATION');
  }

  // Helper để cập nhật state cho một location key cụ thể.
  void _setState(String key, WeatherState state, [String? error]) {
    _states[key] = state;
    if (error != null) _errorMessages[key] = error;
    notifyListeners();
  }
  
  // --- Logic xử lý đa địa điểm ---

  // Các hàm getter cho từng location key.
  WeatherState getStateForLocation(String key) => _states[key] ?? WeatherState.initial;
  WeatherModel? getWeatherForLocation(String key) => _weatherData[key];
  List<ForecastModel>? getForecastForLocation(String key) => _forecastData[key];
  AirQualityModel? getAirQualityForLocation(String key) => _airQualityData[key];
  String? getErrorForLocation(String key) => _errorMessages[key];

  Future<void> fetchDataForLocation(String key, {bool forceRefresh = false}) async {
    // Nếu data đã load và không bị ép refresh thì bỏ qua.
    if (!forceRefresh && _states[key] == WeatherState.loaded) return;

    _setState(key, WeatherState.loading);
    debugPrint("[$key] Start fetching data. ForceRefresh: $forceRefresh");
    // Reset offline status when trying to fetch new data
    if (key == 'CURRENT_LOCATION') _isOffline = false;
    
    try {
      WeatherModel weather;
      List<ForecastModel> forecast;
      AirQualityModel airQuality;

      if (key == 'CURRENT_LOCATION') {
        debugPrint("[$key] Handling permissions...");
        // Bước 1: Xử lý quyền truy cập vị trí trước.
        // Nếu không có quyền, nó sẽ ném Exception và đi vào khối catch.
        final hasPermission = await _locationService.handlePermission();
        if (!hasPermission) return; // Dòng này thực ra không cần thiết vì handlePermission đã throw Exception.

        // Bước 2: Chỉ lấy vị trí sau khi đã chắc chắn có quyền.
        final location = await _locationService.getCurrentLocation();
        debugPrint("[$key] Got location: ${location.latitude}, ${location.longitude}");
        weather = await _weatherService.getCurrentWeatherByCoordinates(
          location.latitude,
          location.longitude,
        );
        forecast = await _weatherService.getForecast(location.cityName ?? 'Unknown');
        airQuality = await _weatherService.getAirQuality(location.latitude, location.longitude);
        debugPrint("[$key] API fetch successful.");
      } else {
        debugPrint("[$key] Fetching by city name...");
        weather = await _weatherService.getCurrentWeatherByCity(key);
        forecast = await _weatherService.getForecast(key);
        airQuality = await _weatherService.getAirQuality(weather.latitude, weather.longitude);
      }
      
      _weatherData[key] = weather;
      _forecastData[key] = forecast;
      _airQualityData[key] = airQuality;
      _lastUpdated = DateTime.now();
      
      // Hiện tại chỉ cache data của vị trí hiện tại.
      if (key == 'CURRENT_LOCATION') {
        await _storageService.saveWeatherData(weather, forecast);
      }
      
      _isOffline = false;
      _setState(key, WeatherState.loaded);
    } catch (e) {
      // Nếu lỗi (mất mạng, API die...), thử fallback về dữ liệu cache.
      debugPrint("[$key] Error fetching data: $e");
      if (key == 'CURRENT_LOCATION') {
        final cachedWeather = await _storageService.getCachedWeather();
        final cachedForecast = await _storageService.getCachedForecast();
        if (cachedWeather != null && cachedForecast != null) {
          _weatherData[key] = cachedWeather;
          _forecastData[key] = cachedForecast;
          // Dữ liệu chất lượng không khí (AQI) không cache, nên sẽ là null.
          _airQualityData.remove(key);
          _isOffline = true;
          _lastUpdated = await _storageService.getLastCacheTime();
          debugPrint("[$key] Fallback to cache. Offline mode: $_isOffline");
          _setState(key, WeatherState.loaded);
          return;
        }
      }
      // Phân tích lỗi để đưa ra thông báo thân thiện hơn.
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      if (e is ClientException || (e.toString().contains('SocketException'))) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('Location permissions are denied')) {
        errorMessage = 'Location permission is required to get weather data.';
      }
      _setState(key, WeatherState.error, errorMessage);
    }
  }

  // Load data từ cache (hỗ trợ code cũ).
  Future<void> loadCachedWeather() async {
    final cachedWeather = await _storageService.getCachedWeather();    
    if (cachedWeather != null) { 
      _weatherData['CURRENT_LOCATION'] = cachedWeather;
      _states['CURRENT_LOCATION'] = WeatherState.loaded;
      notifyListeners();
    }
  }
  
  // Refresh lại toàn bộ dữ liệu thời tiết.
  Future<void> refreshWeather() async {
    // Refresh current location
    await fetchDataForLocation('CURRENT_LOCATION', forceRefresh: true);
    // Refresh favorites
    for (var city in _favoriteCities) {
      await fetchDataForLocation(city, forceRefresh: true);
    }
  }

  // --- Logic chuyển đổi đơn vị ---

  // Chuyển đổi giữa độ C và độ F.
  void toggleTemperatureUnit() {
    _isCelsius = !_isCelsius;
    notifyListeners();
  }

  // Chuyển đổi định dạng thời gian 12h/24h.
  void toggleTimeFormat() {
    _is24HourFormat = !_is24HourFormat;
    notifyListeners();
  }

  // Set đơn vị tốc độ gió.
  void setWindSpeedUnit(String unit) {
    _windSpeedUnit = unit;
    notifyListeners();
  }

  // Lấy nhiệt độ hiển thị (đã qua chuyển đổi nếu cần).
  double getDisplayTemperature(double tempInCelsius) {
    return _isCelsius ? tempInCelsius : (tempInCelsius * 9 / 5) + 32;
  }

  // Lấy chuỗi đơn vị nhiệt độ (°C hoặc °F).
  String getTempUnit() {
    return _isCelsius ? "°C" : "°F";
  }

  // Lấy tốc độ gió hiển thị (đã qua chuyển đổi và có kèm đơn vị).
  String getDisplayWindSpeed(double speedInMps) {
    if (_windSpeedUnit == 'km/h') {
      return '${(speedInMps * 3.6).toStringAsFixed(1)} km/h';
    } else if (_windSpeedUnit == 'mph') {
      return '${(speedInMps * 2.23694).toStringAsFixed(1)} mph';
    } else {
      return '${speedInMps.toStringAsFixed(1)} m/s';
    }
  }

  // Lấy thời gian đã format (12h hoặc 24h).
  String getFormattedTime(DateTime time) {
    if (_is24HourFormat) {
      return DateFormat('HH:mm').format(time);
    } else {
      return DateFormat('hh:mm a').format(time);
    }
  }

  // --- Logic xử lý Lịch sử tìm kiếm & Thành phố yêu thích ---

  // Tải data user (lịch sử, yêu thích) từ SharedPreferences.
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory = prefs.getStringList('search_history') ?? [];
    _favoriteCities = prefs.getStringList('favorite_cities') ?? [];
    notifyListeners();
  }

  // Thêm một thành phố vào lịch sử tìm kiếm.
  Future<void> addToHistory(String cityName) async {
    // Xóa đi nếu đã có để đưa lên đầu list.
    _searchHistory.removeWhere((item) => item.toLowerCase() == cityName.toLowerCase());
    _searchHistory.insert(0, cityName);

    // Giới hạn chỉ lưu 10 mục gần nhất.
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.sublist(0, 10);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
    notifyListeners();
  }

  // Xóa một thành phố khỏi lịch sử.
  Future<void> removeFromHistory(String cityName) async {
    _searchHistory.remove(cityName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', _searchHistory);
    notifyListeners();
  }

  // Xóa sạch lịch sử tìm kiếm.
  Future<void> clearHistory() async {
    _searchHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    notifyListeners();
  }

  // Thêm/xóa một thành phố khỏi danh sách yêu thích.
  Future<bool> toggleFavorite(String cityName) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (_favoriteCities.contains(cityName)) {
      _favoriteCities.remove(cityName);
      // Xóa luôn data của thành phố này để tiết kiệm bộ nhớ.
      _weatherData.remove(cityName);
      _forecastData.remove(cityName);
      _airQualityData.remove(cityName);
      _states.remove(cityName);
      
      await prefs.setStringList('favorite_cities', _favoriteCities);
      notifyListeners();
      return false; // Đã xóa
    } else {
      if (_favoriteCities.length >= 5) {
        throw Exception("You can only save up to 5 cities");
      }
      _favoriteCities.add(cityName);
      await prefs.setStringList('favorite_cities', _favoriteCities);
      // Fetch data cho thành phố vừa thêm.
      fetchDataForLocation(cityName);
      
      notifyListeners();
      return true; // Đã thêm
    }
  }

  // Check xem một thành phố có trong danh sách yêu thích không.
  bool isFavorite(String cityName) {
    return _favoriteCities.contains(cityName);
  }

  // Lắng nghe thay đổi vị trí và tự động cập nhật
  void listenToLocationChanges() {
    _locationSubscription = _locationService.getLocationStream().listen((_) {
      // Khi có vị trí mới, fetch lại data cho vị trí hiện tại
      fetchDataForLocation('CURRENT_LOCATION', forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
