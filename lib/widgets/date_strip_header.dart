import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/todo_provider.dart';

class DateStripHeader extends StatefulWidget {
  final TodoProvider provider;

  const DateStripHeader({super.key, required this.provider});

  @override
  State<DateStripHeader> createState() => _DateStripHeaderState();
}

class _DateStripHeaderState extends State<DateStripHeader> {
  bool _isMonthExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = widget.provider;
    final selected = provider.selectedDate;

    final monthFormat = DateFormat('yyyy년 M월', 'ko');
    final isTodaySelected =
        selected.year == DateTime.now().year &&
        selected.month == DateTime.now().month &&
        selected.day == DateTime.now().day;

    final selectedDayTodos = provider.todos.where(
      (t) =>
          t.targetDate.year == selected.year &&
          t.targetDate.month == selected.month &&
          t.targetDate.day == selected.day,
    ).toList();
    final selectedUncompleted = selectedDayTodos.where((t) => !t.isCompleted).length;

    // Week calculation
    final monday = selected.subtract(Duration(days: selected.weekday - 1));
    final weekDays = List.generate(
      7,
      (index) => monday.add(Duration(days: index)),
    );

    // Month calculation
    final firstOfMonth = DateTime(selected.year, selected.month, 1);
    final lastOfMonth = DateTime(selected.year, selected.month + 1, 0);
    final firstDisplayDate = firstOfMonth.subtract(Duration(days: firstOfMonth.weekday - 1));
    final lastDisplayDate = lastOfMonth.add(Duration(days: 7 - lastOfMonth.weekday));

    final totalDays = lastDisplayDate.difference(firstDisplayDate).inDays + 1;
    final monthWeeks = <List<DateTime>>[];
    for (int i = 0; i < totalDays; i += 7) {
      monthWeeks.add(
        List.generate(7, (index) => firstDisplayDate.add(Duration(days: i + index))),
      );
    }

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
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isMonthExpanded = !_isMonthExpanded;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              monthFormat.format(selected),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isMonthExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                          ],
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: selectedUncompleted > 0
                              ? Colors.orange.withValues(alpha: 0.15)
                              : Colors.teal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          selectedUncompleted > 0
                              ? '남은 할 일 $selectedUncompleted개'
                              : (selectedDayTodos.isNotEmpty
                                    ? '모두 완료! 🎉'
                                    : '계획 없음'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: selectedUncompleted > 0
                                ? Colors.orange[800]
                                : Colors.teal[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    onPressed: () {
                      if (_isMonthExpanded) {
                        provider.setSelectedDate(
                          DateTime(selected.year, selected.month - 1, 1),
                        );
                      } else {
                        provider.setSelectedDate(
                          selected.subtract(const Duration(days: 7)),
                        );
                      }
                    },
                    tooltip: _isMonthExpanded ? '이전 달' : '이전 주',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                  IconButton(
                    icon: Icon(
                      _isMonthExpanded ? Icons.calendar_view_month : Icons.calendar_today,
                      size: 18,
                      color: _isMonthExpanded ? theme.colorScheme.primary : null,
                    ),
                    onPressed: () {
                      setState(() {
                        _isMonthExpanded = !_isMonthExpanded;
                      });
                    },
                    tooltip: _isMonthExpanded ? '주간 보기로 접기' : '월간 달력 펼치기',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    onPressed: () {
                      if (_isMonthExpanded) {
                        provider.setSelectedDate(
                          DateTime(selected.year, selected.month + 1, 1),
                        );
                      } else {
                        provider.setSelectedDate(
                          selected.add(const Duration(days: 7)),
                        );
                      }
                    },
                    tooltip: _isMonthExpanded ? '다음 달' : '다음 주',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Animated Expansion between Week Strip and Full Month Grid
          AnimatedCrossFade(
            firstChild: _buildWeekRow(theme, provider, selected, weekDays),
            secondChild: _buildMonthGrid(theme, provider, selected, monthWeeks),
            crossFadeState: _isMonthExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekRow(
    ThemeData theme,
    TodoProvider provider,
    DateTime selected,
    List<DateTime> weekDays,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays.map((day) {
        return _buildDayCell(
          theme: theme,
          provider: provider,
          selected: selected,
          day: day,
          isOutsideMonth: false,
        );
      }).toList(),
    );
  }

  Widget _buildMonthGrid(
    ThemeData theme,
    TodoProvider provider,
    DateTime selected,
    List<List<DateTime>> monthWeeks,
  ) {
    return Column(
      children: monthWeeks.map((week) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: week.map((day) {
              final isOutside = day.month != selected.month;
              return _buildDayCell(
                theme: theme,
                provider: provider,
                selected: selected,
                day: day,
                isOutsideMonth: isOutside,
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayCell({
    required ThemeData theme,
    required TodoProvider provider,
    required DateTime selected,
    required DateTime day,
    required bool isOutsideMonth,
  }) {
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
    final uncompletedCount = dayTodos.where((t) => !t.isCompleted).length;
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
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : (isToday
                      ? theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        )
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Opacity(
            opacity: isOutsideMonth ? 0.4 : 1.0,
            child: Column(
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    fontSize: 11,
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
                const SizedBox(height: 2),
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 3),
                if (totalCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.onPrimary.withValues(alpha: 0.25)
                          : (uncompletedCount > 0
                              ? Colors.orange.withValues(alpha: 0.15)
                              : Colors.green.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      uncompletedCount > 0 ? '$uncompletedCount개' : '완료',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : (uncompletedCount > 0 ? Colors.orange[800] : Colors.green[800]),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 13),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
