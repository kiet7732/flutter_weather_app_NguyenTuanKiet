import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/services/weather_service.dart';

// Annotation để bảo build_runner tạo mock class cho http.Client.
@GenerateMocks([http.Client])
import 'weather_service_test.mocks.dart';

void main() {
  late MockClient mockClient;
  late WeatherService weatherService;

  // Hàm này chạy trước mỗi test, dùng để khởi tạo các đối tượng cần thiết.
  setUp(() {
    mockClient = MockClient();
    weatherService = WeatherService(apiKey: 'test_api_key', client: mockClient);
  });

  group('WeatherModel', () {
    test('Test parse JSON - fromJson nên parse đúng data từ Map', () {
      // Arrange: Chuẩn bị data JSON giả.
      final jsonMap = {
        'name': 'Hanoi',
        'main': {'temp': 25.0, 'feels_like': 26.0, 'humidity': 80, 'pressure': 1010},
        'weather': [{'main': 'Clouds', 'description': 'overcast clouds', 'icon': '04d'}],
        'wind': {'speed': 3.1},
        'sys': {'country': 'VN', 'sunrise': 1618282138, 'sunset': 1618330496},
        'dt': 1618317040,
        'coord': {'lat': 21.02, 'lon': 105.84},
        'visibility': 10000,
        'clouds': {'all': 90}
      };

      // Act: Gọi hàm fromJson để parse.
      final weather = WeatherModel.fromJson(jsonMap);

      // Assert: Check xem các trường có đúng giá trị không.
      expect(weather.cityName, 'Hanoi');
      expect(weather.temperature, 25.0);
      expect(weather.mainCondition, 'Clouds');
    });
  });

  group('WeatherService', () {
    test('Test gọi API thành công - nên trả về một WeatherModel', () async {
      // Arrange: Chuẩn bị data và giả lập API trả về 200 OK.
      const cityName = 'London';
      final mockResponse = jsonEncode({
        'name': 'London',
        'main': {'temp': 15.0, 'feels_like': 14.0, 'humidity': 82, 'pressure': 1012},
        'weather': [{'main': 'Clear', 'description': 'clear sky', 'icon': '01d'}],
        'wind': {'speed': 3.6},
        'sys': {'country': 'GB', 'sunrise': 1618282138, 'sunset': 1618330496},
        'dt': 1618317040,
        'coord': {'lat': 51.51, 'lon': -0.13},
        'visibility': 10000,
        'clouds': {'all': 0}
      });

      // Giả lập: khi mockClient.get được gọi với bất kỳ URL nào,
      // nó sẽ trả về một http.Response thành công (200) với body là mockResponse.
      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response(mockResponse, 200));

      // Act: Gọi hàm cần test.
      final result = await weatherService.getCurrentWeatherByCity(cityName);

      // Assert: Check xem kết quả có phải là một WeatherModel không.
      expect(result, isA<WeatherModel>());
      expect(result.cityName, 'London');
      expect(result.temperature, 15.0);
    });

    test('Test gọi API thất bại - nên ném ra Exception khi gặp lỗi 404', () async {
      // Arrange: Giả lập API trả về lỗi 404 Not Found.
      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      // Act & Assert: Check xem hàm có ném ra đúng Exception không.
      // Dùng expect(..., throwsException) để bắt lỗi.
      expect(
        () => weatherService.getCurrentWeatherByCity('UnknownCity'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'toString',
          contains('City not found'),
        )),
      );
    });
  });
}