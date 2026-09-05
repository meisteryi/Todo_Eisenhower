import 'package:flutter/material.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';
import 'workout_calendar_dialog.dart';

class WorkoutDashboardWidget extends StatelessWidget {
  final TodoProvider provider;

  const WorkoutDashboardWidget({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workouts = provider.workouts;
    final todayLogs = provider.todayWorkoutLogs;
    final streak = provider.workoutStreak;

    final totalCount = workouts.length;
    final completedCount = workouts.where((w) => todayLogs[w.id]?.isCompleted ?? false).length;
    final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;
    final isAllDone = totalCount > 0 && completedCount == totalCount;

    final uncompletedWorkouts = workouts.where((w) => !(todayLogs[w.id]?.isCompleted ?? false)).toList();
    final nextWorkout = uncompletedWorkouts.isNotEmpty ? uncompletedWorkouts.first : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: isAllDone
          ? const Color(0xFF2ECC71).withValues(alpha: 0.12)
          : AppColors.q2.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top Row: Streak Badge & Calendar Launcher
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isAllDone ? const Color(0xFF2ECC71) : AppColors.q2,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            '연속 $streak일째 오운완!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month_outlined, size: 20),
                  tooltip: '월간 캘린더 보기',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => WorkoutCalendarDialog(provider: provider),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Middle Section: Progress Circle & Status
            Row(
              children: [
                // Circular Progress Indicator
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                        color: isAllDone ? const Color(0xFF2ECC71) : AppColors.q2,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Status text & Progress info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAllDone ? '🎉 오늘 운동 완벽 달성!' : '오늘의 운동 현황',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '총 $totalCount개 중 $completedCount개 완료',
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Next Workout Quick Preview (if available)
            if (nextWorkout != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Text(nextWorkout.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '다음 운동: ${nextWorkout.title}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            '${nextWorkout.category} • ${nextWorkout.workoutType == 'set' ? '${nextWorkout.targetSets}세트' : '${nextWorkout.targetMinutes}분'}',
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: AppColors.q2, size: 22),
                      onPressed: () {
                        provider.toggleWorkoutCompletion(nextWorkout);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
