import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseOperations {
  static final DatabaseOperations _instance = DatabaseOperations._internal();
  factory DatabaseOperations() => _instance;
  DatabaseOperations._internal();

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

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
} 