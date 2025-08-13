import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../model/entity.dart';

class MapManager {
  static const CameraPosition defaultLocation = CameraPosition(
    target: LatLng(23.8103, 90.4125),
    zoom: 7.0,
  );

  Set<Marker> createMarkers({
    required List<Entity> entities,
    Position? currentPosition,
    required Function(Entity) onEntityTap,
  }) {
    Set<Marker> markers = {};
    
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

  CameraPosition getCameraPositionForLocation(Position position) {
    return CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 16.0,
    );
  }

  CameraUpdate getCameraUpdateForLocation(Position position) {
    return CameraUpdate.newCameraPosition(
      getCameraPositionForLocation(position),
    );
  }
} 