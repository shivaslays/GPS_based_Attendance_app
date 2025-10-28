import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  bool _isLocationEnabled = false;
  bool _isLoading = false;
  Timer? _locationTimer;
  bool _isMonitoring = false;

  Position? get currentPosition => _currentPosition;
  bool get isLocationEnabled => _isLocationEnabled;
  bool get isLoading => _isLoading;
  bool get isMonitoring => _isMonitoring;

  Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Permission request error: $e');
      return false;
    }
  }

  Future<bool> getCurrentLocation() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _isLocationEnabled = false;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _isLocationEnabled = false;
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _isLocationEnabled = false;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      _isLocationEnabled = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Location error: $e');
      _isLocationEnabled = false;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  bool isWithinRange(double teacherLat, double teacherLon, double rangeInMeters) {
    if (_currentPosition == null) return false;
    
    double distance = calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      teacherLat,
      teacherLon,
    );
    
    return distance <= rangeInMeters;
  }

  // Start continuous location monitoring
  void startLocationMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateLocationSilently();
    });
    
    // Get initial location
    _updateLocationSilently();
    notifyListeners();
  }

  // Stop location monitoring
  void stopLocationMonitoring() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _isMonitoring = false;
    notifyListeners();
  }

  // Update location without showing loading state
  Future<void> _updateLocationSilently() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _isLocationEnabled = false;
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        _isLocationEnabled = false;
        return;
      }

      // Get current position
      final newPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      // Only update if position has changed significantly (more than 5 meters)
      if (_currentPosition == null || 
          calculateDistance(
            _currentPosition!.latitude, 
            _currentPosition!.longitude,
            newPosition.latitude, 
            newPosition.longitude
          ) > 5) {
        _currentPosition = newPosition;
        _isLocationEnabled = true;
        notifyListeners();
      }
    } catch (e) {
      print('Silent location update error: $e');
      // Don't update UI for silent location errors
    }
  }

  @override
  void dispose() {
    stopLocationMonitoring();
    super.dispose();
  }
}
