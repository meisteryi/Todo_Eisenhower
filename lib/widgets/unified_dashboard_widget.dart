import 'package:flutter/material.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';

class UnifiedDashboardWidget extends StatefulWidget {
  final TodoProvider provider;

  const UnifiedDashboardWidget({super.key, required this.provider});

  @override
  State<UnifiedDashboardWidget> createState() => _UnifiedDashboardWidgetState();
}

class _UnifiedDashboardWidgetState extends State<UnifiedDashboardWidget> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = widget.provider;

    // Todo counts
    final q1Count = provider.getQuadrantTodos(1).length;
    final q2Count = provider.getQuadrantTodos(2).length;
    final q3Count = provider.getQuadrantTodos(3).length;
    final q4Count = provider.getQuadrantTodos(4).length;
    final totalPendingTodos = q1Count + q2Count + q3Count + q4Count;

    // Workout stats
    final workouts = provider.workouts;
    final todayLogs = provider.todayWorkoutLogs;
    final streak = provider.workoutStreak;
    final totalWorkouts = workouts.length;
    final completedWorkouts = workouts.where((w) => todayLogs[w.id]?.isCompleted ?? false).length;
    final isWorkoutAllDone = totalWorkouts > 0 && completedWorkouts == totalWorkouts;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Widget Header Bar
          InkWell(
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text('📊', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    '오늘의 스마트 대시보드',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.q2.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🔥 $streak일',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.q2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: theme.hintColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Content Body
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Left Half: Eisenhower Quadrant Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.grid_view, size: 14, color: AppColors.q1),
                            const SizedBox(width: 4),
                            Text(
                              '할 일 ($totalPendingTodos)',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 2.2,
                          children: [
                            _buildQuadrantBadge('Q1 긴급/중요', q1Count, AppColors.q1),
                            _buildQuadrantBadge('Q2 목표/계획', q2Count, AppColors.q2),
                            _buildQuadrantBadge('Q3 대리/위임', q3Count, AppColors.q3),
                            _buildQuadrantBadge('Q4 휴식/소각', q4Count, AppColors.q4),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                    height: 90,
                    width: 1,
                    color: theme.dividerColor.withValues(alpha: 0.15),
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                  ),

                  // Right Half: Daily Workout Progress
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.fitness_center, size: 14, color: AppColors.q2),
                            const SizedBox(width: 4),
                            const Text(
                              '운동 (오운완)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isWorkoutAllDone
                                ? const Color(0xFF2ECC71).withValues(alpha: 0.1)
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isWorkoutAllDone ? '🎉 완벽 달성' : '$completedWorkouts / $totalWorkouts 완료',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isWorkoutAllDone ? const Color(0xFF2ECC71) : null,
                                    ),
                                  ),
                                  Text(
                                    totalWorkouts > 0
                                        ? '${((completedWorkouts / totalWorkouts) * 100).toInt()}%'
                                        : '0%',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: totalWorkouts > 0 ? (completedWorkouts / totalWorkouts) : 0.0,
                                  minHeight: 6,
                                  backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isWorkoutAllDone ? const Color(0xFF2ECC71) : AppColors.q2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuadrantBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
