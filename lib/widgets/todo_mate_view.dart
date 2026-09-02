import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/todo_model.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';

class TodoMateView extends StatefulWidget {
  final TodoProvider provider;
  final Function(Todo todo) onEditTodo;

  const TodoMateView({
    super.key,
    required this.provider,
    required this.onEditTodo,
  });

  @override
  State<TodoMateView> createState() => _TodoMateViewState();
}

class _TodoMateViewState extends State<TodoMateView> {
  final Map<int?, TextEditingController> _inlineControllers = {};
  final Map<int?, bool> _inlineInputActive = {};

  @override
  void dispose() {
    for (final controller in _inlineControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  void _addInlineTodo(int? categoryId) {
    final controller = _inlineControllers[categoryId];
    if (controller != null && controller.text.trim().isNotEmpty) {
      final title = controller.text.trim();
      widget.provider.addTodo(
        title,
        1, // Default Q1
        categoryId: categoryId,
        targetDate: widget.provider.selectedDate,
      );
      controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.provider.categories;
    final groupedTodos = widget.provider.todosGroupedByCategory;

    return RefreshIndicator(
      onRefresh: () async {
        await widget.provider.loadTodos();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Render each Category section
            for (final cat in categories) ...[
              _buildCategorySection(
                context: context,
                category: cat,
                color: _parseColor(cat.colorHex),
                todos: groupedTodos[cat.id] ?? [],
              ),
            ],

            // Uncategorized section if any
            if ((groupedTodos[null] ?? []).isNotEmpty)
              _buildCategorySection(
                context: context,
                category: Category(
                  id: null,
                  name: '기타 (미분류)',
                  colorHex: '#7F8C8D',
                  emoji: '📌',
                ),
                color: Colors.grey,
                todos: groupedTodos[null]!,
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection({
    required BuildContext context,
    required Category category,
    required Color color,
    required List<Todo> todos,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final completedCount = todos.where((t) => t.isCompleted).length;
    final isInputActive = _inlineInputActive[category.id] ?? false;

    if (!_inlineControllers.containsKey(category.id)) {
      _inlineControllers[category.id] = TextEditingController();
    }
    final controller = _inlineControllers[category.id]!;

    final pendingRoutines = widget.provider
        .getPendingRoutinesForDate(widget.provider.selectedDate)
        .where((r) => r.categoryId == category.id)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(category.emoji, style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      category.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleMedium?.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$completedCount / ${todos.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    isInputActive ? Icons.close : Icons.add_circle_outline,
                    color: color,
                    size: 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _inlineInputActive[category.id] = !isInputActive;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Inline Add Task TextField
          if (isInputActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: '${category.name} 할 일 입력...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: color.withValues(alpha: 0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: color, width: 2),
                        ),
                      ),
                      onSubmitted: (_) => _addInlineTodo(category.id),
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: color),
                    onPressed: () => _addInlineTodo(category.id),
                  ),
                ],
              ),
            ),

          // Pending Routines list (semi-transparent grey preview cards with manual add button)
          if (pendingRoutines.isNotEmpty)
            ...pendingRoutines.map((routine) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                      child: Icon(
                        Icons.autorenew_rounded,
                        size: 15,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            routine.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '반복 루틴${routine.timeStr != null ? ' • ${routine.timeStr}' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () async {
                        await widget.provider.instantiateRoutineAsTodo(
                          routine,
                          widget.provider.selectedDate,
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.q2.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded, size: 15, color: AppColors.q2),
                            SizedBox(width: 2),
                            Text(
                              '추가',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.q2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

          // Todo List items
          if (todos.isEmpty && pendingRoutines.isEmpty && !isInputActive)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Text(
                '할 일이 없습니다. + 버튼을 눌러 등록해보세요!',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            )
          else if (todos.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todos.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 52,
                color: theme.dividerColor.withValues(alpha: 0.05),
              ),
              itemBuilder: (context, index) {
                final todo = todos[index];

                return Dismissible(
                  key: Key('todo_mate_${todo.id}'),
                  background: Container(
                    color: Colors.red.shade400,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    widget.provider.softDeleteTodo(todo);
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: GestureDetector(
                      onTap: () {
                        widget.provider.toggleTodoCompletion(todo);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: todo.isCompleted ? color : Colors.transparent,
                          border: Border.all(
                            color: todo.isCompleted ? color : color.withValues(alpha: 0.6),
                            width: 2,
                          ),
                        ),
                        child: todo.isCompleted
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                        color: todo.isCompleted
                            ? theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4)
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: (todo.timeStr != null || todo.location != null || todo.memo != null || todo.hasNotification)
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (todo.timeStr != null || todo.location != null || todo.hasNotification)
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      if (todo.hasNotification)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.notifications_active_rounded, size: 12, color: Colors.amber),
                                            const SizedBox(width: 2),
                                            Text(
                                              todo.notificationOffset == 0
                                                  ? '알림 ON'
                                                  : (todo.notificationOffset == 60 ? '1시간 전' : '${todo.notificationOffset}분 전'),
                                              style: const TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      if ((todo.timeStr != null && todo.timeStr!.isNotEmpty) || (todo.dueTimeStr != null && todo.dueTimeStr!.isNotEmpty))
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.access_time_rounded, size: 12, color: Colors.blueAccent),
                                            const SizedBox(width: 2),
                                            Text(
                                              (todo.timeStr != null && todo.timeStr!.isNotEmpty && todo.dueTimeStr != null && todo.dueTimeStr!.isNotEmpty)
                                                  ? '${todo.timeStr} ~ ${todo.dueTimeStr}'
                                                  : (todo.timeStr ?? '~ ${todo.dueTimeStr}'),
                                              style: const TextStyle(fontSize: 11, color: Colors.blueAccent),
                                            ),
                                          ],
                                        ),
                                      if (todo.location != null && todo.location!.isNotEmpty)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 12, color: Colors.deepOrangeAccent),
                                            const SizedBox(width: 2),
                                            Text(
                                              todo.location!,
                                              style: const TextStyle(fontSize: 11, color: Colors.deepOrangeAccent, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                if (todo.memo != null && todo.memo!.isNotEmpty)
                                  Text(
                                    '📝 ${todo.memo!}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (todo.routineId != null)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.autorenew, size: 10, color: Colors.teal),
                                SizedBox(width: 2),
                                Text(
                                  '루틴',
                                  style: TextStyle(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        if (!todo.isCompleted && todo.id != null)
                          IconButton(
                            icon: Icon(
                              widget.provider.pomodoroTodoId == todo.id && widget.provider.isTimerRunning
                                  ? Icons.pause_circle_filled
                                  : Icons.timer_outlined,
                              size: 20,
                              color: widget.provider.pomodoroTodoId == todo.id
                                  ? Colors.redAccent
                                  : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                            ),
                            onPressed: () {
                              if (widget.provider.pomodoroTodoId == todo.id && widget.provider.isTimerRunning) {
                                widget.provider.pausePomodoro();
                              } else {
                                widget.provider.startPomodoro(todo.id!);
                              }
                            },
                            tooltip: '뽀모도로 25분 타이머',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => widget.onEditTodo(todo),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
