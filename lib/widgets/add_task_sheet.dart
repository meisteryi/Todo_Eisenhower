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
    bool hasNotification,
    int notificationOffset,
  )
  onAddTask;

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
  bool _hasNotification = false;
  int _notificationOffset = 0;

  @override
  void initState() {
    super.initState();
    final todo = widget.initialTodo;
    _titleController = TextEditingController(text: todo?.title ?? '');
    _locationController = TextEditingController(text: todo?.location ?? '');
    _timeController = TextEditingController(text: todo?.timeStr ?? '');
    _memoController = TextEditingController(text: todo?.memo ?? '');

    _selectedQ = todo?.quadrant ?? widget.initialQuadrant;
    _selectedCategoryId =
        todo?.categoryId ??
        widget.initialCategoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _selectedTargetDate =
        todo?.targetDate ?? widget.initialTargetDate ?? DateTime.now();
    _selectedDueDate = todo?.dueDate;
    _hasNotification = todo?.hasNotification ?? false;
    _notificationOffset = todo?.notificationOffset ?? 0;
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

  String _getQShortName(int q) {
    switch (q) {
      case 0:
        return '미분류';
      case 1:
        return '즉시';
      case 2:
        return '계획';
      case 3:
        return '위임';
      case 4:
        return '소각';
      default:
        return '';
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay initial = TimeOfDay.now();
    if (_timeController.text.isNotEmpty) {
      final parts = _timeController.text.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60) {
          initial = TimeOfDay(hour: h, minute: m);
        }
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      initialEntryMode: TimePickerEntryMode.input,
      helpText: '시간 입력 (숫자 직접 입력)',
      confirmText: '확인',
      cancelText: '취소',
    );

    if (picked != null) {
      final formattedHour = picked.hour.toString().padLeft(2, '0');
      final formattedMinute = picked.minute.toString().padLeft(2, '0');
      setState(() {
        _timeController.text = '$formattedHour:$formattedMinute';
      });
    }
  }

  Future<int?> _showCustomMinutesDialog() async {
    final controller = TextEditingController(
      text: (_notificationOffset != 0 &&
              _notificationOffset != 10 &&
              _notificationOffset != 30 &&
              _notificationOffset != 60)
          ? _notificationOffset.toString()
          : '15',
    );
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            '커스텀 알림 시간 설정',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              suffixText: '분 전',
              hintText: '예: 15',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final min = int.tryParse(controller.text.trim());
                if (min != null && min >= 0) {
                  Navigator.pop(context, min);
                }
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
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
      _hasNotification,
      _notificationOffset,
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
              // Header Row (Title + Notification Toggle)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initialTodo == null ? '새로운 할 일 등록' : '할 일 세부 수정',
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _hasNotification
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_outlined,
                        size: 18,
                        color: _hasNotification
                            ? Colors.amber[700]
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _hasNotification ? '알림 켬' : '알림 끔',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _hasNotification
                              ? Colors.amber[700]
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        height: 24,
                        child: Switch.adaptive(
                          value: _hasNotification,
                          activeThumbColor: Colors.amber[700],
                          onChanged: (val) {
                            setState(() {
                              _hasNotification = val;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
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
                      color: isDark
                          ? AppColors.darkDivider
                          : AppColors.lightDivider,
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
                      readOnly: true,
                      onTap: _pickTime,
                      decoration: InputDecoration(
                        hintText: '시간 선택⏱️',
                        prefixIcon: const Icon(
                          Icons.access_time_rounded,
                          size: 18,
                        ),
                        suffixIcon: _timeController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  setState(() {
                                    _timeController.clear();
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Location input
                  Expanded(
                    child: TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'location',
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
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
                maxLines: 1,
                decoration: InputDecoration(
                  hintText: '상세 메모 및 주요 노트 입력...',
                  prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Notification Timing Options (Show when _hasNotification is true)
              if (_hasNotification) ...[
                Text(
                  '알림 미리 알림 시간',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ChoiceChip(
                      label: const Text('정시', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      selected: _notificationOffset == 0,
                      selectedColor: Colors.amber[700],
                      labelStyle: TextStyle(
                        color: _notificationOffset == 0 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) setState(() => _notificationOffset = 0);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('10분 전', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      selected: _notificationOffset == 10,
                      selectedColor: Colors.amber[700],
                      labelStyle: TextStyle(
                        color: _notificationOffset == 10 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) setState(() => _notificationOffset = 10);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('30분 전', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      selected: _notificationOffset == 30,
                      selectedColor: Colors.amber[700],
                      labelStyle: TextStyle(
                        color: _notificationOffset == 30 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) setState(() => _notificationOffset = 30);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('1시간 전', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      selected: _notificationOffset == 60,
                      selectedColor: Colors.amber[700],
                      labelStyle: TextStyle(
                        color: _notificationOffset == 60 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      showCheckmark: false,
                      onSelected: (selected) {
                        if (selected) setState(() => _notificationOffset = 60);
                      },
                    ),
                    ChoiceChip(
                      label: Text(
                        _notificationOffset != 0 && _notificationOffset != 10 && _notificationOffset != 30 && _notificationOffset != 60
                            ? '커스텀 ($_notificationOffset분 전)'
                            : '커스텀',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      selected: _notificationOffset != 0 && _notificationOffset != 10 && _notificationOffset != 30 && _notificationOffset != 60,
                      selectedColor: Colors.amber[700],
                      labelStyle: TextStyle(
                        color: (_notificationOffset != 0 && _notificationOffset != 10 && _notificationOffset != 30 && _notificationOffset != 60)
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      showCheckmark: false,
                      onSelected: (selected) async {
                        if (selected) {
                          final customMin = await _showCustomMinutesDialog();
                          if (customMin != null) {
                            setState(() => _notificationOffset = customMin);
                          }
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Category Selection Dropdown
              if (widget.categories.isNotEmpty) ...[
                Text(
                  '카테고리 선택',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  initialValue: _selectedCategoryId,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

              // Priority Quadrant Selection Chips
              Text(
                '우선순위 사분면 지정',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
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
                        fontSize: 12,
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
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
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
