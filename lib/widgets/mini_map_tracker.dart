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
      return provider.getQuadrantTodos(quadrant).length;
    }

    Widget buildQuadrantCell(int index, String label, String title, Color themeColor) {
      final isActive = provider.activeQuadrant == index;
      final activeCount = getActiveCount(index);
      final progress = getProgressRatio(index);

      final activeTodos = provider.getQuadrantTodos(index);
      final previewTodos = activeTodos.take(3).toList();

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

      EdgeInsets getProgressBarPadding() {
        if (!isDashboard) {
          if (index == 1) return const EdgeInsets.only(right: 20, bottom: 2);
          if (index == 2) return const EdgeInsets.only(left: 20, bottom: 2);
          return const EdgeInsets.only(bottom: 2);
        }
        switch (index) {
          case 1:
            return const EdgeInsets.only(right: 48, bottom: 4);
          case 2:
            return const EdgeInsets.only(left: 48, bottom: 4);
          case 3:
          case 4:
          default:
            return const EdgeInsets.only(left: 4, right: 4, bottom: 4);
        }
      }

      EdgeInsets getHeaderPadding() {
        if (!isDashboard) {
          if (index == 3) return const EdgeInsets.only(right: 14);
          if (index == 4) return const EdgeInsets.only(left: 14);
          return EdgeInsets.zero;
        }
        switch (index) {
          case 3:
            return const EdgeInsets.only(right: 48);
          case 4:
            return const EdgeInsets.only(left: 48);
          case 1:
          case 2:
          default:
            return EdgeInsets.zero;
        }
      }

      Color cellBg;
      Color borderClr;
      if (isActive && !isDashboard) {
        cellBg = themeColor.withValues(alpha: 0.15);
        borderClr = themeColor;
      } else {
        cellBg = isDark ? AppColors.darkCard.withValues(alpha: 0.6) : AppColors.lightCard;
        borderClr = Colors.transparent;
      }

      // Compact spacing, padding and fonts for mini-map mode to avoid cut-offs
      final cellPadding = isDashboard
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 11)
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
              Padding(
                padding: getHeaderPadding(),
                child: Row(
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
              ),
              SizedBox(height: isDashboard ? 4 : 2),
              // Title
              Text(
                title,
                style: titleStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Preview uncompleted tasks (Max 3, only in dashboard mode)
              Expanded(
                child: AnimatedOpacity(
                  opacity: isDashboard ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: isDashboard ? Curves.easeIn : Curves.easeOut,
                  child: isDashboard
                      ? (previewTodos.isEmpty
                          ? Center(
                              child: Text(
                                '대기 중인 태스크가 없습니다.',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontStyle: FontStyle.italic,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            )
                          : ClipRect(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(previewTodos.length, (todoIdx) {
                                  final todo = previewTodos[todoIdx];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.black.withValues(alpha: 0.15)
                                            : Colors.grey[50]!.withValues(
                                                alpha: 0.5,
                                              ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.darkDivider
                                              : AppColors.lightDivider,
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 3.5,
                                            height: 3.5,
                                            decoration: BoxDecoration(
                                              color: themeColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              todo.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                color: isDark
                                                    ? AppColors.darkTextPrimary
                                                    : AppColors.lightTextPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ))
                      : const SizedBox.shrink(),
                ),
              ),
              SizedBox(height: isDashboard ? 6 : 4),
              // Occupancy Bar Gauge (Progress Bar only, offset asymmetrically to avoid curves)
              Padding(
                padding: getProgressBarPadding(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    minHeight: isDashboard ? 7.0 : 5.0,
                  ),
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
      padding: EdgeInsets.all(isDashboard ? 12 : 12),
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
