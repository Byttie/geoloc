import 'dart:math' show cos, pi;
import 'package:sqflite/sqflite.dart';
import 'entity.dart';
import 'database_operations.dart';

class EntityQueries {
  final DatabaseOperations _dbOps = DatabaseOperations();

  // Count - Get total number of entities
  Future<int> getEntityCount() async {
    final db = await _dbOps.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT COUNT(*) FROM entities');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Search - Get entities by title (partial match)
  Future<List<Entity>> searchEntitiesByTitle(String title) async {
    final db = await _dbOps.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'entities',
      where: 'title LIKE ?',
      whereArgs: ['%$title%'],
    );
    return List.generate(maps.length, (i) {
      return Entity.fromMap(maps[i]);
    });
  }

  // Get entities within a certain distance from a point
  Future<List<Entity>> getEntitiesNearLocation(double lat, double lon, double radiusInKm) async {
    final db = await _dbOps.database;
    // Using simple bounding box for performance (not exact distance calculation)
    final double latDelta = radiusInKm / 111.0; // Rough conversion: 1 degree latitude ≈ 111 km
    final double lonDelta = radiusInKm / (111.0 * cos(lat * pi / 180));
    
    final List<Map<String, dynamic>> maps = await db.query(
      'entities',
      where: 'lat BETWEEN ? AND ? AND lon BETWEEN ? AND ?',
      whereArgs: [
        lat - latDelta,
        lat + latDelta,
        lon - lonDelta,
        lon + lonDelta,
      ],
    );
    return List.generate(maps.length, (i) {
      return Entity.fromMap(maps[i]);
    });
  }
} 