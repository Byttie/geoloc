import 'package:flutter/material.dart';
import '../model/entity.dart';
import '../modelView/entity_manager.dart';
import 'entity_form.dart';
import '../utils/image_utils.dart';

class EntityList extends StatefulWidget {
  const EntityList({super.key});

  @override
  State<EntityList> createState() => _EntityListState();
}

class _EntityListState extends State<EntityList> {
  final EntityManager _entityManager = EntityManager();
  
  List<Entity> _entities = [];
  bool _isLoading = false;

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
      
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                        ImageDisplayUtils.buildNetworkImage(
                          imageUrl: entity.getFullImageUrl()!,
                          height: 400,
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
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _editEntity(entity);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                        ),
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
      _loadEntities();
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('List')),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadEntities,
                    child: ListView.builder(
                      key: ValueKey(_entities.length),
                      itemCount: _entities.length,
                      itemBuilder: (context, index) {
                        final entity = _entities[index];
                        return Card(
                          key: ValueKey('entity_${entity.id}'),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          child: ListTile(
                            leading: entity.image != null && entity.image!.isNotEmpty
                                ? ImageDisplayUtils.buildNetworkImage(
                                    imageUrl: entity.getFullImageUrl()!,
                                    height: 60,
                                    width: 60,
                                    fit: BoxFit.cover,
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
                            onTap: () => _showEntityDetails(entity),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
} 