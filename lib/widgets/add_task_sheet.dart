import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class AddTaskSheet extends StatefulWidget {
  final int initialQuadrant;
  final Function(String title, int quadrant, DateTime? dueDate) onAddTask;

  const AddTaskSheet({
    super.key,
    required this.initialQuadrant,
    required this.onAddTask,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  late TextEditingController _titleController;
  late int _selectedQ;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _selectedQ = widget.initialQuadrant;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Color _getQColor(int q) {
    switch (q) {
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

  void _submitTask() {
    final text = _titleController.text.trim();
    if (text.isEmpty) return;

    widget.onAddTask(text, _selectedQ, _selectedDate);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '새로운 할 일 등록',
              style: textTheme.titleMedium?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 16),

            // Title Input Text Field
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '할 일을 입력하세요...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _getQColor(_selectedQ),
                    width: 2.0,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitTask(),
            ),
            const SizedBox(height: 16),

            // Quadrant Segment Selection
            Text(
              '사분면 영역 지정',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [1, 2, 3, 4].map((q) {
                final isSelected = _selectedQ == q;
                final qColor = _getQColor(q);
                String qName = '';
                switch (q) {
                  case 1:
                    qName = 'Q1: Do';
                    break;
                  case 2:
                    qName = 'Q2: Plan';
                    break;
                  case 3:
                    qName = 'Q3: Delg';
                    break;
                  case 4:
                    qName = 'Q4: Dlet';
                    break;
                }

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedQ = q;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? qColor
                              : (isDark ? AppColors.darkBg : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? qColor : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          qName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Due Date Picker Trigger
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedDate == null
                          ? '마감 기한 지정 안 함'
                          : '기한: ${DateFormat('yyyy.MM.dd HH:mm').format(_selectedDate!)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: _selectedDate == null
                            ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                            : _getQColor(_selectedQ),
                        fontWeight: _selectedDate == null ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );

                    if (pickedDate != null) {
                      if (!context.mounted) return;
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: _selectedDate != null
                            ? TimeOfDay.fromDateTime(_selectedDate!)
                            : const TimeOfDay(hour: 12, minute: 0),
                      );

                      setState(() {
                        _selectedDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime?.hour ?? 12,
                          pickedTime?.minute ?? 0,
                        );
                      });
                    }
                  },
                  child: const Text('지정하기'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _getQColor(_selectedQ),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _submitTask,
              child: const Text(
                '할 일 등록 완료',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
