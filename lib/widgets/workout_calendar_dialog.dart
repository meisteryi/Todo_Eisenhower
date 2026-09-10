import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month, 1);
    });
    widget.provider.setSelectedDate(now);
    _loadMonthData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    final firstOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstDisplayDate = firstOfMonth.subtract(Duration(days: firstOfMonth.weekday - 1));
    final lastDisplayDate = lastOfMonth.add(Duration(days: 7 - lastOfMonth.weekday));

    final totalDays = lastDisplayDate.difference(firstDisplayDate).inDays + 1;
    final weeks = <List<DateTime>>[];
    for (int i = 0; i < totalDays; i += 7) {
      weeks.add(
        List.generate(7, (index) => firstDisplayDate.add(Duration(days: i + index))),
      );
    }

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

    final isCurrentMonthShowing = _currentMonth.year == now.year && _currentMonth.month == now.month;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: AppColors.q2, size: 22),
                    SizedBox(width: 8),
                    Text(
                      '운동 캘린더',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (!isCurrentMonthShowing)
                      GestureDetector(
                        onTap: _jumpToToday,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.q2.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '이번 달',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.q2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Month Navigator Capsule
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 22),
                    onPressed: () => _changeMonth(-1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Text(
                    DateFormat('yyyy년 M월', 'ko').format(_currentMonth),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 22),
                    onPressed: () => _changeMonth(1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Weekdays Row
            Row(
              children: ['월', '화', '수', '목', '금', '토', '일'].map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: day == '일'
                            ? Colors.redAccent
                            : (day == '토'
                                ? Colors.blueAccent
                                : (isDark ? Colors.grey[400] : Colors.grey[600])),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // Weeks & Days Grid
            ...weeks.map((week) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: week.map((day) {
                    final isOutside = day.month != _currentMonth.month;
                    final dateStr = DateFormat('yyyy-MM-dd').format(day);
                    final dayLogs = logsByDate[dateStr] ?? [];
                    final hasCompleted = dayLogs.any((l) => l.isCompleted);

                    final isToday = day.year == now.year &&
                        day.month == now.month &&
                        day.day == now.day;

                    final isSelectedDate = day.year == widget.provider.selectedDate.year &&
                        day.month == widget.provider.selectedDate.month &&
                        day.day == widget.provider.selectedDate.day;

                    Color bgColor;
                    if (isSelectedDate) {
                      bgColor = AppColors.q2;
                    } else if (hasCompleted && !isOutside) {
                      bgColor = AppColors.q2.withValues(alpha: 0.15);
                    } else if (isToday) {
                      bgColor = isDark
                          ? AppColors.q2.withValues(alpha: 0.12)
                          : AppColors.q2.withValues(alpha: 0.08);
                    } else {
                      bgColor = isDark ? AppColors.darkInputBg : AppColors.lightInputBg;
                    }

                    Color textColor;
                    if (isSelectedDate) {
                      textColor = Colors.white;
                    } else if (isOutside) {
                      textColor = theme.hintColor.withValues(alpha: 0.35);
                    } else if (hasCompleted) {
                      textColor = AppColors.q2;
                    } else if (day.weekday == 7) {
                      textColor = Colors.redAccent;
                    } else if (day.weekday == 6) {
                      textColor = Colors.blueAccent;
                    } else {
                      textColor = isDark ? Colors.white70 : Colors.black87;
                    }

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: InkWell(
                          onTap: () {
                            widget.provider.setSelectedDate(day);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: isOutside && !isSelectedDate ? Colors.transparent : bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: isToday && !isSelectedDate
                                  ? Border.all(color: AppColors.q2, width: 1.5)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isToday || hasCompleted || isSelectedDate
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                if (hasCompleted && !isOutside)
                                  Text(
                                    '🔥',
                                    style: TextStyle(
                                      fontSize: isSelectedDate ? 11 : 10,
                                    ),
                                  )
                                else if (isToday && !isOutside && !isSelectedDate)
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: AppColors.q2,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                                else
                                  const SizedBox(height: 4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
            const SizedBox(height: 14),

            // Summary Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.q2.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: AppColors.q2, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '이번 달 총 $completedDaysCount일 오운완 달성! 🎉',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '날짜를 탭하면 해당 일자의 운동 기록으로 이동합니다.',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.hintColor,
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
    );
  }
}
