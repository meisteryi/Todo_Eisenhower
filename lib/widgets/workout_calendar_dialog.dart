import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';

class WorkoutCalendarDialog extends StatefulWidget {
  final TodoProvider provider;

  const WorkoutCalendarDialog({super.key, required this.provider});

  @override
  State<WorkoutCalendarDialog> createState() => _WorkoutCalendarDialogState();
}

class _WorkoutCalendarDialogState extends State<WorkoutCalendarDialog> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(
      widget.provider.selectedDate.year,
      widget.provider.selectedDate.month,
      1,
    );
    _loadMonthData();
  }

  void _loadMonthData() {
    final yyyyMM = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}';
    widget.provider.loadMonthlyWorkoutLogs(yyyyMM);
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
    });
    _loadMonthData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday; // 1=Mon, 7=Sun

    final Map<String, List<WorkoutLog>> logsByDate = {};
    for (var log in widget.provider.monthlyWorkoutLogs) {
      logsByDate.putIfAbsent(log.date, () => []).add(log);
    }

    int completedDaysCount = 0;
    logsByDate.forEach((date, logs) {
      if (logs.any((l) => l.isCompleted)) {
        completedDaysCount++;
      }
    });

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📅 월간 오운완 캘린더',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Month Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  '${_currentMonth.year}년 ${_currentMonth.month}월',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Weekday Labels
            Row(
              children: ['월', '화', '수', '목', '금', '토', '일'].map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: day == '일' ? Colors.redAccent : (day == '토' ? Colors.blueAccent : theme.hintColor),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // Days Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42, // 6 rows * 7 days
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemBuilder: (context, index) {
                final dayNum = index - (firstWeekday - 1) + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const SizedBox.shrink();
                }

                final dateStr = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                final dayLogs = logsByDate[dateStr] ?? [];
                final hasCompleted = dayLogs.any((l) => l.isCompleted);

                final now = DateTime.now();
                final isToday = _currentMonth.year == now.year &&
                    _currentMonth.month == now.month &&
                    dayNum == now.day;

                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hasCompleted
                        ? AppColors.q2.withValues(alpha: 0.15)
                        : (isToday ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4) : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: isToday
                        ? Border.all(color: AppColors.q2, width: 1.5)
                        : Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday || hasCompleted ? FontWeight.bold : FontWeight.normal,
                          color: hasCompleted ? AppColors.q2 : theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      if (hasCompleted)
                        const Text(
                          '🔥',
                          style: TextStyle(fontSize: 10),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.q2.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium, color: AppColors.q2),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '이번 달 총 $completedDaysCount일 오운완 달성! 🎉',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.q2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
