import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todo_eisenhower/models/todo_model.dart';
import 'package:todo_eisenhower/services/database_helper.dart';
import 'package:todo_eisenhower/providers/todo_provider.dart';

void main() {
  // Initialize SQLite FFI for testing on desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() {
    // Set test path to in-memory database
    DatabaseHelper.testPath = inMemoryDatabasePath;
  });

  tearDown(() async {
    // Clean database after each test
    final db = await DatabaseHelper.instance.database;
    await db.delete('todos');
  });

  group('Todo Model Tests', () {
    test('toMap and fromMap Serialization', () {
      final now = DateTime.now();
      final todo = Todo(
        id: 42,
        title: '테스트 할 일',
        quadrant: 2,
        isCompleted: true,
        isTrash: false,
        dueDate: now.add(const Duration(days: 1)),
        createdAt: now,
        completedAt: now,
      );

      final map = todo.toMap();
      expect(map['id'], 42);
      expect(map['title'], '테스트 할 일');
      expect(map['quadrant'], 2);
      expect(map['is_completed'], 1);
      expect(map['is_trash'], 0);
      expect(map['due_date'], todo.dueDate!.toIso8601String());

      final parsed = Todo.fromMap(map);
      expect(parsed.id, todo.id);
      expect(parsed.title, todo.title);
      expect(parsed.quadrant, todo.quadrant);
      expect(parsed.isCompleted, todo.isCompleted);
      expect(parsed.isTrash, todo.isTrash);
      expect(parsed.dueDate, todo.dueDate);
    });
  });

  group('DatabaseHelper & Q4 Incinerator Tests', () {
    test('Insert and Fetch Todos', () async {
      final dbHelper = DatabaseHelper.instance;

      final todo = Todo(
        title: 'Q1 즉시 실행 업무',
        quadrant: 1,
        createdAt: DateTime.now(),
      );

      final id = await dbHelper.insert(todo);
      expect(id, isNotNull);

      final list = await dbHelper.fetchAllActive();
      expect(list.length, 1);
      expect(list.first.title, 'Q1 즉시 실행 업무');
      expect(list.first.quadrant, 1);
    });

    test('Incinerator soft-deletes Q4 tasks older than 7 days', () async {
      final dbHelper = DatabaseHelper.instance;

      final now = DateTime.now();
      final eightDaysAgo = now.subtract(const Duration(days: 8));

      // 1. Insert Q4 task created 8 days ago
      final oldTodo = Todo(
        title: '8일 지난 Q4 업무',
        quadrant: 4,
        createdAt: eightDaysAgo,
      );
      final oldId = await dbHelper.insert(oldTodo);

      // 2. Insert Q4 task created today (should NOT be incinerated)
      final freshTodo = Todo(
        title: '오늘 작성한 Q4 업무',
        quadrant: 4,
        createdAt: now,
      );
      final freshId = await dbHelper.insert(freshTodo);

      // Verify they are active
      var activeList = await dbHelper.fetchAllActive();
      expect(activeList.length, 2);

      // 3. Run incinerator
      final count = await dbHelper.incinerateOldQ4Tasks();
      expect(count, 1); // 1 item should be incinerated

      // 4. Verify list changes
      activeList = await dbHelper.fetchAllActive();
      expect(activeList.length, 1);
      expect(activeList.first.id, freshId); // Only the fresh one remains active

      final trashList = await dbHelper.fetchTrash();
      expect(trashList.length, 1);
      expect(trashList.first.id, oldId); // The old one is in trash
      expect(trashList.first.isTrash, isTrue);
      expect(trashList.first.deletedAt, isNotNull);
    });
  });

  group('TodoProvider State Tests', () {
    test('Add and toggle todo', () async {
      final provider = TodoProvider();
      await provider.loadTodos();

      expect(provider.todos.isEmpty, isTrue);

      await provider.addTodo('신규 할 일', 3);
      expect(provider.todos.length, 1);
      expect(provider.todos.first.title, '신규 할 일');
      expect(provider.todos.first.quadrant, 3);
      expect(provider.todos.first.isCompleted, isFalse);

      await provider.toggleTodoCompletion(provider.todos.first);
      expect(provider.todos.first.isCompleted, isTrue);
    });
  });
}
