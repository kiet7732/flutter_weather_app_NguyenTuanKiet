import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/models/weather_model.dart';

void main() {
  group('WeatherModel Tests', () {
    test('Test parse JSON - fromJson nên parse đúng data từ Map', () {
      // Arrange: Chuẩn bị data JSON giả.
      final json = <String, dynamic>{
        'name': 'Ho Chi Minh City',
        'main': {
          'temp': 25.0,
          'feels_like': 26.0,
          'humidity': 80,
          'pressure': 1010,
          'temp_min': 24.0,
          'temp_max': 26.0
        },
        'weather': [
          {'main': 'Clouds', 'description': 'overcast clouds', 'icon': '04d'}
        ],
        'wind': {'speed': 3.1},
        'sys': {'country': 'VN', 'sunrise': 1618282138, 'sunset': 1618330496},
        'dt': 1618317040,
        'coord': {'lat': 10.82, 'lon': 106.63},
        'visibility': 10000,
        'clouds': {'all': 90}
      };

      // Act: Gọi hàm fromJson để parse.
      final weather = WeatherModel.fromJson(json);

      // Assert: Check xem các trường có đúng giá trị không.
      expect(weather.temperature, 25.0);
      expect(weather.cityName, 'Ho Chi Minh City');
      expect(weather.mainCondition, 'Clouds');
    });
  });
}
