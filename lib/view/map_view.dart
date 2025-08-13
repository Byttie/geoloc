import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../modelView/location_service.dart';
import '../modelView/entity_manager.dart';
import '../modelView/map_manager.dart';
import '../model/entity.dart';
import 'entity_form.dart';
import 'entity_list.dart';
import '../utils/image_utils.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _mapController; 
  final LocationService _locationService = LocationService(); 
  final EntityManager _entityManager = EntityManager(); 
  final MapManager _mapManager = MapManager();
  Position? _currentPosition;
  Set<Marker> _markers = {}; 
  List<Entity> _entities = [];
  bool _isLoading = true; 

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadEntities();
  }

  Future<void> _getCurrentLocation() async { 
    setState(() {
      _isLoading = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
      _updateEntityMarkers();

              if (_mapController != null) {
        _mapController!.animateCamera(
          _mapManager.getCameraUpdateForLocation(position),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEntities() async {
    try {
      final entities = await _entityManager.loadEntities();
      setState(() {
        _entities = entities;
      });
      _updateEntityMarkers();
      
    } catch (e) {
      setState(() {
        _entities = [];
      });
      _updateEntityMarkers();
    }
  }

  void _updateEntityMarkers() {
    final markers = _mapManager.createMarkers(
      entities: _entities,
      currentPosition: _currentPosition,
      onEntityTap: _showEntityDetails,
    );
    
    setState(() {
      _markers = markers;
    });
  }

  void _showEntityDetails(Entity entity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entity.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entity.image != null && entity.image!.isNotEmpty)
              ImageDisplayUtils.buildNetworkImage(
                imageUrl: entity.getFullImageUrl()!,
                height: 150,
              ),
            SizedBox(height: 8),
            Text('Lat: ${entity.lat}'),
            Text('Lon: ${entity.lon}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }



  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    if (_currentPosition != null) {
      controller.animateCamera(
        _mapManager.getCameraUpdateForLocation(_currentPosition!),
      );
    }
  }


  void _navigateToCreateEntity() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EntityForm(),
      ),
    );

    if (result == true) {
      _loadEntities();
    }
  }

  void _navigateToEntityList() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EntityList(),
      ),
    );

    if (result == true) {
      _loadEntities();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map')),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: Text('Map'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text('Create'),
              onTap: () {
                Navigator.pop(context);
                _navigateToCreateEntity();
              },
            ),
            ListTile(
              title: Text('List'),
              onTap: () {
                Navigator.pop(context);
                _navigateToEntityList();
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: _currentPosition != null
                      ? _mapManager.getCameraPositionForLocation(_currentPosition!)
                      : MapManager.defaultLocation,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                ),
                Positioned(
                  bottom: 80,
                  left: 16,
                  child: FloatingActionButton(
                    heroTag: "location",
                    mini: true,
                    onPressed: _getCurrentLocation,
                    child: Icon(Icons.my_location),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 16,
                  child: FloatingActionButton(
                    heroTag: "refresh",
                    mini: true,
                    onPressed: _loadEntities,
                    child: Icon(Icons.refresh),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
} 