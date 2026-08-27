import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo_model.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';

class TrashScreen extends StatelessWidget {
  final TodoProvider provider;

  const TrashScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final trashTodos = provider.trashTodos;

    Color getQuadrantColor(int quadrant) {
      switch (quadrant) {
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

    String getQuadrantName(int quadrant) {
      switch (quadrant) {
        case 1:
          return 'Q1. Do';
        case 2:
          return 'Q2. Decide';
        case 3:
          return 'Q3. Delegate';
        case 4:
          return 'Q4. Delete';
        default:
          return '';
      }
    }

    void confirmClearTrash() {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('휴지통 비우기'),
            content: const Text('휴지통의 모든 할 일이 영구히 삭제되며 복구할 수 없습니다. 계속하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  provider.clearTrashBin();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('휴지통을 비웠습니다.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('비우기'),
              ),
            ],
          );
        },
      );
    }

    Widget buildTrashItem(Todo todo) {
      final qColor = getQuadrantColor(todo.quadrant);
      final qName = getQuadrantName(todo.quadrant);
      final deletedDateStr = todo.deletedAt != null
          ? DateFormat('yy.MM.dd HH:mm').format(todo.deletedAt!)
          : '날짜 없음';

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left color border indicator
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: qColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: qColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          qName,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: qColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '소각/삭제일: $deletedDateStr',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions (Restore, Delete forever)
            IconButton(
              icon: const Icon(Icons.restore, color: Colors.green),
              tooltip: '복원',
              onPressed: () {
                provider.restoreTodo(todo);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${todo.title}" 할 일이 복원되었습니다.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              tooltip: '영구 삭제',
              onPressed: () {
                provider.deleteTodoPermanently(todo.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('영구 삭제되었습니다.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('휴지통 (소각장 보관소)'),
        actions: [
          if (trashTodos.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              label: const Text('비우기', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onPressed: confirmClearTrash,
            ),
        ],
      ),
      body: trashTodos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 64,
                    color: isDark ? Colors.grey[700] : Colors.grey[350],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '휴지통이 비어 있습니다.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: trashTodos.length,
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              itemBuilder: (context, index) {
                return buildTrashItem(trashTodos[index]);
              },
            ),
    );
  }
}
