import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/todo_provider.dart';

class DateStripHeader extends StatelessWidget {
  final TodoProvider provider;

  const DateStripHeader({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = provider.selectedDate;

    final monday = selected.subtract(Duration(days: selected.weekday - 1));
    final weekDays = List.generate(
      7,
      (index) => monday.add(Duration(days: index)),
    );

    final monthFormat = DateFormat('yyyy년 M월', 'ko');
    final isTodaySelected =
        selected.year == DateTime.now().year &&
        selected.month == DateTime.now().month &&
        selected.day == DateTime.now().day;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Month navigation header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    monthFormat.format(selected),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isTodaySelected)
                    GestureDetector(
                      onTap: () {
                        provider.setSelectedDate(DateTime.now());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '오늘',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: () {
                      provider.setSelectedDate(
                        selected.subtract(const Duration(days: 7)),
                      );
                    },
                    tooltip: '이전 주',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selected,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        provider.setSelectedDate(picked);
                      }
                    },
                    tooltip: '달력에서 선택',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: () {
                      provider.setSelectedDate(
                        selected.add(const Duration(days: 7)),
                      );
                    },
                    tooltip: '다음 주',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 7-day strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((day) {
              final isSelected =
                  day.year == selected.year &&
                  day.month == selected.month &&
                  day.day == selected.day;
              final isToday =
                  day.year == DateTime.now().year &&
                  day.month == DateTime.now().month &&
                  day.day == DateTime.now().day;

              final dayTodos = provider.todos
                  .where(
                    (t) =>
                        t.targetDate.year == day.year &&
                        t.targetDate.month == day.month &&
                        t.targetDate.day == day.day,
                  )
                  .toList();
              final hasCompleted = dayTodos.any((t) => t.isCompleted);
              final totalCount = dayTodos.length;

              final weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
              final dayName = weekdayNames[day.weekday - 1];

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    provider.setSelectedDate(day);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isToday
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  )
                                : Colors.transparent),
                      borderRadius: BorderRadius.circular(16),
                      border: isToday && !isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.4,
                              ),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : (day.weekday == 7
                                      ? Colors.red
                                      : (day.weekday == 6
                                            ? Colors.blue
                                            : theme.textTheme.bodyMedium?.color
                                                  ?.withValues(alpha: 0.7))),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (totalCount > 0)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : (hasCompleted
                                            ? Colors.green
                                            : Colors.orange),
                                ),
                              )
                            else
                              const SizedBox(height: 6),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
