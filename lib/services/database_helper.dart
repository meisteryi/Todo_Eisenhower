import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/category_model.dart';
import '../models/routine_model.dart';
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
    // macOS/Desktop initialization for SQLite
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

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        quadrant INTEGER NOT NULL,
        category_id INTEGER,
        routine_id INTEGER,
        target_date TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        is_trash INTEGER NOT NULL DEFAULT 0,
        due_date TEXT,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        deleted_at TEXT,
        location TEXT,
        time_str TEXT,
        due_time_str TEXT,
        memo TEXT,
        has_notification INTEGER NOT NULL DEFAULT 0,
        notification_offset INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color_hex TEXT NOT NULL,
        emoji TEXT NOT NULL DEFAULT '📝',
        is_visible INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE routines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        title TEXT NOT NULL,
        repeat_type TEXT NOT NULL,
        repeat_days TEXT NOT NULL,
        start_date TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Populate default categories
    for (final cat in Category.defaultCategories()) {
      await db.insert('categories', cat.toMap());
    }
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE todos ADD COLUMN category_id INTEGER');
      await db.execute('ALTER TABLE todos ADD COLUMN routine_id INTEGER');
      await db.execute('ALTER TABLE todos ADD COLUMN target_date TEXT');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          color_hex TEXT NOT NULL,
          emoji TEXT NOT NULL DEFAULT '📝',
          is_visible INTEGER NOT NULL DEFAULT 1,
          sort_order INTEGER NOT NULL DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS routines (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category_id INTEGER,
          title TEXT NOT NULL,
          repeat_type TEXT NOT NULL,
          repeat_days TEXT NOT NULL,
          start_date TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1
        )
      ''');

      // Populate default categories if empty
      final catCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM categories')) ?? 0;
      if (catCount == 0) {
        for (final cat in Category.defaultCategories()) {
          await db.insert('categories', cat.toMap());
        }
      }

      // Populate target_date for existing todos using created_at date
      await db.execute('''
        UPDATE todos SET target_date = substr(created_at, 1, 10) WHERE target_date IS NULL
      ''');
    }

    if (oldVersion < 3) {
      try { await db.execute('ALTER TABLE todos ADD COLUMN location TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE todos ADD COLUMN time_str TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE todos ADD COLUMN memo TEXT'); } catch (_) {}
    }

    if (oldVersion < 4) {
      try { await db.execute('ALTER TABLE todos ADD COLUMN has_notification INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
    }

    if (oldVersion < 5) {
      try { await db.execute('ALTER TABLE todos ADD COLUMN notification_offset INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
    }

    if (oldVersion < 6) {
      try { await db.execute('ALTER TABLE todos ADD COLUMN due_time_str TEXT'); } catch (_) {}
    }
  }

  // --- TODOS ---

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
  Future<int> incinerateOldQ4Tasks() async {
    final db = await instance.database;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7)).toIso8601String();

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

  // --- CATEGORIES ---

  Future<List<Category>> fetchCategories() async {
    final db = await instance.database;
    final maps = await db.query(
      'categories',
      orderBy: 'sort_order ASC, id ASC',
    );
    if (maps.isEmpty) {
      // Re-populate if missing
      for (final cat in Category.defaultCategories()) {
        await db.insert('categories', cat.toMap());
      }
      return Category.defaultCategories();
    }
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await instance.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    // Set category_id to NULL on related todos
    await db.update(
      'todos',
      {'category_id': null},
      where: 'category_id = ?',
      whereArgs: [id],
    );
    // Delete routines under category
    await db.delete(
      'routines',
      where: 'category_id = ?',
      whereArgs: [id],
    );
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- ROUTINES ---

  Future<List<Routine>> fetchRoutines() async {
    final db = await instance.database;
    final maps = await db.query('routines', orderBy: 'id ASC');
    return maps.map((map) => Routine.fromMap(map)).toList();
  }

  Future<int> insertRoutine(Routine routine) async {
    final db = await instance.database;
    return await db.insert('routines', routine.toMap());
  }

  Future<int> updateRoutine(Routine routine) async {
    final db = await instance.database;
    return await db.update(
      'routines',
      routine.toMap(),
      where: 'id = ?',
      whereArgs: [routine.id],
    );
  }

  Future<int> deleteRoutine(int id) async {
    final db = await instance.database;
    return await db.delete(
      'routines',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
