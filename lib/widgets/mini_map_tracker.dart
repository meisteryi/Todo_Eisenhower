import 'dart:math';
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

      BorderRadius getCellRadius() {
        final double outerRadius = isDashboard ? 24 : 14;
        final double sideRadius = isDashboard ? 12 : 8;
        final double centerRadius = isDashboard ? 76 : 36;

        switch (index) {
          case 1:
            return BorderRadius.only(
              topLeft: Radius.circular(outerRadius),
              topRight: Radius.circular(sideRadius),
              bottomLeft: Radius.circular(sideRadius),
              bottomRight: Radius.circular(centerRadius),
            );
          case 2:
            return BorderRadius.only(
              topRight: Radius.circular(outerRadius),
              topLeft: Radius.circular(sideRadius),
              bottomRight: Radius.circular(sideRadius),
              bottomLeft: Radius.circular(centerRadius),
            );
          case 3:
            return BorderRadius.only(
              bottomLeft: Radius.circular(outerRadius),
              topLeft: Radius.circular(sideRadius),
              bottomRight: Radius.circular(sideRadius),
              topRight: Radius.circular(centerRadius),
            );
          case 4:
            return BorderRadius.only(
              bottomRight: Radius.circular(outerRadius),
              topRight: Radius.circular(sideRadius),
              bottomLeft: Radius.circular(sideRadius),
              topLeft: Radius.circular(centerRadius),
            );
          default:
            return BorderRadius.circular(16);
        }
      }

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
          clipBehavior: Clip.antiAlias,
          padding: cellPadding,
          decoration: BoxDecoration(
            color: cellBg,
            borderRadius: getCellRadius(),
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
              SizedBox(height: isDashboard ? 12 : 6),
              // Title
              Text(
                title,
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isDashboard ? 10 : 5),
              // Occupancy Bar Gauge (Progress Bar only, no labels, thicker)
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  minHeight: isDashboard ? 7.0 : 5.0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final q0ActiveCount = getActiveCount(0);
    final gap = isDashboard ? 12.0 : 6.0;

    return Container(
      padding: EdgeInsets.all(isDashboard ? 16 : 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 2x2 grid representing quadrants
          Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: buildQuadrantCell(1, 'Q1', '즉시 실행 (Do)', AppColors.q1),
                    ),
                    SizedBox(width: gap),
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
              SizedBox(height: gap),
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
                    SizedBox(width: gap),
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
          // Central Diamond for Unclassified tasks (Q0)
          GestureDetector(
            onTap: () => onQuadrantSelected(0),
            child: Transform.rotate(
              angle: pi / 4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isDashboard ? 72 : 36,
                height: isDashboard ? 72 : 36,
                decoration: BoxDecoration(
                  color: (provider.activeQuadrant == 0 && !isDashboard)
                      ? AppColors.q0.withValues(alpha: 0.15)
                      : (isDark ? AppColors.darkCard : Colors.white),
                  borderRadius: BorderRadius.circular(isDashboard ? 14 : 7),
                  border: Border.all(
                    color: (provider.activeQuadrant == 0 && !isDashboard)
                        ? AppColors.q0
                        : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    width: (provider.activeQuadrant == 0 && !isDashboard) ? 2.0 : 1.0,
                  ),
                  boxShadow: (provider.activeQuadrant == 0 && !isDashboard)
                      ? [
                          BoxShadow(
                            color: AppColors.q0.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.05,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Transform.rotate(
                  angle: -pi / 4,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: isDashboard ? 22 : 13,
                            color: (provider.activeQuadrant == 0 && !isDashboard)
                                ? AppColors.q0
                                : (isDark ? Colors.white : AppColors.lightTextPrimary),
                          ),
                          if (isDashboard) ...[
                            const SizedBox(height: 4),
                            Text(
                              '미분류',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Active Count Badge
                      if (q0ActiveCount > 0)
                        Positioned(
                          top: isDashboard ? -6 : -4,
                          right: isDashboard ? -6 : -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.q0,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$q0ActiveCount',
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
