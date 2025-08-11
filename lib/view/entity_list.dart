import 'package:flutter/material.dart';
import '../model/entity.dart';
import '../modelView/entity_manager.dart';
import 'entity_form.dart';

class EntityList extends StatefulWidget {
  const EntityList({super.key});

  @override
  State<EntityList> createState() => _EntityListState();
}

class _EntityListState extends State<EntityList> {
  final EntityManager _entityManager = EntityManager();
  
  List<Entity> _entities = [];
  bool _isLoading = false;
  bool _isDeleting = false;
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
      final entities = await _entityManager.loadEntities();
      setState(() {
        _entities = entities;
      });
    } catch (e) {
      setState(() {
        _entities = [];
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
    if (_isDeleting) return; // Prevent multiple simultaneous deletions
    
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
      setState(() {
        _isDeleting = true;
      });
      
      // Show loading state
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleting entity...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      try {
        final success = await _entityManager.deleteEntity(entity.id!);
        
        if (success) {
          // Add a small delay to allow image buffers to be released
          await Future.delayed(const Duration(milliseconds: 100));
          
          if (mounted) {
            setState(() {
              _entities.removeWhere((e) => e.id == entity.id);
            });
            
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Entity deleted successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete entity')),
            );
          }
        }
              } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting entity: $e')),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isDeleting = false;
            });
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
                              cacheWidth: 800, // Reasonable cache size
                              cacheHeight: 600,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.error, size: 50),
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
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
      appBar: AppBar(title: Text('List')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(labelText: 'Search'),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredEntities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_searchQuery.isEmpty
                                ? 'No entities found'
                                : 'No entities match your search'),
                            if (_searchQuery.isEmpty)
                              ElevatedButton(
                                onPressed: _createEntity,
                                child: Text('Create First Entity'),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadEntities,
                        child: ListView.builder(
                          key: ValueKey(_filteredEntities.length), // Rebuild when count changes
                          itemCount: _filteredEntities.length,
                          itemBuilder: (context, index) {
                            final entity = _filteredEntities[index];
                            return Card(
                              key: ValueKey('entity_${entity.id}'), // Unique key for each card
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
                                          cacheWidth: 120, // Limit cache size
                                          cacheHeight: 120,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.error),
                                            );
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.image),
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