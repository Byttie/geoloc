import '../model/entity.dart';
import '../model/api_service.dart';

class EntityManager {
  final ApiService _apiService = ApiService();

  Future<List<Entity>> loadEntities() async {
    try {
      final apiEntities = await _apiService.getAllEntities();
      return apiEntities ?? [];
    } catch (e) {
      return [];
    }
  }

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

      return result != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateEntity({
    required int id,
    required String title,
    required double lat,
    required double lon,
    var imageFile,
  }) async {
    try {
      final result = await _apiService.updateEntity(
        id: id,
        title: title,
        lat: lat,
        lon: lon,
        imageFile: imageFile,
      );

      return result != null;
    } catch (e) {
      return false;
    }
  }
} 