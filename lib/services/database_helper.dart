import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/category_model.dart';
import '../models/routine_model.dart';
import '../models/todo_model.dart';
import '../models/workout_model.dart';

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
      version: 8,
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
        due_date TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        is_trash INTEGER NOT NULL DEFAULT 0,
        trashed_at TEXT,
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
        quadrant INTEGER NOT NULL DEFAULT 1,
        repeat_type TEXT NOT NULL,
        repeat_days TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        location TEXT,
        time_str TEXT,
        due_time_str TEXT,
        memo TEXT,
        has_notification INTEGER NOT NULL DEFAULT 0,
        notification_offset INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        emoji TEXT NOT NULL DEFAULT '🏋️',
        category TEXT NOT NULL DEFAULT '웨이트',
        workout_type TEXT NOT NULL DEFAULT 'set',
        target_sets INTEGER NOT NULL DEFAULT 3,
        target_reps INTEGER NOT NULL DEFAULT 10,
        target_weight REAL NOT NULL DEFAULT 0.0,
        target_minutes INTEGER NOT NULL DEFAULT 30,
        repeat_days TEXT NOT NULL DEFAULT '월,화,수,목,금,토,일',
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE workout_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        completed_sets INTEGER NOT NULL DEFAULT 0,
        set_details_json TEXT,
        duration_minutes INTEGER NOT NULL DEFAULT 0,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        memo TEXT
      )
    ''');

    // Populate default categories
    for (final cat in Category.defaultCategories()) {
      await db.insert('categories', cat.toMap());
    }

    // Populate default workouts
    for (final w in Workout.defaultWorkouts()) {
      await db.insert('workouts', w.toMap());
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

      final catCheck = await db.rawQuery('SELECT count(*) as count FROM categories');
      if ((catCheck.first['count'] as int) == 0) {
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

    if (oldVersion < 7) {
      try { await db.execute('ALTER TABLE routines ADD COLUMN quadrant INTEGER NOT NULL DEFAULT 1'); } catch (_) {}
      try { await db.execute('ALTER TABLE routines ADD COLUMN end_date TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE routines ADD COLUMN location TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE routines ADD COLUMN time_str TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE routines ADD COLUMN due_time_str TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE routines ADD COLUMN memo TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE routines ADD COLUMN has_notification INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
      try { await db.execute('ALTER TABLE routines ADD COLUMN notification_offset INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
    }

    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS workouts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          emoji TEXT NOT NULL DEFAULT '🏋️',
          category TEXT NOT NULL DEFAULT '웨이트',
          workout_type TEXT NOT NULL DEFAULT 'set',
          target_sets INTEGER NOT NULL DEFAULT 3,
          target_reps INTEGER NOT NULL DEFAULT 10,
          target_weight REAL NOT NULL DEFAULT 0.0,
          target_minutes INTEGER NOT NULL DEFAULT 30,
          repeat_days TEXT NOT NULL DEFAULT '월,화,수,목,금,토,일',
          sort_order INTEGER NOT NULL DEFAULT 0,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS workout_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workout_id INTEGER NOT NULL,
          date TEXT NOT NULL,
          completed_sets INTEGER NOT NULL DEFAULT 0,
          set_details_json TEXT,
          duration_minutes INTEGER NOT NULL DEFAULT 0,
          is_completed INTEGER NOT NULL DEFAULT 0,
          completed_at TEXT,
          memo TEXT
        )
      ''');

      final wCheck = await db.rawQuery('SELECT count(*) as count FROM workouts');
      if ((wCheck.first['count'] as int) == 0) {
        for (final w in Workout.defaultWorkouts()) {
          await db.insert('workouts', w.toMap());
        }
      }
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

  Future<int> clearAllTodos() async {
    final db = await instance.database;
    return await db.delete('todos');
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
    try { await db.execute('ALTER TABLE routines ADD COLUMN quadrant INTEGER NOT NULL DEFAULT 1'); } catch (_) {}
    try { await db.execute('ALTER TABLE routines ADD COLUMN end_date TEXT'); } catch (_) {}
    try { await db.execute('ALTER TABLE routines ADD COLUMN location TEXT'); } catch (_) {}
    try { await db.execute('ALTER TABLE routines ADD COLUMN time_str TEXT'); } catch (_) {}
    try { await db.execute('ALTER TABLE routines ADD COLUMN due_time_str TEXT'); } catch (_) {}
    try { await db.execute('ALTER TABLE routines ADD COLUMN memo TEXT'); } catch (_) {}
    try { await db.execute('ALTER TABLE routines ADD COLUMN has_notification INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
    try { await db.execute('ALTER TABLE routines ADD COLUMN notification_offset INTEGER NOT NULL DEFAULT 0'); } catch (_) {}

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

  // --- WORKOUTS ---

  Future<List<Workout>> fetchWorkouts() async {
    final db = await instance.database;
    final maps = await db.query('workouts', where: 'is_active = 1', orderBy: 'sort_order ASC, id ASC');
    return maps.map((map) => Workout.fromMap(map)).toList();
  }

  Future<int> insertWorkout(Workout workout) async {
    final db = await instance.database;
    return await db.insert('workouts', workout.toMap());
  }

  Future<int> updateWorkout(Workout workout) async {
    final db = await instance.database;
    return await db.update(
      'workouts',
      workout.toMap(),
      where: 'id = ?',
      whereArgs: [workout.id],
    );
  }

  Future<int> deleteWorkout(int id) async {
    final db = await instance.database;
    // Mark as inactive instead of hard delete to keep historical logs
    return await db.update(
      'workouts',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- WORKOUT LOGS ---

  Future<List<WorkoutLog>> fetchWorkoutLogsForDate(String dateStr) async {
    final db = await instance.database;
    final maps = await db.query(
      'workout_logs',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    return maps.map((map) => WorkoutLog.fromMap(map)).toList();
  }

  Future<List<WorkoutLog>> fetchWorkoutLogsForMonth(String yyyyMM) async {
    final db = await instance.database;
    final maps = await db.query(
      'workout_logs',
      where: 'date LIKE ?',
      whereArgs: ['$yyyyMM%'],
    );
    return maps.map((map) => WorkoutLog.fromMap(map)).toList();
  }

  Future<int> upsertWorkoutLog(WorkoutLog log) async {
    final db = await instance.database;
    if (log.id != null) {
      return await db.update(
        'workout_logs',
        log.toMap(),
        where: 'id = ?',
        whereArgs: [log.id],
      );
    } else {
      // Check if existing log exists for workout_id + date
      final existing = await db.query(
        'workout_logs',
        where: 'workout_id = ? AND date = ?',
        whereArgs: [log.workoutId, log.date],
      );
      if (existing.isNotEmpty) {
        final existingId = existing.first['id'] as int;
        final updatedLog = log.copyWith(id: existingId);
        await db.update(
          'workout_logs',
          updatedLog.toMap(),
          where: 'id = ?',
          whereArgs: [existingId],
        );
        return existingId;
      } else {
        return await db.insert('workout_logs', log.toMap());
      }
    }
  }
}
