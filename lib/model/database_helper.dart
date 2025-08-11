import 'dart:math' show cos, pi;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'entity.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'entities.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE entities(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        lat REAL NOT NULL,
        lon REAL NOT NULL,
        image TEXT
      )
    ''');
  }

  // Create - Insert a new entity
  Future<int> insertEntity(Entity entity) async {
    final db = await database;
    return await db.insert('entities', entity.toMap());
  }

  // Read - Get all entities
  Future<List<Entity>> getAllEntities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('entities');
    return List.generate(maps.length, (i) {
      return Entity.fromMap(maps[i]);
    });
  }

  // Read - Get entity by ID
  Future<Entity?> getEntityById(int id) async {
    final db = await database;
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
    final db = await database;
    return await db.update(
      'entities',
      entity.toMap(),
      where: 'id = ?',
      whereArgs: [entity.id],
    );
  }

  // Delete - Delete an entity by ID
  Future<int> deleteEntity(int id) async {
    final db = await database;
    return await db.delete(
      'entities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete - Delete all entities
  Future<int> deleteAllEntities() async {
    final db = await database;
    return await db.delete('entities');
  }

  // Count - Get total number of entities
  Future<int> getEntityCount() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT COUNT(*) FROM entities');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Search - Get entities by title (partial match)
  Future<List<Entity>> searchEntitiesByTitle(String title) async {
    final db = await database;
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
    final db = await database;
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

  // Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
} 