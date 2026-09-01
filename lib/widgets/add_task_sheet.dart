import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category_model.dart';
import '../models/todo_model.dart';
import '../theme/app_theme.dart';

class AddTaskSheet extends StatefulWidget {
  final int initialQuadrant;
  final List<Category> categories;
  final int? initialCategoryId;
  final DateTime? initialTargetDate;
  final Todo? initialTodo;
  final Function(
    String title,
    int quadrant,
    int? categoryId,
    DateTime? targetDate,
    DateTime? dueDate,
    String? location,
    String? timeStr,
    String? memo,
  ) onAddTask;

  const AddTaskSheet({
    super.key,
    required this.initialQuadrant,
    this.categories = const [],
    this.initialCategoryId,
    this.initialTargetDate,
    this.initialTodo,
    required this.onAddTask,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _timeController;
  late TextEditingController _memoController;

  late int _selectedQ;
  int? _selectedCategoryId;
  late DateTime _selectedTargetDate;
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    final todo = widget.initialTodo;
    _titleController = TextEditingController(text: todo?.title ?? '');
    _locationController = TextEditingController(text: todo?.location ?? '');
    _timeController = TextEditingController(text: todo?.timeStr ?? '');
    _memoController = TextEditingController(text: todo?.memo ?? '');

    _selectedQ = todo?.quadrant ?? widget.initialQuadrant;
    _selectedCategoryId = todo?.categoryId ?? widget.initialCategoryId ?? (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _selectedTargetDate = todo?.targetDate ?? widget.initialTargetDate ?? DateTime.now();
    _selectedDueDate = todo?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _timeController.dispose();
    _memoController.dispose();
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

  String _getQFullName(int q) {
    switch (q) {
      case 0:
        return '미분류 (Inbox)';
      case 1:
        return '1사분면: 즉시 실행 (Do - 긴급&중요)';
      case 2:
        return '2사분면: 계획 수립 (Decide - 중요&긴급X)';
      case 3:
        return '3사분면: 신속 위임 (Delegate - 긴급&중요X)';
      case 4:
        return '4사분면: 소각 대상 (Delete - 낭비)';
      default:
        return '';
    }
  }

  String _getQShortName(int q) {
    switch (q) {
      case 0:
        return '미분류';
      case 1:
        return '1사분면 (즉시)';
      case 2:
        return '2사분면 (계획)';
      case 3:
        return '3사분면 (위임)';
      case 4:
        return '4사분면 (소각)';
      default:
        return '';
    }
  }

  void _submitTask() {
    final text = _titleController.text.trim();
    if (text.isEmpty) return;

    final loc = _locationController.text.trim();
    final timeStr = _timeController.text.trim();
    final memoStr = _memoController.text.trim();

    widget.onAddTask(
      text,
      _selectedQ,
      _selectedCategoryId,
      _selectedTargetDate,
      _selectedDueDate,
      loc.isNotEmpty ? loc : null,
      timeStr.isNotEmpty ? timeStr : null,
      memoStr.isNotEmpty ? memoStr : null,
    );
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
                widget.initialTodo == null ? '새로운 할 일 등록' : '할 일 세부 수정',
                style: textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Title Input Text Field
              TextField(
                controller: _titleController,
                autofocus: widget.initialTodo == null,
                decoration: InputDecoration(
                  hintText: '할 일을 입력하세요...',
                  prefixIcon: const Icon(Icons.check_box_outlined, size: 20),
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
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              // Time & Location Inputs Row
              Row(
                children: [
                  // Time input
                  Expanded(
                    child: TextField(
                      controller: _timeController,
                      decoration: InputDecoration(
                        hintText: '시간 (예: 14:00)',
                        prefixIcon: const Icon(Icons.access_time_rounded, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Location input
                  Expanded(
                    child: TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: '장소 (예: 회의실 A)',
                        prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Memo / Description Input
              TextField(
                controller: _memoController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: '상세 메모 및 주요 노트 입력...',
                  prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
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

              // Quadrant Selection Dropdown & Chips with Full Names
              Text(
                '우선순위 사분면 지정',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedQ,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _getQColor(_selectedQ), width: 2),
                  ),
                ),
                items: [0, 1, 2, 3, 4].map((q) {
                  final qColor = _getQColor(q);
                  return DropdownMenuItem<int>(
                    value: q,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: qColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getQFullName(q),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedQ = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),

              // Quick Selector Chips with Descriptive Names
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [0, 1, 2, 3, 4].map((q) {
                  final isSelected = _selectedQ == q;
                  final qColor = _getQColor(q);

                  return ChoiceChip(
                    label: Text(
                      _getQShortName(q),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : qColor,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: qColor,
                    backgroundColor: qColor.withValues(alpha: 0.1),
                    side: BorderSide(color: qColor, width: 1.2),
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedQ = q;
                        });
                      }
                    },
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
                child: Text(
                  widget.initialTodo == null ? '할 일 등록 완료' : '수정 사항 저장',
                  style: const TextStyle(
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
