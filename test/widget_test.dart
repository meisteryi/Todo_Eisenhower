import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:todo_eisenhower/models/category_model.dart';
import 'package:todo_eisenhower/models/routine_model.dart';
import 'package:todo_eisenhower/models/todo_model.dart';
import 'package:todo_eisenhower/services/database_helper.dart';
import 'package:todo_eisenhower/providers/todo_provider.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() {
    DatabaseHelper.testPath = inMemoryDatabasePath;
  });

  tearDown(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('todos');
    await db.delete('categories');
    await db.delete('routines');
  });

  group('Todo & Category & Routine Model Tests', () {
    test('Category default list & serialization', () {
      final defaults = Category.defaultCategories();
      expect(defaults.length, 4);

      final cat = Category(
        id: 10,
        name: '운동',
        colorHex: '#2ECC71',
        emoji: '💪',
      );
      final map = cat.toMap();
      expect(map['name'], '운동');
      expect(map['color_hex'], '#2ECC71');

      final parsed = Category.fromMap(map);
      expect(parsed.name, '운동');
      expect(parsed.emoji, '💪');
    });

    test('Routine recurrence logic', () {
      final dailyRoutine = Routine(
        title: '매일 영양제',
        repeatType: 'daily',
        repeatDays: '1,2,3,4,5,6,7',
        startDate: DateTime(2026, 1, 1),
      );

      final weeklyRoutine = Routine(
        title: '월수금 수영',
        repeatType: 'weekly',
        repeatDays: '1,3,5', // Mon, Wed, Fri
        startDate: DateTime(2026, 1, 1),
      );

      final monday = DateTime(2026, 9, 7); // Monday (weekday = 1)
      final tuesday = DateTime(2026, 9, 8); // Tuesday (weekday = 2)

      expect(dailyRoutine.shouldOccurOn(monday), isTrue);
      expect(dailyRoutine.shouldOccurOn(tuesday), isTrue);

      expect(weeklyRoutine.shouldOccurOn(monday), isTrue);
      expect(weeklyRoutine.shouldOccurOn(tuesday), isFalse);
    });
  });

  group('DatabaseHelper & Q4 Incinerator Tests', () {
    test('Insert and Fetch Categories', () async {
      final dbHelper = DatabaseHelper.instance;

      final categories = await dbHelper.fetchCategories();
      expect(categories.length, greaterThanOrEqualTo(4));
    });

    test('Incinerator soft-deletes Q4 tasks older than 7 days', () async {
      final dbHelper = DatabaseHelper.instance;

      final now = DateTime.now();
      final eightDaysAgo = now.subtract(const Duration(days: 8));

      final oldTodo = Todo(
        title: '8일 지난 Q4 업무',
        quadrant: 4,
        createdAt: eightDaysAgo,
      );
      final oldId = await dbHelper.insert(oldTodo);

      final freshTodo = Todo(
        title: '오늘 작성한 Q4 업무',
        quadrant: 4,
        createdAt: now,
      );
      final freshId = await dbHelper.insert(freshTodo);

      var activeList = await dbHelper.fetchAllActive();
      expect(activeList.length, 2);

      final count = await dbHelper.incinerateOldQ4Tasks();
      expect(count, 1);

      activeList = await dbHelper.fetchAllActive();
      expect(activeList.length, 1);
      expect(activeList.first.id, freshId);

      final trashList = await dbHelper.fetchTrash();
      expect(trashList.length, 1);
      expect(trashList.first.id, oldId);
    });
  });

  group('TodoProvider State Tests', () {
    test('Category and Routine management', () async {
      final provider = TodoProvider();
      await provider.loadTodos();

      expect(provider.categories.isNotEmpty, isTrue);

      await provider.addCategory('독서', '#9B59B6', '📚');
      expect(provider.categories.any((c) => c.name == '독서'), isTrue);

      await provider.addRoutine(
        title: '독서 30분',
        categoryId: provider.categories.last.id,
        repeatType: 'daily',
        repeatDays: '1,2,3,4,5,6,7',
        startDate: DateTime.now(),
      );

      expect(provider.routines.length, 1);
      expect(provider.routines.first.title, '독서 30분');
    });
  });
}
