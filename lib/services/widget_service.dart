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
  static const String iOSWidgetName = 'TodoWidgetProvider';

  Future<void> updateHomeScreenWidget({
    required List<Todo> todos,
    required List<Workout> workouts,
    required Map<int, WorkoutLog> workoutLogs,
    required int streak,
  }) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      final activeTodos = todos.where((t) => !t.isCompleted && !t.isTrash).toList();
      final q1Count = activeTodos.where((t) => t.quadrant == 1).length;
      final q2Count = activeTodos.where((t) => t.quadrant == 2).length;
      final q3Count = activeTodos.where((t) => t.quadrant == 3).length;
      final q4Count = activeTodos.where((t) => t.quadrant == 4).length;

      final totalWorkouts = workouts.length;
      final completedWorkouts = workouts.where((w) => workoutLogs[w.id]?.isCompleted ?? false).length;

      final payload = {
        'q1_count': q1Count,
        'q2_count': q2Count,
        'q3_count': q3Count,
        'q4_count': q4Count,
        'total_pending_todos': activeTodos.length,
        'workout_streak': streak,
        'workout_completed': completedWorkouts,
        'workout_total': totalWorkouts,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await HomeWidget.saveWidgetData<int>('q1_count', q1Count);
      await HomeWidget.saveWidgetData<int>('total_pending', activeTodos.length);
      await HomeWidget.saveWidgetData<int>('workout_streak', streak);
      await HomeWidget.saveWidgetData<int>('workout_completed', completedWorkouts);
      await HomeWidget.saveWidgetData<int>('workout_total', totalWorkouts);
      await HomeWidget.saveWidgetData<String>('widget_payload_json', jsonEncode(payload));

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (e) {
      debugPrint('Error updating HomeWidget: $e');
    }
  }
}
