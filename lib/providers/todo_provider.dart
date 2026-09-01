import 'dart:async';
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/routine_model.dart';
import '../models/todo_model.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

class TodoProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Todo> _todos = [];
  List<Todo> _trashTodos = [];
  List<Category> _categories = [];
  List<Routine> _routines = [];

  bool _isLoading = true;
  int _activeQuadrant = 1; // 1 to 4
  int _lastIncineratedCount = 0;

  // Selected date for Todo Mate calendar view
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  // Active Main View Mode: 'eisenhower', 'todomate', 'routines'
  String _activeViewMode = 'eisenhower';

  // Pomodoro Focus Timer State
  int? _pomodoroTodoId;
  int _pomodoroSecondsRemaining = 25 * 60; // default 25 minutes
  bool _isTimerRunning = false;
  Timer? _pomodoroTimer;

  // Getters
  List<Todo> get todos => _todos;
  List<Todo> get trashTodos => _trashTodos;
  List<Category> get categories => _categories;
  List<Routine> get routines => _routines;
  bool get isLoading => _isLoading;
  int get activeQuadrant => _activeQuadrant;
  int get lastIncineratedCount => _lastIncineratedCount;
  DateTime get selectedDate => _selectedDate;
  String get activeViewMode => _activeViewMode;

  // Matrix View Filter: false = 전체 사분면 (All), true = 오늘의 사분면 (Today Only)
  bool _isMatrixFilterTodayOnly = false;
  bool get isMatrixFilterTodayOnly => _isMatrixFilterTodayOnly;

  void setMatrixFilterTodayOnly(bool todayOnly) {
    _isMatrixFilterTodayOnly = todayOnly;
    notifyListeners();
  }

  // Get filtered Todos for a quadrant based on isMatrixFilterTodayOnly
  List<Todo> getQuadrantTodos(int q) {
    return _todos.where((t) {
      if (t.quadrant != q || t.isCompleted || t.isTrash) return false;
      if (!_isMatrixFilterTodayOnly) return true; // 전체 사분면

      // 오늘의 사분면 조건:
      // 1) targetDate가 선택된 날짜인 경우 (오늘 할 일)
      final isSameTargetDate = t.targetDate.year == _selectedDate.year &&
          t.targetDate.month == _selectedDate.month &&
          t.targetDate.day == _selectedDate.day;

      // 2) dueDate가 선택된 날짜 이전이거나 당일인 경우 (마감 임박/지연 과제)
      final isDueTodayOrPast = t.dueDate != null &&
          (t.dueDate!.isBefore(_selectedDate) ||
              (t.dueDate!.year == _selectedDate.year &&
                  t.dueDate!.month == _selectedDate.month &&
                  t.dueDate!.day == _selectedDate.day));

      return isSameTargetDate || isDueTodayOrPast;
    }).toList();
  }

  // Quadrant filtered lists (only active, non-trash)
  List<Todo> get q0Todos => getQuadrantTodos(0);
  List<Todo> get q1Todos => getQuadrantTodos(1);
  List<Todo> get q2Todos => getQuadrantTodos(2);
  List<Todo> get q3Todos => getQuadrantTodos(3);
  List<Todo> get q4Todos => getQuadrantTodos(4);

  // Pomodoro getters
  int? get pomodoroTodoId => _pomodoroTodoId;
  int get pomodoroSecondsRemaining => _pomodoroSecondsRemaining;
  bool get isTimerRunning => _isTimerRunning;

  String get pomodoroTimeFormatted {
    final minutes = (_pomodoroSecondsRemaining ~/ 60).toString().padLeft(
      2,
      '0',
    );
    final seconds = (_pomodoroSecondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Selected date's active todos
  List<Todo> get selectedDateTodos {
    return _todos.where((t) {
      return t.targetDate.year == _selectedDate.year &&
          t.targetDate.month == _selectedDate.month &&
          t.targetDate.day == _selectedDate.day;
    }).toList();
  }

  // Map of Todos for selected date grouped by Category ID
  Map<int?, List<Todo>> get todosGroupedByCategory {
    final map = <int?, List<Todo>>{};
    final dateTodos = selectedDateTodos;

    // Standard categories
    for (final cat in _categories) {
      map[cat.id] = [];
    }
    // Uncategorized
    map[null] = [];

    for (final todo in dateTodos) {
      if (map.containsKey(todo.categoryId)) {
        map[todo.categoryId]!.add(todo);
      } else {
        map[null]!.add(todo);
      }
    }
    return map;
  }

  // Set active view mode ('todomate', 'eisenhower', 'routines')
  void setViewMode(String mode) {
    if (['todomate', 'eisenhower', 'routines'].contains(mode)) {
      _activeViewMode = mode;
      notifyListeners();
    }
  }

  // Set selected date for calendar/date strip
  void setSelectedDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  // Set active quadrant index
  void setActiveQuadrant(int quadrant) {
    if (quadrant >= 0 && quadrant <= 4) {
      _activeQuadrant = quadrant;
      notifyListeners();
    }
  }

  // Load all data from DB
  Future<void> loadTodos() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Incinerate old Q4 items
      _lastIncineratedCount = await _dbHelper.incinerateOldQ4Tasks();

      // 2. Fetch categories and routines
      _categories = await _dbHelper.fetchCategories();
      _routines = await _dbHelper.fetchRoutines();

      // 3. Fetch todos
      _todos = await _dbHelper.fetchAllActive();
      _trashTodos = await _dbHelper.fetchTrash();

      // 4. Schedule local notifications for active todos
      for (final todo in _todos) {
        if (todo.hasNotification && !todo.isCompleted) {
          NotificationService().scheduleTodoNotification(todo);
        }
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if active routines exist for a date (manual addition mode)
  List<Routine> getPendingRoutinesForDate(DateTime date) {
    final targetDateOnly = DateTime(date.year, date.month, date.day);
    return _routines.where((routine) {
      if (!routine.shouldOccurOn(targetDateOnly)) return false;
      final alreadyAdded = _todos.any(
        (t) =>
            t.routineId == routine.id &&
            t.targetDate.year == targetDateOnly.year &&
            t.targetDate.month == targetDateOnly.month &&
            t.targetDate.day == targetDateOnly.day,
      );
      return !alreadyAdded;
    }).toList();
  }

  Future<void> instantiateRoutineAsTodo(Routine routine, [DateTime? date]) async {
    final targetDateOnly = date ?? _selectedDate;
    final newTodo = Todo(
      title: routine.title,
      quadrant: routine.quadrant,
      categoryId: routine.categoryId,
      routineId: routine.id,
      targetDate: DateTime(
        targetDateOnly.year,
        targetDateOnly.month,
        targetDateOnly.day,
      ),
      dueDate: routine.endDate,
      createdAt: DateTime.now(),
      location: routine.location,
      timeStr: routine.timeStr,
      dueTimeStr: routine.dueTimeStr,
      memo: routine.memo,
      hasNotification: routine.hasNotification,
      notificationOffset: routine.notificationOffset,
    );

    try {
      await _dbHelper.insert(newTodo);
      await loadTodos();
    } catch (e) {
      debugPrint("Error instantiating routine: $e");
    }
  }

  void clearLastIncineratedCount() {
    _lastIncineratedCount = 0;
    notifyListeners();
  }

  // Add Todo
  Future<void> addTodo(
    String title,
    int quadrant, {
    int? categoryId,
    DateTime? targetDate,
    DateTime? dueDate,
    String? location,
    String? timeStr,
    String? dueTimeStr,
    String? memo,
    bool hasNotification = false,
    int notificationOffset = 0,
  }) async {
    final todoTargetDate = targetDate ?? _selectedDate;
    final newTodo = Todo(
      title: title,
      quadrant: quadrant,
      categoryId: categoryId,
      targetDate: DateTime(
        todoTargetDate.year,
        todoTargetDate.month,
        todoTargetDate.day,
      ),
      dueDate: dueDate,
      createdAt: DateTime.now(),
      location: location,
      timeStr: timeStr,
      dueTimeStr: dueTimeStr,
      memo: memo,
      hasNotification: hasNotification,
      notificationOffset: notificationOffset,
    );

    try {
      await _dbHelper.insert(newTodo);
      await loadTodos();
    } catch (e) {
      debugPrint("Error adding todo: $e");
    }
  }

  // Toggle completion
  Future<void> toggleTodoCompletion(Todo todo) async {
    final updatedTodo = todo.copyWith(
      isCompleted: !todo.isCompleted,
      completedAt: !todo.isCompleted ? DateTime.now() : null,
    );

    try {
      await _dbHelper.update(updatedTodo);
      if (updatedTodo.isCompleted && _pomodoroTodoId == todo.id) {
        stopPomodoro();
      }
      await loadTodos();
    } catch (e) {
      debugPrint("Error updating todo completion: $e");
    }
  }

  // Move todo quadrant
  Future<void> moveTodo(Todo todo, int newQuadrant) async {
    if (newQuadrant < 0 || newQuadrant > 4) return;

    // Reset createdAt to now when entering Q4 so 7-day incineration countdown starts from entry moment
    final shouldResetTimer = newQuadrant == 4 && todo.quadrant != 4;
    final updatedTodo = todo.copyWith(
      quadrant: newQuadrant,
      createdAt: shouldResetTimer ? DateTime.now() : todo.createdAt,
    );

    try {
      await _dbHelper.update(updatedTodo);
      await loadTodos();
    } catch (e) {
      debugPrint("Error moving todo: $e");
    }
  }

  // Update complete todo
  Future<void> updateTodo(Todo todo) async {
    try {
      await _dbHelper.update(todo);
      await loadTodos();
    } catch (e) {
      debugPrint("Error updating todo: $e");
    }
  }

  // Reorder todos within quadrant
  Future<void> reorderTodos(int quadrant, int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    List<Todo> quadrantTodos;
    switch (quadrant) {
      case 0:
        quadrantTodos = q0Todos;
        break;
      case 1:
        quadrantTodos = q1Todos;
        break;
      case 2:
        quadrantTodos = q2Todos;
        break;
      case 3:
        quadrantTodos = q3Todos;
        break;
      case 4:
        quadrantTodos = q4Todos;
        break;
      default:
        return;
    }

    if (oldIndex < 0 || oldIndex >= quadrantTodos.length) return;
    if (newIndex < 0 || newIndex >= quadrantTodos.length) return;

    final reorderedList = List<Todo>.from(quadrantTodos);
    final movedTodo = reorderedList.removeAt(oldIndex);
    reorderedList.insert(newIndex, movedTodo);

    final now = DateTime.now();
    try {
      for (int i = 0; i < reorderedList.length; i++) {
        final todo = reorderedList[i];
        final newCreatedAt = now.subtract(Duration(seconds: i * 2));
        final updatedTodo = todo.copyWith(createdAt: newCreatedAt);
        await _dbHelper.update(updatedTodo);
      }
      await loadTodos();
    } catch (e) {
      debugPrint("Error reordering todos: $e");
    }
  }

  // Soft delete
  Future<void> softDeleteTodo(Todo todo) async {
    final updatedTodo = todo.copyWith(isTrash: true, deletedAt: DateTime.now());

    try {
      await _dbHelper.update(updatedTodo);
      if (_pomodoroTodoId == todo.id) {
        stopPomodoro();
      }
      await loadTodos();
    } catch (e) {
      debugPrint("Error soft deleting todo: $e");
    }
  }

  // Restore
  Future<void> restoreTodo(Todo todo) async {
    final restoredTodo = Todo(
      id: todo.id,
      title: todo.title,
      quadrant: todo.quadrant,
      categoryId: todo.categoryId,
      routineId: todo.routineId,
      targetDate: todo.targetDate,
      isCompleted: todo.isCompleted,
      isTrash: false,
      dueDate: todo.dueDate,
      createdAt: todo.createdAt,
      completedAt: todo.completedAt,
    );

    try {
      await _dbHelper.update(restoredTodo);
      await loadTodos();
    } catch (e) {
      debugPrint("Error restoring todo: $e");
    }
  }

  // Permanent Delete
  Future<void> deleteTodoPermanently(int id) async {
    try {
      await _dbHelper.deletePermanently(id);
      if (_pomodoroTodoId == id) {
        stopPomodoro();
      }
      await loadTodos();
    } catch (e) {
      debugPrint("Error permanently deleting todo: $e");
    }
  }

  // Clear Trash
  Future<void> clearTrashBin() async {
    try {
      await _dbHelper.clearTrash();
      await loadTodos();
    } catch (e) {
      debugPrint("Error clearing trash bin: $e");
    }
  }

  // --- CATEGORY OPERATIONS ---

  Future<void> addCategory(String name, String colorHex, String emoji) async {
    final maxSortOrder = _categories.fold<int>(
      0,
      (max, c) => c.sortOrder > max ? c.sortOrder : max,
    );
    final category = Category(
      name: name,
      colorHex: colorHex,
      emoji: emoji,
      sortOrder: maxSortOrder + 1,
    );

    try {
      await _dbHelper.insertCategory(category);
      await loadTodos();
    } catch (e) {
      debugPrint("Error adding category: $e");
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await _dbHelper.updateCategory(category);
      await loadTodos();
    } catch (e) {
      debugPrint("Error updating category: $e");
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _dbHelper.deleteCategory(id);
      await loadTodos();
    } catch (e) {
      debugPrint("Error deleting category: $e");
    }
  }

  // --- ROUTINE OPERATIONS ---

  Future<void> addRoutine({
    required String title,
    int quadrant = 1,
    int? categoryId,
    required String repeatType,
    required String repeatDays,
    required DateTime startDate,
    DateTime? endDate,
    String? location,
    String? timeStr,
    String? dueTimeStr,
    String? memo,
    bool hasNotification = false,
    int notificationOffset = 0,
  }) async {
    final routine = Routine(
      title: title,
      quadrant: quadrant,
      categoryId: categoryId,
      repeatType: repeatType,
      repeatDays: repeatDays,
      startDate: startDate,
      endDate: endDate,
      location: location,
      timeStr: timeStr,
      dueTimeStr: dueTimeStr,
      memo: memo,
      hasNotification: hasNotification,
      notificationOffset: notificationOffset,
      isActive: true,
    );

    try {
      await _dbHelper.insertRoutine(routine);
      await loadTodos();
    } catch (e) {
      debugPrint("Error adding routine: $e");
    }
  }

  Future<void> toggleRoutineActive(Routine routine) async {
    final updated = routine.copyWith(isActive: !routine.isActive);
    try {
      await _dbHelper.updateRoutine(updated);
      await loadTodos();
    } catch (e) {
      debugPrint("Error toggling routine: $e");
    }
  }

  Future<void> deleteRoutine(int id) async {
    try {
      await _dbHelper.deleteRoutine(id);
      await loadTodos();
    } catch (e) {
      debugPrint("Error deleting routine: $e");
    }
  }

  // --- POMODORO TIMER LOGIC ---

  void startPomodoro(int todoId) {
    if (_pomodoroTodoId == todoId && _isTimerRunning) return;

    if (_pomodoroTodoId != todoId) {
      _pomodoroTodoId = todoId;
      _pomodoroSecondsRemaining = 25 * 60;
    }

    _isTimerRunning = true;
    _pomodoroTimer?.cancel();
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_pomodoroSecondsRemaining > 0) {
        _pomodoroSecondsRemaining--;
        notifyListeners();
      } else {
        _isTimerRunning = false;
        timer.cancel();
        final todoIndex = _todos.indexWhere((t) => t.id == _pomodoroTodoId);
        if (todoIndex != -1) {
          toggleTodoCompletion(_todos[todoIndex]);
        }
        _pomodoroTodoId = null;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void pausePomodoro() {
    _isTimerRunning = false;
    _pomodoroTimer?.cancel();
    notifyListeners();
  }

  void stopPomodoro() {
    _isTimerRunning = false;
    _pomodoroTimer?.cancel();
    _pomodoroTodoId = null;
    _pomodoroSecondsRemaining = 25 * 60;
    notifyListeners();
  }

  @override
  void dispose() {
    _pomodoroTimer?.cancel();
    super.dispose();
  }
}
