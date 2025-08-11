import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permissions
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Open app settings for user to manually enable location
      await openAppSettings();
      return false;
    }
    
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location service is enabled
      if (!await isLocationServiceEnabled()) {
        throw Exception('Location services are disabled.');
      }

      // Check and request permissions
      if (!await requestLocationPermission()) {
        throw Exception('Location permissions are denied.');
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return _currentPosition;
    } catch (e) {
      return null;
    }
  }

  /// Get location stream for real-time updates
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream();
  }

  /// Calculate distance between two points
  double calculateDistance(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
} 