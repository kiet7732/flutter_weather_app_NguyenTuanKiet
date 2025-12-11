import 'package:flutter/material.dart';
import '../../../models/location_model.dart';
import '../../../services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService = LocationService();
  
  LocationModel? _currentLocation;
  bool _isLoading = false;
  String? _error;

  LocationModel? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentLocation = await _locationService.getCurrentLocation();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}