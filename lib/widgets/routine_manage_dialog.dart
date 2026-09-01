import 'package:flutter/material.dart';
import '../providers/todo_provider.dart';

class RoutineManageDialog extends StatefulWidget {
  final TodoProvider provider;

  const RoutineManageDialog({super.key, required this.provider});

  @override
  State<RoutineManageDialog> createState() => _RoutineManageDialogState();
}

class _RoutineManageDialogState extends State<RoutineManageDialog> {
  void _showAddRoutineDialog() {
    final titleController = TextEditingController();
    int? selectedCategoryId = widget.provider.categories.isNotEmpty ? widget.provider.categories.first.id : null;
    List<int> selectedDays = [1, 2, 3, 4, 5, 6, 7]; // Default everyday (1=Mon, 7=Sun)

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('신규 루틴 등록'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: '루틴 제목',
                        hintText: '예: 영양제 먹기, 매일 30분 운동',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    const Text('카테고리 선택', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int?>(
                      initialValue: selectedCategoryId,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('카테고리 없음'),
                        ),
                        ...widget.provider.categories.map((cat) {
                          return DropdownMenuItem<int?>(
                            value: cat.id,
                            child: Text('${cat.emoji} ${cat.name}'),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          selectedCategoryId = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('반복 주기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('매일'),
                          selected: selectedDays.length == 7,
                          onSelected: (selected) {
                            setDialogState(() {
                              selectedDays = [1, 2, 3, 4, 5, 6, 7];
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('평일(월~금)'),
                          selected: selectedDays.length == 5 && !selectedDays.contains(6) && !selectedDays.contains(7),
                          onSelected: (selected) {
                            setDialogState(() {
                              selectedDays = [1, 2, 3, 4, 5];
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('주말'),
                          selected: selectedDays.length == 2 && selectedDays.contains(6) && selectedDays.contains(7),
                          onSelected: (selected) {
                            setDialogState(() {
                              selectedDays = [6, 7];
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('요일 직접 선택', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (idx) {
                        final dayNum = idx + 1; // 1=Mon, 7=Sun
                        final isSelected = selectedDays.contains(dayNum);
                        return FilterChip(
                          label: Text(weekdayLabels[idx]),
                          selected: isSelected,
                          onSelected: (val) {
                            setDialogState(() {
                              if (val) {
                                if (!selectedDays.contains(dayNum)) selectedDays.add(dayNum);
                              } else {
                                if (selectedDays.length > 1) selectedDays.remove(dayNum);
                              }
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    selectedDays.sort();
                    final repeatDaysStr = selectedDays.join(',');

                    widget.provider.addRoutine(
                      title: title,
                      categoryId: selectedCategoryId,
                      repeatType: selectedDays.length == 7 ? 'daily' : 'weekly',
                      repeatDays: repeatDaysStr,
                      startDate: DateTime.now(),
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text('등록'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final routines = widget.provider.routines;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.autorenew, color: Colors.teal),
                    SizedBox(width: 8),
                    Text(
                      '루틴 관리',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: routines.isEmpty
                  ? const Center(child: Text('등록된 루틴이 없습니다.'))
                  : ListView.builder(
                      itemCount: routines.length,
                      itemBuilder: (context, index) {
                        final r = routines[index];
                        final cat = widget.provider.categories.firstWhere(
                          (c) => c.id == r.categoryId,
                          orElse: () => widget.provider.categories.first,
                        );

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                            ),
                            title: Text(
                              r.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: r.isActive ? null : TextDecoration.lineThrough,
                              ),
                            ),
                            subtitle: Text(
                              '${cat.name} • ${_formatRepeatDays(r.repeatDays)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: r.isActive,
                                  onChanged: (val) {
                                    widget.provider.toggleRoutineActive(r);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {
                                    widget.provider.deleteRoutine(r.id!);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddRoutineDialog,
                icon: const Icon(Icons.add),
                label: const Text('새 루틴 등록하기'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRepeatDays(String repeatDays) {
    if (repeatDays == '1,2,3,4,5,6,7') return '매일';
    if (repeatDays == '1,2,3,4,5') return '평일(월~금)';
    if (repeatDays == '6,7') return '주말(토, 일)';

    final weekdayLabels = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};
    final days = repeatDays.split(',').map((e) => int.tryParse(e.trim())).whereType<int>();
    return '매주 ${days.map((d) => weekdayLabels[d]).join(', ')}';
  }
}
