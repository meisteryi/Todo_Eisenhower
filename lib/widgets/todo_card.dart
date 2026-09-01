import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo_model.dart';
import '../theme/app_theme.dart';

class TodoCard extends StatefulWidget {
  final Todo todo;
  final Color quadrantColor;
  final VoidCallback onToggleComplete;
  final Function(int) onMoveToQuadrant;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;

  const TodoCard({
    super.key,
    required this.todo,
    required this.quadrantColor,
    required this.onToggleComplete,
    required this.onMoveToQuadrant,
    required this.onDelete,
    this.onLongPress,
  });

  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  double _dragOffset = 0.0;
  final double _maxDragWidth = 180.0; // width of action buttons
  bool _isOpened = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideController.addListener(() {
      setState(() {
        _dragOffset = _slideController.value * -_maxDragWidth;
      });
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TodoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If todo changes (e.g. moved quadrant or completed), reset slide
    if (oldWidget.todo.id != widget.todo.id || oldWidget.todo.quadrant != widget.todo.quadrant) {
      _resetSlide();
    }
  }

  void _resetSlide() {
    _slideController.reverse();
    setState(() {
      _dragOffset = 0.0;
      _isOpened = false;
    });
  }

  void _openSlide() {
    _slideController.forward();
    setState(() {
      _dragOffset = -_maxDragWidth;
      _isOpened = true;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.primaryDelta!;
      if (_dragOffset > 0) _dragOffset = 0; // prevent sliding right
      if (_dragOffset < -_maxDragWidth - 20) {
        _dragOffset = -_maxDragWidth - 20; // limit overshoot
      }
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset < -_maxDragWidth / 2) {
      _openSlide();
    } else {
      _resetSlide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    // Determine adjacent quadrants for moving
    List<int> adjacentQuadrants = [1, 2, 3, 4];
    adjacentQuadrants.remove(widget.todo.quadrant);

    // Build the action buttons revealed on swipe
    Widget buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
      return GestureDetector(
        onTap: () {
          onTap();
          _resetSlide();
        },
        child: Container(
          width: 60,
          height: double.infinity,
          color: color,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Stack(
        children: [
          // Background Slide Actions
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: isDark ? AppColors.darkCard.withValues(alpha: 0.8) : Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Button 1: Adjacent Q1/Q2
                    buildActionButton(
                      _getQShortTitle(adjacentQuadrants[0]),
                      Icons.swap_horiz,
                      _getQuadrantColor(adjacentQuadrants[0]),
                      () => widget.onMoveToQuadrant(adjacentQuadrants[0]),
                    ),
                    // Button 2: Adjacent Q3/Q4
                    buildActionButton(
                      _getQShortTitle(adjacentQuadrants[1]),
                      Icons.swap_vert,
                      _getQuadrantColor(adjacentQuadrants[1]),
                      () => widget.onMoveToQuadrant(adjacentQuadrants[1]),
                    ),
                    // Button 3: Delete (Trash Bin)
                    buildActionButton(
                      '삭제',
                      Icons.delete_outline,
                      Colors.redAccent,
                      widget.onDelete,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Foreground Card Content
          GestureDetector(
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            onTap: _isOpened ? _resetSlide : null,
            onLongPress: widget.onLongPress,
            child: Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                    width: 0.8,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Left edge color bar
                      Container(
                        width: 5,
                        decoration: BoxDecoration(
                          color: widget.quadrantColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Animated custom checkbox
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        child: _CustomCheckbox(
                          value: widget.todo.isCompleted,
                          color: widget.quadrantColor,
                          onChanged: (_) => widget.onToggleComplete(),
                        ),
                      ),

                      // Todo details
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.todo.title,
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: widget.todo.isCompleted ? TextDecoration.lineThrough : null,
                                  color: widget.todo.isCompleted
                                      ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                ),
                              ),
                               if (widget.todo.timeStr != null ||
                                  widget.todo.location != null ||
                                  widget.todo.dueDate != null ||
                                  widget.todo.hasNotification ||
                                  (widget.todo.quadrant == 4 && !widget.todo.isCompleted)) ...[
                                 const SizedBox(height: 4),
                                 Wrap(
                                   spacing: 6,
                                   runSpacing: 4,
                                   children: [
                                     if (widget.todo.quadrant == 4 && !widget.todo.isCompleted)
                                       _IncineratorBadge(todo: widget.todo),
                                     if (widget.todo.hasNotification)
                                       _InfoChip(
                                         icon: Icons.notifications_active_rounded,
                                         label: widget.todo.notificationOffset == 0
                                             ? '알림'
                                             : (widget.todo.notificationOffset == 60
                                                 ? '1시간 전'
                                                 : '${widget.todo.notificationOffset}분 전'),
                                         color: Colors.amber[800]!,
                                       ),
                                    if (widget.todo.timeStr != null && widget.todo.timeStr!.isNotEmpty)
                                      _InfoChip(
                                        icon: Icons.access_time_rounded,
                                        label: widget.todo.timeStr!,
                                        color: Colors.blueAccent,
                                      ),
                                    if (widget.todo.location != null && widget.todo.location!.isNotEmpty)
                                      _InfoChip(
                                        icon: Icons.location_on_outlined,
                                        label: widget.todo.location!,
                                        color: Colors.deepOrangeAccent,
                                      ),
                                    if (widget.todo.dueDate != null)
                                      _DueDateBadge(
                                        dueDate: widget.todo.dueDate!,
                                        isCompleted: widget.todo.isCompleted,
                                      ),
                                  ],
                                ),
                              ],
                              if (widget.todo.memo != null && widget.todo.memo!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '📝 ${widget.todo.memo!}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Space reserved for action buttons and drag handles on the far right
                      const SizedBox(width: 48),
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

  Color _getQuadrantColor(int quadrant) {
    switch (quadrant) {
      case 0:
        return AppColors.q0;
      case 1:
        return AppColors.q1;
      case 2:
        return AppColors.q2;
      case 3:
        return AppColors.q3;
      case 4:
        return AppColors.q4;
      default:
        return Colors.blue;
    }
  }

  String _getQShortTitle(int quadrant) {
    switch (quadrant) {
      case 0:
        return '미분류';
      case 1:
        return '1사분면';
      case 2:
        return '2사분면';
      case 3:
        return '3사분면';
      case 4:
        return '4사분면';
      default:
        return '';
    }
  }
}

// Custom animated checkbox
class _CustomCheckbox extends StatefulWidget {
  final bool value;
  final Color color;
  final ValueChanged<bool?> onChanged;

  const _CustomCheckbox({
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  State<_CustomCheckbox> createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<_CustomCheckbox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.bounceOut),
    );

    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _CustomCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        widget.onChanged(!widget.value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: widget.value ? widget.color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.value
                ? widget.color
                : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
            width: 2,
          ),
        ),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: const Icon(
            Icons.check,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// Due Date Badge
class _DueDateBadge extends StatelessWidget {
  final DateTime dueDate;
  final bool isCompleted;

  const _DueDateBadge({
    required this.dueDate,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final difference = due.difference(today).inDays;

    Color badgeColor;
    Color textColor;
    String label;

    if (isCompleted) {
      badgeColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
      textColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
      label = DateFormat('yy.MM.dd').format(dueDate);
    } else {
      if (difference < 0) {
        // Overdue
        badgeColor = Colors.red.withValues(alpha: 0.15);
        textColor = Colors.redAccent;
        label = '초과: ${difference.abs()}일';
      } else if (difference == 0) {
        // Today
        badgeColor = Colors.orange.withValues(alpha: 0.15);
        textColor = Colors.orange;
        label = '오늘까지';
      } else if (difference == 1) {
        // Tomorrow
        badgeColor = Colors.amber.withValues(alpha: 0.15);
        textColor = Colors.amber[800]!;
        label = '내일까지';
      } else {
        // Farther
        badgeColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
        textColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
        label = DateFormat('yy.MM.dd').format(dueDate);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 10, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncineratorBadge extends StatelessWidget {
  final Todo todo;

  const _IncineratorBadge({required this.todo});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final creationDate = todo.createdAt;
    final expiryDate = creationDate.add(const Duration(days: 7));
    final remainingDuration = expiryDate.difference(now);

    final daysRemaining = remainingDuration.inDays;
    final hoursRemaining = remainingDuration.inHours;

    Color color;
    String label;

    if (hoursRemaining <= 0) {
      color = Colors.red[700]!;
      label = '🔥 오늘 소각 예정';
    } else if (daysRemaining < 1) {
      color = Colors.red[600]!;
      label = '🔥 $hoursRemaining시간 후 소각';
    } else {
      color = Colors.deepOrange;
      label = '🔥 $daysRemaining일 후 소각';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
