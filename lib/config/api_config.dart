class ApiConfig {
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';
  // Xóa dòng này hoặc không sử dụng nó để ghi đè params
  // static const String apiKey = String.fromEnvironment('OPENWEATHER_API_KEY');
  
  // Endpoints
  static const String currentWeather = '/weather';
  static const String forecast = '/forecast';
  static const String oneCall = '/onecall';
  
  // Build URL
  static String buildUrl(String endpoint, Map<String, dynamic> params) {
    final uri = Uri.parse('$baseUrl$endpoint');
    // Không ghi đè appid nếu nó đã được truyền vào từ Service
    // params['appid'] = apiKey; 
    params['units'] = 'metric'; // or 'imperial'
    return uri.replace(queryParameters: params).toString();
  }
}