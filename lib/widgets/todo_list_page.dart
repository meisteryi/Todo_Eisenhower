import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/todo_model.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';
import 'todo_card.dart';

class TodoListPage extends StatelessWidget {
  final int quadrant;
  final TodoProvider provider;
  final ScrollController? scrollController;
  final VoidCallback? onCloseDetail;

  const TodoListPage({
    super.key,
    required this.quadrant,
    required this.provider,
    this.scrollController,
    this.onCloseDetail,
  });

  Color _getQuadrantColor() {
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

  String _getQuadrantTitle() {
    switch (quadrant) {
      case 0:
        return '미분류 (Unclassified)';
      case 1:
        return 'Q1. Do (즉시 실행)';
      case 2:
        return 'Q2. Decide (계획 실행)';
      case 3:
        return 'Q3. Delegate (업무 위임)';
      case 4:
        return 'Q4. Delete (제거/소각)';
      default:
        return '';
    }
  }

  List<Todo> _getQuadrantTodos() {
    switch (quadrant) {
      case 0:
        return provider.q0Todos;
      case 1:
        return provider.q1Todos;
      case 2:
        return provider.q2Todos;
      case 3:
        return provider.q3Todos;
      case 4:
        return provider.q4Todos;
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final todos = _getQuadrantTodos();
    final themeColor = _getQuadrantColor();

    // 1. Q1 Pomodoro Timer Widget
    Widget buildQ1PomodoroHeader() {
      if (quadrant != 1 || provider.pomodoroTodoId == null) {
        return const SizedBox.shrink();
      }

      final runningTodoId = provider.pomodoroTodoId;
      final runningTodo = provider.todos.firstWhere(
        (t) => t.id == runningTodoId,
        orElse: () => Todo(title: '집중 태스크', quadrant: 1, createdAt: DateTime.now()),
      );

      final elapsedRatio = 1.0 - (provider.pomodoroSecondsRemaining / (25 * 60));

      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.q1.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.q1.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular timer indicator
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: elapsedRatio,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    color: AppColors.q1,
                    strokeWidth: 4,
                  ),
                ),
                Icon(
                  provider.isTimerRunning ? Icons.local_fire_department : Icons.pause,
                  color: AppColors.q1,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오늘의 집중 모드',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.q1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    runningTodo.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.pomodoroTimeFormatted,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    provider.isTimerRunning ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: AppColors.q1,
                    size: 32,
                  ),
                  onPressed: () {
                    if (provider.isTimerRunning) {
                      provider.pausePomodoro();
                    } else {
                      provider.startPomodoro(runningTodo.id!);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.stop_circle_outlined,
                    color: Colors.grey,
                    size: 32,
                  ),
                  onPressed: () {
                    provider.stopPomodoro();
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 2. Q4 Incinerator Banner
    Widget buildQ4Banner() {
      if (quadrant != 4) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.q4.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.q4.withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.q4, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '7일 동안 완료/이동되지 않은 항목은 자동으로 소각되어 휴지통으로 이동합니다.',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.q4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Empty state widget
    Widget buildEmptyState() {
      IconData icon;
      String message;
      switch (quadrant) {
        case 1:
          icon = Icons.check_circle_outline;
          message = '지금 실행할 긴급하고 중요한 일이 없습니다.\n행복하고 여유로운 시간을 보내세요!';
          break;
        case 2:
          icon = Icons.calendar_today_outlined;
          message = '장기적인 성장을 위한 계획을 등록하고\n미래를 준비해 보세요.';
          break;
        case 3:
          icon = Icons.people_outline;
          message = '다른 사람에게 넘기거나 요청할 수 있는\n할 일을 기록해 보세요.';
          break;
        case 4:
          icon = Icons.delete_sweep_outlined;
          message = '불필요한 시간 낭비 습관들을\n여기에 넣고 아예 없애 버리세요.';
          break;
        default:
          icon = Icons.assignment_outlined;
          message = '비어있음';
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: themeColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }



    // Quick share helper for Q3
    void triggerQ3Share(Todo todo) {
      final dueStr = todo.dueDate != null
          ? '\n(기한: ${DateFormat('yyyy년 MM월 dd일 HH:mm').format(todo.dueDate!)})'
          : '';
      final shareText = '📢 이 업무의 진행을 정중히 위임/요청드립니다.\n할 일: "${todo.title}"$dueStr\n확인 후 협조 부탁드립니다. 감사합니다!';

      Share.share(shareText, subject: '업무 위임 요청');
    }

    // Quick show bottom sheet for quadrant repositioning
    void showRepositionSheet(Todo todo) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '사분면 이동 및 재배치',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '태스크: "${todo.title}"',
                  style: textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                  children: [
                    _buildRepositionButton(context, todo, 1, 'Q1. Do (즉시 실행)', AppColors.q1),
                    _buildRepositionButton(context, todo, 2, 'Q2. Decide (계획 실행)', AppColors.q2),
                    _buildRepositionButton(context, todo, 3, 'Q3. Delegate (업무 위임)', AppColors.q3),
                    _buildRepositionButton(context, todo, 4, 'Q4. Delete (제거/소각)', AppColors.q4),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: _buildRepositionButton(context, todo, 0, '미분류 카테고리로 이동', AppColors.q0),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Headers
        buildQ1PomodoroHeader(),
        buildQ4Banner(),

        // Section Title
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    _getQuadrantTitle(),
                    style: textTheme.titleLarge?.copyWith(color: themeColor, fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${todos.length}개)',
                    style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
              if (onCloseDetail != null)
                InkWell(
                  onTap: onCloseDetail,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '대시보드로',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await provider.loadTodos();
            },
            child: todos.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: 300,
                      child: buildEmptyState(),
                    ),
                  )
                : ReorderableListView.builder(
                    scrollController: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorderItem: (oldIndex, newIndex) {
                    provider.reorderTodos(quadrant, oldIndex, newIndex);
                  },
                  itemCount: todos.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    return TodoCard(
                      key: ValueKey(todo.id!),
                      todo: todo,
                      quadrantColor: themeColor,
                      onToggleComplete: () => provider.toggleTodoCompletion(todo),
                      onMoveToQuadrant: (q) => provider.moveTodo(todo, q),
                      onDelete: () => provider.softDeleteTodo(todo),
                      onLongPress: () => showRepositionSheet(todo),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Q1 Focus trigger
                          if (quadrant == 1 && !todo.isCompleted)
                            IconButton(
                              icon: Icon(
                                provider.pomodoroTodoId == todo.id && provider.isTimerRunning
                                    ? Icons.pause_circle_outline
                                    : Icons.play_circle_outline,
                                color: AppColors.q1,
                                size: 20,
                              ),
                              onPressed: () {
                                if (provider.pomodoroTodoId == todo.id && provider.isTimerRunning) {
                                  provider.pausePomodoro();
                                } else {
                                  provider.startPomodoro(todo.id!);
                                }
                              },
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                            ),

                          // Q3 Share trigger
                          if (quadrant == 3 && !todo.isCompleted)
                            IconButton(
                              icon: const Icon(Icons.share, size: 18, color: AppColors.q3),
                              onPressed: () => triggerQ3Share(todo),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                            ),
                          // Q4 Incinerator countdown warning
                          if (quadrant == 4 && !todo.isCompleted)
                            _IncineratorCountdown(todo: todo),
                          
                          // Reorder Drag Handle
                          ReorderableDragStartListener(
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                              child: Icon(
                                Icons.drag_handle,
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepositionButton(BuildContext context, Todo todo, int targetQ, String label, Color color) {
    final isCurrent = todo.quadrant == targetQ;
    return InkWell(
      onTap: isCurrent
          ? null
          : () {
              provider.moveTodo(todo, targetQ);
              Navigator.pop(context);
            },
      child: Container(
        decoration: BoxDecoration(
          color: isCurrent ? color.withValues(alpha: 0.15) : color,
          borderRadius: BorderRadius.circular(12),
          border: isCurrent ? Border.all(color: color, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          isCurrent ? '현재 위치' : label,
          style: TextStyle(
            color: isCurrent ? color : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// Countdown display for Q4 items to warn of incineration
class _IncineratorCountdown extends StatelessWidget {
  final Todo todo;

  const _IncineratorCountdown({required this.todo});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final creationDate = todo.createdAt;
    final expiryDate = creationDate.add(const Duration(days: 7));
    final remainingDuration = expiryDate.difference(now);

    int daysRemaining = remainingDuration.inDays;

    Color color;
    String label;

    if (daysRemaining <= 1) {
      color = AppColors.q1; // Critical warning
      final hours = remainingDuration.inHours;
      label = hours > 0 ? '$hours시간 후 소각' : '곧 소각';
    } else {
      color = AppColors.q4;
      label = '$daysRemaining일 후 소각';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
