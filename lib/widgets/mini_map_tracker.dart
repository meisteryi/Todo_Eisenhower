import 'package:flutter/material.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';

class MiniMapTracker extends StatelessWidget {
  final TodoProvider provider;
  final Function(int) onQuadrantSelected;
  final bool isDashboard;

  const MiniMapTracker({
    super.key,
    required this.provider,
    required this.onQuadrantSelected,
    this.isDashboard = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Helper to calculate progress ratio
    double getProgressRatio(int quadrant) {
      final quadrantTodos = provider.todos.where((t) => t.quadrant == quadrant).toList();
      if (quadrantTodos.isEmpty) return 0.0;
      final completed = quadrantTodos.where((t) => t.isCompleted).length;
      return completed / quadrantTodos.length;
    }

    // Helper to get active task count
    int getActiveCount(int quadrant) {
      return provider.todos.where((t) => t.quadrant == quadrant && !t.isCompleted).length;
    }

    Widget buildQuadrantCell(int index, String label, String title, Color themeColor) {
      final isActive = provider.activeQuadrant == index;
      final activeCount = getActiveCount(index);
      final progress = getProgressRatio(index);

      Color cellBg;
      Color borderClr;
      if (isActive && !isDashboard) {
        cellBg = themeColor.withValues(alpha: 0.15);
        borderClr = themeColor;
      } else {
        cellBg = isDark ? AppColors.darkCard.withValues(alpha: 0.5) : AppColors.lightCard;
        borderClr = isDark ? AppColors.darkDivider : AppColors.lightDivider;
      }

      // Compact spacing, padding and fonts for mini-map mode to avoid cut-offs
      final cellPadding = isDashboard
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 6);

      final titleStyle = TextStyle(
        fontSize: isDashboard ? 16 : 12,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      );

      final labelStyle = TextStyle(
        fontSize: isDashboard ? 13 : 9,
        fontWeight: FontWeight.bold,
        color: (isActive && !isDashboard)
            ? themeColor
            : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
      );

      return GestureDetector(
        onTap: () => onQuadrantSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: cellPadding,
          decoration: BoxDecoration(
            color: cellBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderClr,
              width: (isActive && !isDashboard) ? 2.0 : 1.0,
            ),
            boxShadow: (isActive && !isDashboard)
                ? [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header Row (Label + Count Badge)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: labelStyle),
                  if (activeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$activeCount',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              // Title
              Text(
                title,
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Occupancy Bar Gauge (Progress Bar)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '진행률',
                        style: TextStyle(
                          fontSize: 8,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: (isActive && !isDashboard)
                              ? themeColor
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isDashboard ? 16 : 12),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: buildQuadrantCell(1, 'Q1', '즉시 실행 (Do)', AppColors.q1),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: buildQuadrantCell(
                    2,
                    'Q2',
                    '계획 실행 (Decide)',
                    AppColors.q2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: buildQuadrantCell(
                    3,
                    'Q3',
                    '업무 위임 (Delegate)',
                    AppColors.q3,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: buildQuadrantCell(
                    4,
                    'Q4',
                    '제거/소각 (Delete)',
                    AppColors.q4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
