import 'package:flutter/material.dart';
import '../model/entity.dart';
import '../model/api_service.dart';
import '../model/database_helper.dart';
import 'entity_form.dart';

class EntityList extends StatefulWidget {
  const EntityList({super.key});

  @override
  State<EntityList> createState() => _EntityListState();
}

class _EntityListState extends State<EntityList> {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  
  List<Entity> _entities = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEntities();
  }

  Future<void> _loadEntities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to fetch from API first
      final apiEntities = await _apiService.getAllEntities();
      
      if (apiEntities != null) {
        // Update local database with API data
        await _databaseHelper.deleteAllEntities();
        for (final entity in apiEntities) {
          await _databaseHelper.insertEntity(entity);
        }
        setState(() {
          _entities = apiEntities;
        });
      } else {
        // Fallback to local database if API fails
        final localEntities = await _databaseHelper.getAllEntities();
        setState(() {
          _entities = localEntities;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Loaded from local storage (API unavailable)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Load from local database on error
      final localEntities = await _databaseHelper.getAllEntities();
      setState(() {
        _entities = localEntities;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading entities: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Entity> get _filteredEntities {
    if (_searchQuery.isEmpty) {
      return _entities;
    }
    return _entities.where((entity) =>
        entity.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  Future<void> _deleteEntity(Entity entity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Entity'),
          content: Text('Are you sure you want to delete "${entity.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Delete from API
        final success = await _apiService.deleteEntity(entity.id!);
        
        if (success) {
          // Delete from local database
          await _databaseHelper.deleteEntity(entity.id!);
          
          // Update UI
          setState(() {
            _entities.removeWhere((e) => e.id == entity.id);
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Entity deleted successfully')),
            );
          }
        } else {
          // Try to delete from local database anyway
          await _databaseHelper.deleteEntity(entity.id!);
          setState(() {
            _entities.removeWhere((e) => e.id == entity.id);
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Deleted locally (API unavailable)'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting entity: $e')),
          );
        }
      }
    }
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
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 400),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              entity.getFullImageUrl()!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.error, size: 50),
                                  ),
                                );
                              },
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
                        'Title: ${entity.title}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Latitude: ${entity.lat}'),
                      const SizedBox(height: 4),
                      Text('Longitude: ${entity.lon}'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _editEntity(entity);
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteEntity(entity);
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ],
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

  void _editEntity(Entity entity) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntityForm(entity: entity),
      ),
    );

    if (result == true) {
      _loadEntities(); // Refresh the list
    }
  }

  void _createEntity() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EntityForm(),
      ),
    );

    if (result == true) {
      _loadEntities(); // Refresh the list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entity List'),
        actions: [
          IconButton(
            onPressed: _loadEntities,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search entities...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Entity list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEntities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inbox, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No entities found'
                                  : 'No entities match your search',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            if (_searchQuery.isEmpty)
                              ElevatedButton.icon(
                                onPressed: _createEntity,
                                icon: const Icon(Icons.add),
                                label: const Text('Create First Entity'),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadEntities,
                        child: ListView.builder(
                          itemCount: _filteredEntities.length,
                          itemBuilder: (context, index) {
                            final entity = _filteredEntities[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 4.0,
                              ),
                              child: ListTile(
                                leading: entity.image != null && entity.image!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          entity.getFullImageUrl()!,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.error),
                                            );
                                          },
                                        ),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.image),
                                      ),
                                title: Text(
                                  entity.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Lat: ${entity.lat.toStringAsFixed(4)}, '
                                  'Lon: ${entity.lon.toStringAsFixed(4)}',
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'edit':
                                        _editEntity(entity);
                                        break;
                                      case 'delete':
                                        _deleteEntity(entity);
                                        break;
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: ListTile(
                                        leading: Icon(Icons.edit),
                                        title: Text('Edit'),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(Icons.delete, color: Colors.red),
                                        title: Text('Delete', style: TextStyle(color: Colors.red)),
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _showEntityDetails(entity),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createEntity,
        child: const Icon(Icons.add),
      ),
    );
  }
} 