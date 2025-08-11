import '../model/entity.dart';
import '../model/api_service.dart';
import '../model/entity_crud.dart';

class EntityManager {
  final ApiService _apiService = ApiService();
  final EntityCrud _entityCrud = EntityCrud();

  // Load entities from API with local database fallback
  Future<List<Entity>> loadEntities() async {
    try {
      // Try to fetch from API first
      final apiEntities = await _apiService.getAllEntities();
      
      if (apiEntities != null && apiEntities.isNotEmpty) {
        // Update local database with API data
        try {
          await _entityCrud.deleteAllEntities();
          for (final entity in apiEntities) {
            await _entityCrud.insertEntity(entity);
          }
        } catch (e) {
          // Silently handle database update errors
        }
        return apiEntities;
      } else {
        // Fallback to local database if API fails
        return await _entityCrud.getAllEntities();
      }
    } catch (e) {
      // Load from local database on error
      return await _entityCrud.getAllEntities();
    }
  }

  // Create new entity
  Future<bool> createEntity({
    required String title,
    required double lat,
    required double lon,
    var imageFile,
  }) async {
    try {
      final result = await _apiService.createEntity(
        title: title,
        lat: lat,
        lon: lon,
        imageFile: imageFile,
      );

      if (result != null) {
        // Save to local database
        final newEntity = Entity(
          title: title,
          lat: lat,
          lon: lon,
          image: 'created_image_path',
        );
        await _entityCrud.insertEntity(newEntity);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Update existing entity
  Future<bool> updateEntity({
    required int id,
    required String title,
    required double lat,
    required double lon,
    var imageFile,
    String? currentImage,
  }) async {
    try {
      final result = await _apiService.updateEntity(
        id: id,
        title: title,
        lat: lat,
        lon: lon,
        imageFile: imageFile,
      );

      if (result != null) {
        // Update in local database
        final updatedEntity = Entity(
          id: id,
          title: title,
          lat: lat,
          lon: lon,
          image: imageFile != null ? 'updated_image_path' : currentImage,
        );
        await _entityCrud.updateEntity(updatedEntity);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Delete entity
  Future<bool> deleteEntity(int id) async {
    try {
      // Delete from API
      final success = await _apiService.deleteEntity(id);
      
      if (success) {
        // Delete from local database
        await _entityCrud.deleteEntity(id);
        return true;
      } else {
        // Try to delete from local database anyway
        await _entityCrud.deleteEntity(id);
        return true; // Consider local deletion as success
      }
    } catch (e) {
      return false;
    }
  }
} 