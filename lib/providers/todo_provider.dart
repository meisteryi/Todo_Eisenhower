import 'dart:async';
import 'package:flutter/material.dart';
import '../models/todo_model.dart';
import '../services/database_helper.dart';

class TodoProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Todo> _todos = [];
  List<Todo> _trashTodos = [];
  bool _isLoading = true;
  int _activeQuadrant = 1; // 1 to 4
  int _lastIncineratedCount = 0;

  // Pomodoro Focus Timer State
  int? _pomodoroTodoId;
  int _pomodoroSecondsRemaining = 25 * 60; // default 25 minutes
  bool _isTimerRunning = false;
  Timer? _pomodoroTimer;

  // Getters
  List<Todo> get todos => _todos;
  List<Todo> get trashTodos => _trashTodos;
  bool get isLoading => _isLoading;
  int get activeQuadrant => _activeQuadrant;
  int get lastIncineratedCount => _lastIncineratedCount;

  // Quadrant filtered lists (only active, non-trash)
  List<Todo> get q0Todos => _todos.where((t) => t.quadrant == 0).toList();
  List<Todo> get q1Todos => _todos.where((t) => t.quadrant == 1).toList();
  List<Todo> get q2Todos => _todos.where((t) => t.quadrant == 2).toList();
  List<Todo> get q3Todos => _todos.where((t) => t.quadrant == 3).toList();
  List<Todo> get q4Todos => _todos.where((t) => t.quadrant == 4).toList();

  // Pomodoro getters
  int? get pomodoroTodoId => _pomodoroTodoId;
  int get pomodoroSecondsRemaining => _pomodoroSecondsRemaining;
  bool get isTimerRunning => _isTimerRunning;

  String get pomodoroTimeFormatted {
    final minutes = (_pomodoroSecondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_pomodoroSecondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Set active quadrant index (from swipe or minimap tap)
  void setActiveQuadrant(int quadrant) {
    if (quadrant >= 0 && quadrant <= 4) {
      _activeQuadrant = quadrant;
      notifyListeners();
    }
  }

  // Load active and trash todos from DB and run incinerator
  Future<void> loadTodos() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Run incineration of old Q4 items first
      _lastIncineratedCount = await _dbHelper.incinerateOldQ4Tasks();

      // 2. Fetch lists
      _todos = await _dbHelper.fetchAllActive();
      _trashTodos = await _dbHelper.fetchTrash();
    } catch (e) {
      debugPrint("Error loading todos: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset the incineration notification count
  void clearLastIncineratedCount() {
    _lastIncineratedCount = 0;
  }

  // Add todo
  Future<void> addTodo(String title, int quadrant, {DateTime? dueDate}) async {
    final newTodo = Todo(
      title: title,
      quadrant: quadrant,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );

    try {
      await _dbHelper.insert(newTodo);
      await loadTodos();
    } catch (e) {
      debugPrint("Error adding todo: $e");
    }
  }

  // Toggle completed status
  Future<void> toggleTodoCompletion(Todo todo) async {
    final updatedTodo = todo.copyWith(
      isCompleted: !todo.isCompleted,
      completedAt: !todo.isCompleted ? DateTime.now() : null,
    );

    try {
      await _dbHelper.update(updatedTodo);
      // If completed task is currently running in Pomodoro, stop the timer
      if (updatedTodo.isCompleted && _pomodoroTodoId == todo.id) {
        stopPomodoro();
      }
      await loadTodos();
    } catch (e) {
      debugPrint("Error updating todo completion: $e");
    }
  }

  // Move todo to another quadrant
  Future<void> moveTodo(Todo todo, int newQuadrant) async {
    if (newQuadrant < 0 || newQuadrant > 4) return;
    final updatedTodo = todo.copyWith(quadrant: newQuadrant);

    try {
      await _dbHelper.update(updatedTodo);
      await loadTodos();
    } catch (e) {
      debugPrint("Error moving todo: $e");
    }
  }

  // Update complete todo details (like due date)
  Future<void> updateTodo(Todo todo) async {
    try {
      await _dbHelper.update(todo);
      await loadTodos();
    } catch (e) {
      debugPrint("Error updating todo: $e");
    }
  }

  // Soft delete todo (move to trash)
  Future<void> softDeleteTodo(Todo todo) async {
    final updatedTodo = todo.copyWith(
      isTrash: true,
      deletedAt: DateTime.now(),
    );

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

  // Restore todo from trash
  Future<void> restoreTodo(Todo todo) async {
    final restoredTodo = Todo(
      id: todo.id,
      title: todo.title,
      quadrant: todo.quadrant,
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

  // Delete permanently
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

  // Clear trash bin
  Future<void> clearTrashBin() async {
    try {
      await _dbHelper.clearTrash();
      await loadTodos();
    } catch (e) {
      debugPrint("Error clearing trash bin: $e");
    }
  }

  // Pomodoro Focus Timer Logic
  void startPomodoro(int todoId) {
    if (_pomodoroTodoId == todoId && _isTimerRunning) return;

    if (_pomodoroTodoId != todoId) {
      _pomodoroTodoId = todoId;
      _pomodoroSecondsRemaining = 25 * 60; // reset to 25 mins for new task
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
        // Pomodoro complete!
        // Mark task as completed or notify
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
