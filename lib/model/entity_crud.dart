import 'entity.dart';
import 'database_operations.dart';

class EntityCrud {
  final DatabaseOperations _dbOps = DatabaseOperations();

  // Create - Insert a new entity
  Future<int> insertEntity(Entity entity) async {
    final db = await _dbOps.database;
    return await db.insert('entities', entity.toMap());
  }

  // Read - Get all entities
  Future<List<Entity>> getAllEntities() async {
    final db = await _dbOps.database;
    final List<Map<String, dynamic>> maps = await db.query('entities');
    return List.generate(maps.length, (i) {
      return Entity.fromMap(maps[i]);
    });
  }

  // Read - Get entity by ID
  Future<Entity?> getEntityById(int id) async {
    final db = await _dbOps.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'entities',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Entity.fromMap(maps.first);
    }
    return null;
  }

  // Update - Update an existing entity
  Future<int> updateEntity(Entity entity) async {
    final db = await _dbOps.database;
    return await db.update(
      'entities',
      entity.toMap(),
      where: 'id = ?',
      whereArgs: [entity.id],
    );
  }

  // Delete - Delete an entity by ID
  Future<int> deleteEntity(int id) async {
    final db = await _dbOps.database;
    return await db.delete(
      'entities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete - Delete all entities
  Future<int> deleteAllEntities() async {
    final db = await _dbOps.database;
    return await db.delete('entities');
  }
} 