import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../model/entity.dart';

class MapManager {
  // Default location centered on Bangladesh
  static const CameraPosition defaultLocation = CameraPosition(
    target: LatLng(23.8103, 90.4125), // Dhaka, Bangladesh
    zoom: 7.0,
  );

  // Create markers from entities and current position
  Set<Marker> createMarkers({
    required List<Entity> entities,
    Position? currentPosition,
    required Function(Entity) onEntityTap,
  }) {
    Set<Marker> markers = {};
    
    // Add current location marker if available
    if (currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(currentPosition.latitude, currentPosition.longitude),
          infoWindow: const InfoWindow(
            title: 'Your Location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    
    // Add entity markers
    for (final entity in entities) {
      markers.add(
        Marker(
          markerId: MarkerId('entity_${entity.id}'),
          position: LatLng(entity.lat, entity.lon),
          infoWindow: InfoWindow(
            title: entity.title,
            snippet: 'Tap to view details',
            onTap: () => onEntityTap(entity),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () => onEntityTap(entity),
        ),
      );
    }
    
    return markers;
  }

  // Get camera position for current location
  CameraPosition getCameraPositionForLocation(Position position) {
    return CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 16.0,
    );
  }

  // Get camera update for position
  CameraUpdate getCameraUpdateForLocation(Position position) {
    return CameraUpdate.newCameraPosition(
      getCameraPositionForLocation(position),
    );
  }
} 