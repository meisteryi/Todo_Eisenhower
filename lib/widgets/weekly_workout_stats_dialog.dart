import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/workout_model.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';

class WeeklyWorkoutStatsDialog extends StatefulWidget {
  final TodoProvider provider;

  const WeeklyWorkoutStatsDialog({super.key, required this.provider});

  @override
  State<WeeklyWorkoutStatsDialog> createState() => _WeeklyWorkoutStatsDialogState();
}

class _WeeklyWorkoutStatsDialogState extends State<WeeklyWorkoutStatsDialog> {
  late DateTime _currentWeekStart; // Monday of the selected week
  bool _isLoadingWeek = false;
  List<WorkoutLog> _weekLogs = [];

  @override
  void initState() {
    super.initState();
    final now = widget.provider.selectedDate;
    _currentWeekStart = DateTime(now.year, now.month, now.day).subtract(
      Duration(days: now.weekday - 1),
    );
    _loadWeekData();
  }

  Future<void> _loadWeekData() async {
    setState(() => _isLoadingWeek = true);
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final startStr = DateFormat('yyyy-MM-dd').format(_currentWeekStart);
    final endStr = DateFormat('yyyy-MM-dd').format(weekEnd);

    final logs = await widget.provider.fetchWorkoutLogsForRange(startStr, endStr);
    if (mounted) {
      setState(() {
        _weekLogs = logs;
        _isLoadingWeek = false;
      });
    }
  }

