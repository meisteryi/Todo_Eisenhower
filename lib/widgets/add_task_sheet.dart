import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category_model.dart';
import '../theme/app_theme.dart';

class AddTaskSheet extends StatefulWidget {
  final int initialQuadrant;
  final List<Category> categories;
  final int? initialCategoryId;
  final DateTime? initialTargetDate;
  final Function(String title, int quadrant, int? categoryId, DateTime? targetDate, DateTime? dueDate) onAddTask;

  const AddTaskSheet({
    super.key,
    required this.initialQuadrant,
    this.categories = const [],
    this.initialCategoryId,
    this.initialTargetDate,
    required this.onAddTask,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  late TextEditingController _titleController;
  late int _selectedQ;
  int? _selectedCategoryId;
  late DateTime _selectedTargetDate;
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _selectedQ = widget.initialQuadrant;
    _selectedCategoryId = widget.initialCategoryId ?? (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _selectedTargetDate = widget.initialTargetDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Color _getQColor(int q) {
    switch (q) {
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

  void _submitTask() {
    final text = _titleController.text.trim();
    if (text.isEmpty) return;

    widget.onAddTask(text, _selectedQ, _selectedCategoryId, _selectedTargetDate, _selectedDueDate);
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
        child: SingleChildScrollView(
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
                style: textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
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

              // Category Selection Dropdown
              if (widget.categories.isNotEmpty) ...[
                Text(
                  '카테고리 선택',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  initialValue: _selectedCategoryId,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('카테고리 없음'),
                    ),
                    ...widget.categories.map((cat) {
                      return DropdownMenuItem<int?>(
                        value: cat.id,
                        child: Text('${cat.emoji} ${cat.name}'),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedCategoryId = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Quadrant Segment Selection
              Text(
                '사분면 영역 지정 (아이젠하워)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [0, 1, 2, 3, 4].map((q) {
                  final isSelected = _selectedQ == q;
                  final qColor = _getQColor(q);
                  String qName = '';
                  switch (q) {
                    case 0:
                      qName = '미분류';
                      break;
                    case 1:
                      qName = 'Q1';
                      break;
                    case 2:
                      qName = 'Q2';
                      break;
                    case 3:
                      qName = 'Q3';
                      break;
                    case 4:
                      qName = 'Q4';
                      break;
                  }

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedQ = q;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
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

              // Target Date & Due Date Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '날짜: ${DateFormat('yyyy.MM.dd').format(_selectedTargetDate)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_month, size: 16),
                    label: const Text('날짜 변경'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedTargetDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedTargetDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

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
      ),
    );
  }
}
