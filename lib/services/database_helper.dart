import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/todo_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static String? testPath;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('todo_eisenhower.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // macOS desktop initialization for SQLite
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (testPath != null) {
      path = testPath!;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    // Note: If you want to configure shared containers for App Groups in the future:
    // final sharedDirectory = await getApplicationDocumentsDirectory(); // Custom App Group path goes here
    // final path = join(sharedDirectory.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        quadrant INTEGER NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        is_trash INTEGER NOT NULL DEFAULT 0,
        due_date TEXT,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        deleted_at TEXT
      )
    ''');
  }

  Future<int> insert(Todo todo) async {
    final db = await instance.database;
    return await db.insert('todos', todo.toMap());
  }

  Future<List<Todo>> fetchAllActive() async {
    final db = await instance.database;
    final maps = await db.query(
      'todos',
      where: 'is_trash = 0',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Todo.fromMap(map)).toList();
  }

  Future<List<Todo>> fetchTrash() async {
    final db = await instance.database;
    final maps = await db.query(
      'todos',
      where: 'is_trash = 1',
      orderBy: 'deleted_at DESC',
    );
    return maps.map((map) => Todo.fromMap(map)).toList();
  }

  Future<int> update(Todo todo) async {
    final db = await instance.database;
    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<int> deletePermanently(int id) async {
    final db = await instance.database;
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearTrash() async {
    final db = await instance.database;
    return await db.delete(
      'todos',
      where: 'is_trash = 1',
    );
  }

  /// Finds active (uncompleted) Q4 tasks created more than 7 days ago and soft-deletes them.
  /// Returns the number of items soft-deleted.
  Future<int> incinerateOldQ4Tasks() async {
    final db = await instance.database;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7)).toIso8601String();

    // First find which IDs will be deleted so we can log or count them
    final List<Map<String, dynamic>> results = await db.query(
      'todos',
      columns: ['id'],
      where: 'quadrant = 4 AND is_completed = 0 AND is_trash = 0 AND created_at < ?',
      whereArgs: [sevenDaysAgo],
    );

    if (results.isEmpty) return 0;

    final count = results.length;

    await db.update(
      'todos',
      {
        'is_trash': 1,
        'deleted_at': now.toIso8601String(),
      },
      where: 'quadrant = 4 AND is_completed = 0 AND is_trash = 0 AND created_at < ?',
      whereArgs: [sevenDaysAgo],
    );

    return count;
  }
}