  void _changeWeek(int weekOffset) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: weekOffset * 7));
    });
    _loadWeekData();
  }

  void _jumpToCurrentWeek() {
    final now = DateTime.now();
    setState(() {
      _currentWeekStart = DateTime(now.year, now.month, now.day).subtract(
        Duration(days: now.weekday - 1),
      );
    });
    _loadWeekData();
  }

  int _getWeekOfMonth(DateTime date) {
    final firstDayOfMonth = DateTime(date.year, date.month, 1);
    final firstWeekday = firstDayOfMonth.weekday; // 1=Mon
    return ((date.day + firstWeekday - 2) / 7).floor() + 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workouts = widget.provider.workouts;
    final workoutsById = {for (var w in workouts) if (w.id != null) w.id!: w};

    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final weekStartStr = DateFormat('MM.dd').format(_currentWeekStart);
    final weekEndStr = DateFormat('MM.dd').format(weekEnd);
    final weekNumber = _getWeekOfMonth(_currentWeekStart);

    final now = DateTime.now();
    final isThisWeek = _currentWeekStart.year == now.year &&
        _currentWeekStart.month == now.month &&
        now.difference(_currentWeekStart).inDays >= 0 &&
        now.difference(_currentWeekStart).inDays < 7;

    // Group logs by date (YYYY-MM-DD)
    final Map<String, List<WorkoutLog>> logsByDate = {};
    for (var log in _weekLogs) {
      logsByDate.putIfAbsent(log.date, () => []).add(log);
    }

    // Weekly calculations
    int completedDaysCount = 0;
    int totalCompletedSets = 0;
    int totalCompletedMinutes = 0;
    double totalVolumeKg = 0.0;

    final Map<String, int> categoryCounts = {
      '웨이트': 0,
      '유산소': 0,
      '스트레칭': 0,
      '기타': 0,
    };

    // Calculate daily completion & KPIs
    final List<Map<String, dynamic>> daysStats = [];
    final weekDayNames = ['월', '화', '수', '목', '금', '토', '일'];

    for (int i = 0; i < 7; i++) {
      final dayDate = _currentWeekStart.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(dayDate);
      final dayLogs = logsByDate[dateStr] ?? [];

      final isDayCompleted = dayLogs.isNotEmpty && dayLogs.any((l) => l.isCompleted);
      if (isDayCompleted) {
        completedDaysCount++;
      }

      int daySets = 0;
      int dayMinutes = 0;
      double dayVolume = 0.0;

      for (var log in dayLogs) {
        final workout = workoutsById[log.workoutId];
        final cat = workout?.category ?? '기타';

        if (log.isCompleted) {
          categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
        }

        // Sets count & Volume calculation
        if (log.setDetails.isNotEmpty) {
          for (var s in log.setDetails) {
            if (s.isCompleted) {
              daySets++;
              totalCompletedSets++;
              if (s.weight > 0 && s.reps > 0) {
                final vol = s.weight * s.reps;
                dayVolume += vol;
                totalVolumeKg += vol;
              }
            }
          }
        } else if (log.completedSets > 0) {
          daySets += log.completedSets;
          totalCompletedSets += log.completedSets;
        }

        if (log.durationMinutes > 0) {
          dayMinutes += log.durationMinutes;
          totalCompletedMinutes += log.durationMinutes;
        }
      }

      final isToday = dayDate.year == now.year &&
          dayDate.month == now.month &&
          dayDate.day == now.day;

      daysStats.add({
        'dayName': weekDayNames[i],
        'dayNum': dayDate.day,
        'dateStr': dateStr,
        'isCompleted': isDayCompleted,
        'completedCount': dayLogs.where((l) => l.isCompleted).length,
        'totalLogsCount': dayLogs.length,
        'daySets': daySets,
        'dayMinutes': dayMinutes,
        'dayVolume': dayVolume,
        'isToday': isToday,
        'logs': dayLogs,
      });
    }

    final double completionRate = (completedDaysCount / 7.0) * 100;
    final int totalCategories = categoryCounts.values.fold(0, (sum, count) => sum + count);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.insights_rounded, color: AppColors.q2, size: 22),
                    SizedBox(width: 8),
                    Text(
                      '주간 운동 통계',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Week Navigator Bar
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
                    onPressed: () => _changeWeek(-1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  GestureDetector(
                    onTap: isThisWeek ? null : _jumpToCurrentWeek,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              '${_currentWeekStart.year}년 ${_currentWeekStart.month}월 $weekNumber주차',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isThisWeek) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.q2,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  '이번 주',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$weekStartStr ~ $weekEndStr',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.hintColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 22),
                    onPressed: () => _changeWeek(1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Main Scrollable Content
            Expanded(
              child: _isLoadingWeek
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. KPI 4-Grid Cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildKpiCard(
                                  title: '오운완 달성일',
                                  value: '$completedDaysCount일',
                                  subtext: '목표 7일 (${completionRate.toInt()}%)',
                                  icon: Icons.check_circle_rounded,
                                  iconColor: AppColors.q2,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildKpiCard(
                                  title: '완료한 세트',
                                  value: '$totalCompletedSets세트',
                                  subtext: '총 운동 세트 합계',
                                  icon: Icons.fitness_center_rounded,
                                  iconColor: const Color(0xFF6C5CE7),
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildKpiCard(
                                  title: '유산소/운동 시간',
                                  value: totalCompletedMinutes > 0
                                      ? '$totalCompletedMinutes분'
                                      : '0분',
                                  subtext: totalCompletedMinutes > 60
                                      ? '${(totalCompletedMinutes / 60).toStringAsFixed(1)}시간 누적'
                                      : '총 운동 시간',
                                  icon: Icons.timer_rounded,
                                  iconColor: const Color(0xFFEAA134),
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildKpiCard(
                                  title: '웨이트 총 볼륨',
                                  value: totalVolumeKg > 0
                                      ? '${NumberFormat('#,###').format(totalVolumeKg.toInt())}kg'
                                      : '0kg',
                                  subtext: '무게 × 횟수 총합',
                                  icon: Icons.bolt_rounded,
                                  iconColor: AppColors.q1,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 2. 7-Day Activity Chart
                          _buildSectionTitle('📅 요일별 오운완 달성 현황'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: daysStats.map((d) {
                                    final bool isDone = d['isCompleted'] as bool;
                                    final int sets = d['daySets'] as int;
                                    final bool isToday = d['isToday'] as bool;

                                    // Bar height calculation (max 60px)
                                    double barHeight = 8;
                                    if (sets > 0) {
                                      barHeight = (sets * 6.0).clamp(16.0, 56.0);
                                    } else if (isDone) {
                                      barHeight = 28.0;
                                    }

                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Done Badge Icon
                                        SizedBox(
                                          height: 20,
                                          child: isDone
                                              ? const Text('🔥', style: TextStyle(fontSize: 13))
                                              : (isToday
                                                  ? Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration: const BoxDecoration(
                                                        color: AppColors.q2,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    )
                                                  : const SizedBox.shrink()),
                                        ),
                                        const SizedBox(height: 4),

                                        // Bar Column
                                        Container(
                                          width: 18,
                                          height: barHeight,
                                          decoration: BoxDecoration(
                                            color: isDone
                                                ? AppColors.q2
                                                : (isToday
                                                    ? AppColors.q2.withValues(alpha: 0.3)
                                                    : (isDark
                                                        ? Colors.white.withValues(alpha: 0.08)
                                                        : Colors.black.withValues(alpha: 0.06))),
                                            borderRadius: BorderRadius.circular(6),
                                            border: isToday
                                                ? Border.all(color: AppColors.q2, width: 1.5)
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Day Name
                                        Text(
                                          d['dayName'] as String,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                                            color: isToday
                                                ? AppColors.q2
                                                : (d['dayName'] == '일'
                                                    ? Colors.redAccent
                                                    : (d['dayName'] == '토'
                                                        ? Colors.blueAccent
                                                        : (isDark ? Colors.white70 : Colors.black87))),
                                          ),
                                        ),
                                        const SizedBox(height: 2),

                                        // Day Date Number
                                        Text(
                                          '${d['dayNum']}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                            color: isToday ? AppColors.q2 : theme.hintColor,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 3. Category Distribution Bar
                          if (totalCategories > 0) ...[
                            _buildSectionTitle('🏷️ 운동 카테고리 비율'),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: SizedBox(
                                      height: 10,
                                      child: Row(
                                        children: [
                                          if ((categoryCounts['웨이트'] ?? 0) > 0)
                                            Expanded(
                                              flex: categoryCounts['웨이트']!,
                                              child: Container(color: AppColors.q2),
                                            ),
                                          if ((categoryCounts['유산소'] ?? 0) > 0)
                                            Expanded(
                                              flex: categoryCounts['유산소']!,
                                              child: Container(color: const Color(0xFF6C5CE7)),
                                            ),
                                          if ((categoryCounts['스트레칭'] ?? 0) > 0)
                                            Expanded(
                                              flex: categoryCounts['스트레칭']!,
                                              child: Container(color: const Color(0xFFEAA134)),
                                            ),
                                          if ((categoryCounts['기타'] ?? 0) > 0)
                                            Expanded(
                                              flex: categoryCounts['기타']!,
                                              child: Container(color: AppColors.q4),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 6,
                                    children: [
                                      _buildCategoryLegend('웨이트', categoryCounts['웨이트'] ?? 0, AppColors.q2, totalCategories),
                                      _buildCategoryLegend('유산소', categoryCounts['유산소'] ?? 0, const Color(0xFF6C5CE7), totalCategories),
                                      _buildCategoryLegend('스트레칭', categoryCounts['스트레칭'] ?? 0, const Color(0xFFEAA134), totalCategories),
                                      _buildCategoryLegend('기타', categoryCounts['기타'] ?? 0, AppColors.q4, totalCategories),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // 4. Day-by-Day Detailed Log Breakdown
                          _buildSectionTitle('📝 이번 주 일자별 운동 기록'),
                          const SizedBox(height: 8),
                          if (_weekLogs.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              alignment: Alignment.center,
                              child: Text(
                                '해당 주간에 완료된 운동 기록이 없습니다.',
                                style: TextStyle(color: theme.hintColor, fontSize: 13),
                              ),
                            )
                          else
                            Column(
                              children: daysStats.where((d) => (d['logs'] as List).isNotEmpty).map((d) {
                                final dayLogs = d['logs'] as List<WorkoutLog>;
                                final dateStr = d['dateStr'] as String;
                                final formattedDate = DateFormat('M월 d일 (E)', 'ko').format(DateTime.parse(dateStr));

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                formattedDate,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              if (d['isToday'] as bool) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.q2.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    '오늘',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: AppColors.q2,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (d['isCompleted'] as bool)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2ECC71).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.check_circle, color: Color(0xFF2ECC71), size: 12),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    '오운완',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF2ECC71),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ...dayLogs.map((l) {
                                        final w = workoutsById[l.workoutId];
                                        final title = w?.title ?? '운동';
                                        final emoji = w?.emoji ?? '🏋️';

                                        String summary = '';
                                        if (l.setDetails.isNotEmpty) {
                                          final doneSets = l.setDetails.where((s) => s.isCompleted).length;
                                          summary = '$doneSets/${l.setDetails.length}세트 완료';
                                        } else if (l.completedSets > 0) {
                                          summary = '${l.completedSets}세트 완료';
                                        } else if (l.durationMinutes > 0) {
                                          summary = '${l.durationMinutes}분 진행';
                                        } else {
                                          summary = l.isCompleted ? '완료' : '진행 중';
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 3),
                                          child: Row(
                                            children: [
                                              Text(emoji, style: const TextStyle(fontSize: 16)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  title,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                summary,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: l.isCompleted ? AppColors.q2 : theme.hintColor,
                                                  fontWeight: l.isCompleted ? FontWeight.bold : FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.q2,
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryLegend(String name, int count, Color color, int total) {
    if (count == 0) return const SizedBox.shrink();
    final percent = total > 0 ? ((count / total) * 100).toInt() : 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$name $percent% ($count회)',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
