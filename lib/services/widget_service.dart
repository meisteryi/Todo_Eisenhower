import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import '../models/todo_model.dart';
import '../models/workout_model.dart';

class WidgetService {
  static final WidgetService instance = WidgetService._internal();

  WidgetService._internal();

  static const String appGroupId = 'group.com.example.todo_eisenhower';
  static const String androidWidgetName = 'TodoWidgetProvider';
  static const String androidTasksWidgetName = 'TodoTasksWidgetProvider';
  static const String iOSWidgetName = 'TodoWidgetProvider';
  static const String iOSTasksWidgetName = 'TodoTasksWidgetProvider';

  Future<void> updateHomeScreenWidget({
    required List<Todo> todos,
    required List<Workout> workouts,
    required Map<int, WorkoutLog> workoutLogs,
    required int streak,
  }) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      final activeTodos = todos.where((t) => !t.isCompleted && !t.isTrash).toList();
      final q1Todos = activeTodos.where((t) => t.quadrant == 1).toList();
      final q2Todos = activeTodos.where((t) => t.quadrant == 2).toList();
      final q3Count = activeTodos.where((t) => t.quadrant == 3).length;
      final q4Count = activeTodos.where((t) => t.quadrant == 4).length;

      final totalWorkouts = workouts.length;
      final completedWorkouts = workouts.where((w) => workoutLogs[w.id]?.isCompleted ?? false).length;

      // Extract top titles for Q1 & Q2
      final q1Title1 = q1Todos.isNotEmpty ? q1Todos[0].title : '';
      final q1Title2 = q1Todos.length > 1 ? q1Todos[1].title : '';
      final q1Title3 = q1Todos.length > 2 ? q1Todos[2].title : '';

      final q2Title1 = q2Todos.isNotEmpty ? q2Todos[0].title : '';
      final q2Title2 = q2Todos.length > 1 ? q2Todos[1].title : '';
      final q2Title3 = q2Todos.length > 2 ? q2Todos[2].title : '';

      final payload = {
        'q1_count': q1Todos.length,
        'q2_count': q2Todos.length,
        'q3_count': q3Count,
        'q4_count': q4Count,
        'total_pending_todos': activeTodos.length,
        'workout_streak': streak,
        'workout_completed': completedWorkouts,
        'workout_total': totalWorkouts,
        'q1_title_1': q1Title1,
        'q1_title_2': q1Title2,
        'q1_title_3': q1Title3,
        'q2_title_1': q2Title1,
        'q2_title_2': q2Title2,
        'q2_title_3': q2Title3,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await HomeWidget.saveWidgetData<int>('q1_count', q1Todos.length);
      await HomeWidget.saveWidgetData<int>('q2_count', q2Todos.length);
      await HomeWidget.saveWidgetData<int>('q3_count', q3Count);
      await HomeWidget.saveWidgetData<int>('q4_count', q4Count);
      await HomeWidget.saveWidgetData<int>('total_pending', activeTodos.length);
      await HomeWidget.saveWidgetData<int>('workout_streak', streak);
      await HomeWidget.saveWidgetData<int>('workout_completed', completedWorkouts);
      await HomeWidget.saveWidgetData<int>('workout_total', totalWorkouts);

      await HomeWidget.saveWidgetData<String>('q1_title_1', q1Title1);
      await HomeWidget.saveWidgetData<String>('q1_title_2', q1Title2);
      await HomeWidget.saveWidgetData<String>('q1_title_3', q1Title3);
      await HomeWidget.saveWidgetData<String>('q2_title_1', q2Title1);
      await HomeWidget.saveWidgetData<String>('q2_title_2', q2Title2);
      await HomeWidget.saveWidgetData<String>('q2_title_3', q2Title3);

      await HomeWidget.saveWidgetData<String>('widget_payload_json', jsonEncode(payload));

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );

      await HomeWidget.updateWidget(
        name: androidTasksWidgetName,
        androidName: androidTasksWidgetName,
        iOSName: iOSTasksWidgetName,
      );
    } catch (e) {
      debugPrint('Error updating HomeWidget: $e');
    }
  }
}
