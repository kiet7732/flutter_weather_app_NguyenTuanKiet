import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/location_model.dart';

class LocationService {
  // Kiểm tra và yêu cầu quyền truy cập vị trí.
  Future<bool> handlePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Dịch vụ vị trí bị tắt, không thể tiếp tục.
      throw Exception('Location services are disabled.');
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Người dùng từ chối cấp quyền.
        throw Exception('Location permissions are denied.');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Quyền bị từ chối vĩnh viễn, không thể yêu cầu lại.
      throw Exception('Location permissions are permanently denied, we cannot request permissions.');
    }
    
    return true;
  }
  
  // Lấy vị trí hiện tại (sau khi đã có quyền).
  Future<LocationModel> getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String? cityName;
    try {
      cityName = await getCityName(position.latitude, position.longitude);
    } catch (_) {}

    return LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      cityName: cityName,
    );
  }
  
  // Lấy tên thành phố từ tọa độ.
  Future<String> getCityName(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        return placemarks[0].locality ?? 'Unknown';
      }
      return 'Unknown';
    } catch (e) {
      throw Exception('Failed to get city name');
    }
  }

  // Lắng nghe sự thay đổi vị trí
  Stream<Position> getLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Giảm xuống 10m để cập nhật nhạy hơn
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }
}
