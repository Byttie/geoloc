import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal(); 
  factory LocationService() => _instance; 
  LocationService._internal();

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  /// Get current location - throws error if location not enabled
  Future<Position> getCurrentLocation() async {
    // Check if location service is enabled
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Location services are disabled. Please enable location services to use this app.');
    }

    // Get current position
    _currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return _currentPosition!;
  }


} 