import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../modelView/location_service.dart';
import '../model/entity.dart';
import '../model/api_service.dart';
import '../model/database_helper.dart';
import 'entity_form.dart';
import 'entity_list.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  final ApiService _apiService = ApiService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  Position? _currentPosition;
  Set<Marker> _markers = {};
  List<Entity> _entities = [];
  bool _isLoading = true;

  // Default location centered on Bangladesh
  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(23.8103, 90.4125), // Dhaka, Bangladesh
    zoom: 7.0,
  );

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
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });
        _updateEntityMarkers();

        // Move camera to current location
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(position.latitude, position.longitude),
                zoom: 16.0,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEntities() async {
    try {
      print('Loading entities from API...');
      // Try to fetch from API first
      final apiEntities = await _apiService.getAllEntities();
      
      if (apiEntities != null && apiEntities.isNotEmpty) {
        print('Loaded ${apiEntities.length} entities from API');
        setState(() {
          _entities = apiEntities;
        });
        _updateEntityMarkers();
        
        // Update local database with API data
        try {
          await _databaseHelper.deleteAllEntities();
          for (final entity in apiEntities) {
            await _databaseHelper.insertEntity(entity);
          }
        } catch (e) {
          print('Error updating local database: $e');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Loaded ${apiEntities.length} entities from server')),
          );
        }
      } else {
        print('API returned null or empty, trying local database...');
        // Fallback to local database if API fails
        final localEntities = await _databaseHelper.getAllEntities();
        print('Loaded ${localEntities.length} entities from local database');
        setState(() {
          _entities = localEntities;
        });
        _updateEntityMarkers();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localEntities.isEmpty 
                ? 'No entities found. Create some entities first!' 
                : 'Loaded ${localEntities.length} entities from local storage'),
              backgroundColor: localEntities.isEmpty ? Colors.orange : Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading entities: $e');
      // Load from local database on error
      final localEntities = await _databaseHelper.getAllEntities();
      print('Fallback: Loaded ${localEntities.length} entities from local database');
      setState(() {
        _entities = localEntities;
      });
      _updateEntityMarkers();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading from server. ${localEntities.isEmpty 
              ? 'No local entities found.' 
              : 'Loaded ${localEntities.length} entities from local storage'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateEntityMarkers() {
    Set<Marker> newMarkers = {};
    
    print('Updating markers for ${_entities.length} entities');
    
    // Add current location marker if available
    if (_currentPosition != null) {
      print('Adding current location marker at ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      newMarkers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(
            title: 'Your Location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    
    // Add entity markers
    for (final entity in _entities) {
      print('Adding entity marker: ${entity.title} at ${entity.lat}, ${entity.lon}');
      newMarkers.add(
        Marker(
          markerId: MarkerId('entity_${entity.id}'),
          position: LatLng(entity.lat, entity.lon),
          infoWindow: InfoWindow(
            title: entity.title,
            snippet: 'Tap to view details',
            onTap: () => _showEntityDetails(entity),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () => _showEntityDetails(entity),
        ),
      );
    }
    
    print('Total markers created: ${newMarkers.length}');
    setState(() {
      _markers = newMarkers;
    });
  }

  void _showEntityDetails(Entity entity) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(entity.title),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entity.image != null && entity.image!.isNotEmpty)
                        GestureDetector(
                          onTap: () => _showFullScreenImage(entity),
                          child: SizedBox(
                            width: double.infinity,
                            height: 200,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                entity.getFullImageUrl()!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(Icons.error, size: 50),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 50),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        entity.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Latitude: ${entity.lat}'),
                      const SizedBox(height: 4),
                      Text('Longitude: ${entity.lon}'),
                      const SizedBox(height: 16),
                      if (entity.image != null && entity.image!.isNotEmpty)
                        const Text(
                          'Tap image to view full size',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFullScreenImage(Entity entity) {
    Navigator.pop(context); // Close the details dialog first
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: Text(entity.title),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            backgroundColor: Colors.black,
            body: Center(
              child: InteractiveViewer(
                child: Image.network(
                  entity.getFullImageUrl()!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.error, size: 50, color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // If we already have current position, move camera to it
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  Future<void> _addSampleEntitiesIfEmpty() async {
    try {
      final existingEntities = await _databaseHelper.getAllEntities();
      if (existingEntities.isEmpty) {
        print('No entities found, adding sample entities for testing...');
        
        // Add some sample entities in Bangladesh
        final sampleEntities = [
          Entity(
            title: 'Dhaka - Capital City',
            lat: 23.8103,
            lon: 90.4125,
            image: 'images/dhaka.jpg',
          ),
          Entity(
            title: 'Chittagong - Port City',
            lat: 22.3569,
            lon: 91.7832,
            image: 'images/chittagong.jpg',
          ),
          Entity(
            title: 'Sylhet - Tea Gardens',
            lat: 24.8949,
            lon: 91.8687,
            image: 'images/sylhet.jpg',
          ),
          Entity(
            title: 'Cox\'s Bazar - Beach',
            lat: 21.4272,
            lon: 92.0058,
            image: 'images/coxsbazar.jpg',
          ),
        ];
        
        for (final entity in sampleEntities) {
          await _databaseHelper.insertEntity(entity);
        }
        
        print('Added ${sampleEntities.length} sample entities');
        
        // Reload entities to display the sample data
        await _loadEntities();
      }
    } catch (e) {
      print('Error adding sample entities: $e');
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
      _loadEntities(); // Refresh entities after creation
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
      _loadEntities(); // Refresh entities after any changes
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoLoc Map'),
        actions: [
          IconButton(
            onPressed: _loadEntities,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 48,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'GeoLoc App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Manage your locations',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Map View'),
              selected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_location),
              title: const Text('Create Entity'),
              onTap: () {
                Navigator.pop(context);
                _navigateToCreateEntity();
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Entity List'),
              onTap: () {
                Navigator.pop(context);
                _navigateToEntityList();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.my_location),
              title: const Text('Go to My Location'),
              onTap: () {
                Navigator.pop(context);
                _getCurrentLocation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh Entities'),
              onTap: () {
                Navigator.pop(context);
                _loadEntities();
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: _currentPosition != null
                      ? CameraPosition(
                          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                          zoom: 16.0,
                        )
                      : _defaultLocation,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false, // Disable default button
                ),
                // Custom location button positioned at bottom left
                Positioned(
                  bottom: 80, // Slightly above the Google logo
                  left: 16,   // Left margin
                  child: FloatingActionButton(
                    heroTag: "current_location", // Unique hero tag
                    mini: true, // Smaller size
                    onPressed: _getCurrentLocation,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    child: const Icon(Icons.my_location),
                  ),
                ),
                // Refresh button positioned below the location button
                Positioned(
                  bottom: 20, // Below the location button
                  left: 16,   // Same left margin as location button
                  child: FloatingActionButton(
                    heroTag: "refresh_entities", // Unique hero tag
                    mini: true, // Smaller size
                    onPressed: () {
                      print('Manual refresh triggered');
                      _loadEntities();
                    },
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.refresh),
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