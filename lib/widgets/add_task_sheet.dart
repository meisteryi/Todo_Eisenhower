import 'package:flutter/cupertino.dart';
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
    String? dueTimeStr,
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
  late TextEditingController _dueTimeController;
  late TextEditingController _memoController;

  int _selectedQ = 1;
  int? _selectedCategoryId;
  DateTime _selectedTargetDate = DateTime.now();
  DateTime? _selectedDueDate;
  bool _hasNotification = false;
  int _notificationOffset = 0;

  bool _isCalendarExpanded = false;
  DateTime _calendarMonth = DateTime.now();
  bool _isSelectingRangeEnd = false;

  @override
  void initState() {
    super.initState();
    final todo = widget.initialTodo;
    _titleController = TextEditingController(text: todo?.title ?? '');
    _locationController = TextEditingController(text: todo?.location ?? '');
    _timeController = TextEditingController(text: todo?.timeStr ?? '');
    _dueTimeController = TextEditingController(text: todo?.dueTimeStr ?? '');
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

    _calendarMonth = DateTime(
      _selectedTargetDate.year,
      _selectedTargetDate.month,
      1,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _timeController.dispose();
    _dueTimeController.dispose();
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

  Future<void> _pickTimeForController(
    TextEditingController controller,
    String titleLabel,
  ) async {
    int selectedHour = DateTime.now().hour;
    int selectedMinuteIndex = 0; // 0: 00, 1: 05, 2: 10, ..., 11: 55

    if (controller.text.isNotEmpty) {
      final parts = controller.text.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          selectedHour = h.clamp(0, 23);
          selectedMinuteIndex = (m / 5).round().clamp(0, 11);
        }
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final minutesList = List.generate(
      12,
      (index) => index * 5,
    ); // 0, 5, 10, ..., 55

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) {
        return Container(
          height: 270,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                // Header Row (Title + Done Button)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        titleLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          final hStr = selectedHour.toString().padLeft(2, '0');
                          final mStr = minutesList[selectedMinuteIndex]
                              .toString()
                              .padLeft(2, '0');
                          setState(() {
                            controller.text = '$hStr:$mStr';
                          });
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          '완료',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.q2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      // Hours Dial (0 ~ 23)
                      Expanded(
                        child: CupertinoPicker(
                          magnification: 1.2,
                          squeeze: 1.2,
                          useMagnifier: true,
                          itemExtent: 36,
                          scrollController: FixedExtentScrollController(
                            initialItem: selectedHour,
                          ),
                          onSelectedItemChanged: (int index) {
                            selectedHour = index;
                          },
                          children: List<Widget>.generate(24, (int index) {
                            return Center(
                              child: Text(
                                '${index.toString().padLeft(2, '0')} 시',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      // Minutes Dial (00, 05, 10, ..., 55)
                      Expanded(
                        child: CupertinoPicker(
                          magnification: 1.2,
                          squeeze: 1.2,
                          useMagnifier: true,
                          itemExtent: 36,
                          scrollController: FixedExtentScrollController(
                            initialItem: selectedMinuteIndex,
                          ),
                          onSelectedItemChanged: (int index) {
                            selectedMinuteIndex = index;
                          },
                          children: List<Widget>.generate(12, (int index) {
                            final minVal = index * 5;
                            return Center(
                              child: Text(
                                '${minVal.toString().padLeft(2, '0')} 분',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<int?> _showCustomMinutesDialog() async {
    final currentHours = _notificationOffset ~/ 60;
    final currentMins = _notificationOffset % 60;

    final hoursController = TextEditingController(
      text: currentHours > 0 ? currentHours.toString() : '',
    );
    final minsController = TextEditingController(
      text: currentMins > 0
          ? currentMins.toString()
          : (currentHours == 0 ? '15' : '0'),
    );

    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            '커스텀 미리 알림 시간 설정',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: hoursController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    suffixText: '시간',
                    hintText: '0',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: minsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    suffixText: '분 전',
                    hintText: '15',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final h = int.tryParse(hoursController.text.trim()) ?? 0;
                final m = int.tryParse(minsController.text.trim()) ?? 0;
                final total = (h * 60) + m;
                if (total >= 0) {
                  Navigator.pop(context, total);
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
    final dueTimeStr = _dueTimeController.text.trim();
    final memoStr = _memoController.text.trim();

    widget.onAddTask(
      text,
      _selectedQ,
      _selectedCategoryId,
      _selectedTargetDate,
      _selectedDueDate,
      loc.isNotEmpty ? loc : null,
      timeStr.isNotEmpty ? timeStr : null,
      dueTimeStr.isNotEmpty ? dueTimeStr : null,
      memoStr.isNotEmpty ? memoStr : null,
      _hasNotification,
      _notificationOffset,
    );
    Navigator.pop(context);
  }

  void _postponeTask(int days) {
    final now = DateTime.now();
    final baseDate = DateTime(now.year, now.month, now.day);
    final newTargetDate = baseDate.add(Duration(days: days));

    setState(() {
      if (_selectedDueDate != null) {
        final diff = _selectedDueDate!.difference(_selectedTargetDate);
        _selectedDueDate = newTargetDate.add(diff);
      }
      _selectedTargetDate = newTargetDate;
    });

    _submitTask();
  }

  void _onInlineCalendarDayTap(DateTime day) {
    final tapped = DateTime(day.year, day.month, day.day);
    final target = DateTime(
      _selectedTargetDate.year,
      _selectedTargetDate.month,
      _selectedTargetDate.day,
    );

    if (!_isSelectingRangeEnd) {
      // First Tap: Set targetDate = tapped, reset dueDate = null (single day)
      setState(() {
        _selectedTargetDate = tapped;
        _selectedDueDate = null;
        _isSelectingRangeEnd = true;
      });
    } else {
      // Second Tap: Set range end or handle same day
      if (tapped.isAtSameMomentAs(target)) {
        // Tapped same day twice => Single-day task!
        setState(() {
          _selectedTargetDate = target;
          _selectedDueDate = null;
          _isSelectingRangeEnd = false;
          _isCalendarExpanded = false;
        });
      } else if (tapped.isBefore(target)) {
        // Tapped earlier day => Swap start and end
        setState(() {
          _selectedTargetDate = tapped;
          _selectedDueDate = target;
          _isSelectingRangeEnd = false;
          _isCalendarExpanded = false;
        });
      } else {
        // Tapped later day => Range from target to tapped
        setState(() {
          _selectedTargetDate = target;
          _selectedDueDate = tapped;
          _isSelectingRangeEnd = false;
          _isCalendarExpanded = false;
        });
      }
    }
  }

  Widget _buildInlineCalendarGrid(ThemeData theme, bool isDark) {
    final firstOfMonth = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final lastOfMonth = DateTime(
      _calendarMonth.year,
      _calendarMonth.month + 1,
      0,
    );
    final firstDisplayDate = firstOfMonth.subtract(
      Duration(days: firstOfMonth.weekday - 1),
    );
    final lastDisplayDate = lastOfMonth.add(
      Duration(days: 7 - lastOfMonth.weekday),
    );

    final totalDays = lastDisplayDate.difference(firstDisplayDate).inDays + 1;
    final weeks = <List<DateTime>>[];
    for (int i = 0; i < totalDays; i += 7) {
      weeks.add(
        List.generate(
          7,
          (index) => firstDisplayDate.add(Duration(days: i + index)),
        ),
      );
    }

    final targetOnly = DateTime(
      _selectedTargetDate.year,
      _selectedTargetDate.month,
      _selectedTargetDate.day,
    );
    final dueOnly = _selectedDueDate != null
        ? DateTime(
            _selectedDueDate!.year,
            _selectedDueDate!.month,
            _selectedDueDate!.day,
          )
        : null;

    final weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Month Header Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: () {
                  setState(() {
                    _calendarMonth = DateTime(
                      _calendarMonth.year,
                      _calendarMonth.month - 1,
                      1,
                    );
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                DateFormat('yyyy년 M월', 'ko').format(_calendarMonth),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () {
                  setState(() {
                    _calendarMonth = DateTime(
                      _calendarMonth.year,
                      _calendarMonth.month + 1,
                      1,
                    );
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Weekday Names Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdayNames.map((name) {
              return Expanded(
                child: Center(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: name == '일'
                          ? Colors.red
                          : (name == '토'
                                ? Colors.blue
                                : (isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600])),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          // Calendar Grid Rows
          ...weeks.map((week) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: week.map((day) {
                  final dayOnly = DateTime(day.year, day.month, day.day);
                  final isOutside = day.month != _calendarMonth.month;

                  final isStart = dayOnly.isAtSameMomentAs(targetOnly);
                  final isEnd =
                      dueOnly != null && dayOnly.isAtSameMomentAs(dueOnly);
                  final isInRange =
                      dueOnly != null &&
                      dayOnly.isAfter(targetOnly) &&
                      dayOnly.isBefore(dueOnly);
                  final isToday =
                      dayOnly.year == DateTime.now().year &&
                      dayOnly.month == DateTime.now().month &&
                      dayOnly.day == DateTime.now().day;

                  Color? cellBg;
                  BorderRadius cellRadius = BorderRadius.circular(10);

                  if (isStart && (isEnd || dueOnly == null)) {
                    cellBg = theme.colorScheme.primary;
                  } else if (isStart) {
                    cellBg = theme.colorScheme.primary;
                    cellRadius = const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    );
                  } else if (isEnd) {
                    cellBg = Colors.redAccent;
                    cellRadius = const BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    );
                  } else if (isInRange) {
                    cellBg = theme.colorScheme.primary.withValues(alpha: 0.2);
                    cellRadius = BorderRadius.zero;
                  }

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _onInlineCalendarDayTap(day),
                      child: Container(
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cellBg,
                          borderRadius: cellRadius,
                          border: isToday && !isStart && !isEnd
                              ? Border.all(
                                  color: theme.colorScheme.primary,
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Opacity(
                          opacity: isOutside ? 0.35 : 1.0,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: (isStart || isEnd || isToday)
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: (isStart || isEnd)
                                      ? Colors.white
                                      : (day.weekday == 7
                                            ? Colors.red
                                            : (day.weekday == 6
                                                  ? Colors.blue
                                                  : (isDark
                                                        ? Colors.white
                                                        : Colors.black87))),
                                ),
                              ),
                              if (isStart && dueOnly != null)
                                const Text(
                                  '시작',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.white70,
                                  ),
                                )
                              else if (isEnd)
                                const Text(
                                  '마감',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.white70,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
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
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _getQColor(_selectedQ),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),

              // Time & Location Inputs Row
              if (_selectedDueDate != null) ...[
                // Range Task: Separate Start Time & Due Time
                Row(
                  children: [
                    // Start Time input
                    Expanded(
                      child: TextField(
                        controller: _timeController,
                        readOnly: true,
                        onTap: () =>
                            _pickTimeForController(_timeController, '실행/시작 시간'),
                        decoration: InputDecoration(
                          hintText: '시작 시간⏱️',
                          prefixIcon: const Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: Colors.blue,
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
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Due Time input
                    Expanded(
                      child: TextField(
                        controller: _dueTimeController,
                        readOnly: true,
                        onTap: () =>
                            _pickTimeForController(_dueTimeController, '마감 시간'),
                        decoration: InputDecoration(
                          hintText: '마감 시간🚩',
                          prefixIcon: const Icon(
                            Icons.flag_outlined,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          suffixIcon: _dueTimeController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    setState(() {
                                      _dueTimeController.clear();
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: '위치/장소📍',
                    prefixIcon: const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ] else ...[
                // Single-day Task: Time + Location Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _timeController,
                        readOnly: true,
                        onTap: () =>
                            _pickTimeForController(_timeController, '실행 시간'),
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
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          hintText: '위치/장소📍',
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
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
              ],
              const SizedBox(height: 10),

              // Memo / Description Input
              TextField(
                controller: _memoController,
                maxLines: 1,
                decoration: InputDecoration(
                  hintText: '상세 메모 및 주요 노트 입력...',
                  prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text(
                          '정시',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: _notificationOffset == 0,
                        selectedColor: Colors.amber[700],
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.08),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelStyle: TextStyle(
                          color: _notificationOffset == 0
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        onSelected: (selected) {
                          if (selected) setState(() => _notificationOffset = 0);
                        },
                      ),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        label: const Text(
                          '10분 전',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: _notificationOffset == 10,
                        selectedColor: Colors.amber[700],
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.08),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelStyle: TextStyle(
                          color: _notificationOffset == 10
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        onSelected: (selected) {
                          if (selected) setState(() => _notificationOffset = 10);
                        },
                      ),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        label: const Text(
                          '30분 전',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: _notificationOffset == 30,
                        selectedColor: Colors.amber[700],
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.08),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelStyle: TextStyle(
                          color: _notificationOffset == 30
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        onSelected: (selected) {
                          if (selected) setState(() => _notificationOffset = 30);
                        },
                      ),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        label: const Text(
                          '1시간 전',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: _notificationOffset == 60,
                        selectedColor: Colors.amber[700],
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.08),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelStyle: TextStyle(
                          color: _notificationOffset == 60
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        onSelected: (selected) {
                          if (selected) setState(() => _notificationOffset = 60);
                        },
                      ),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        label: Text(
                          _notificationOffset != 0 &&
                                  _notificationOffset != 10 &&
                                  _notificationOffset != 30 &&
                                  _notificationOffset != 60
                              ? (_notificationOffset >= 60 &&
                                      _notificationOffset % 60 == 0
                                  ? '${_notificationOffset ~/ 60}시간 전'
                                  : '$_notificationOffset분 전')
                              : '커스텀',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected:
                            _notificationOffset != 0 &&
                            _notificationOffset != 10 &&
                            _notificationOffset != 30 &&
                            _notificationOffset != 60,
                        selectedColor: Colors.amber[700],
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.08),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        labelStyle: TextStyle(
                          color:
                              (_notificationOffset != 0 &&
                                  _notificationOffset != 10 &&
                                  _notificationOffset != 30 &&
                                  _notificationOffset != 60)
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) async {
                          final customMin = await _showCustomMinutesDialog();
                          if (customMin != null) {
                            setState(() => _notificationOffset = customMin);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Category Selection (Organic Wrap Pastel Pill Selector)
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
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    // '카테고리 없음' Chip
                    ChoiceChip(
                      label: Text(
                        '📁 없음',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _selectedCategoryId == null
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                      selected: _selectedCategoryId == null,
                      selectedColor: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.1),
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.08),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      showCheckmark: false,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategoryId = null;
                          });
                        }
                      },
                    ),
                    // Category Chips List
                    ...widget.categories.map((cat) {
                      final isSelected = _selectedCategoryId == cat.id;
                      final catColor = Color(
                        int.parse(cat.colorHex.replaceFirst('#', '0xFF')),
                      );

                      return ChoiceChip(
                        label: Text(
                          '${cat.emoji} ${cat.name}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: catColor,
                        backgroundColor: catColor.withValues(alpha: 0.15),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        showCheckmark: false,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategoryId = cat.id;
                            });
                          }
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 14),
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
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : qColor.withValues(alpha: 0.08),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
              const SizedBox(height: 14),

              // Inline Range Calendar Selection Header (Borderless Filled Container)
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isCalendarExpanded = !_isCalendarExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedDueDate != null
                              ? Icons.date_range_rounded
                              : Icons.today_rounded,
                          size: 18,
                          color: Theme.of(context).primaryColor,
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedDueDate == null
                                  ? '실행일: ${DateFormat('yyyy.MM.dd (E)', 'ko').format(_selectedTargetDate)}'
                                  : '기간: ${DateFormat('MM.dd', 'ko').format(_selectedTargetDate)} ~ ${DateFormat('MM.dd', 'ko').format(_selectedDueDate!)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _selectedDueDate == null
                                  ? '당일 일정 (달력을 2번 눌러 기간 설정)'
                                  : '${_selectedDueDate!.difference(_selectedTargetDate).inDays + 1}일간 진행되는 일정 (마감: ${DateFormat('MM.dd').format(_selectedDueDate!)})',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (_selectedDueDate != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDueDate = null;
                                  _isSelectingRangeEnd = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '당일로 초기화',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          Icon(
                            _isCalendarExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

              // Expandable Inline Range Calendar Grid
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isCalendarExpanded
                    ? _buildInlineCalendarGrid(Theme.of(context), isDark)
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // Postpone Action Buttons (Show when editing an existing task)
              if (widget.initialTodo != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _postponeTask(1),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wb_sunny_outlined, size: 16, color: Colors.orange),
                              SizedBox(width: 6),
                              Text(
                                '내일로 미루기',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _postponeTask(7),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.update_rounded, size: 16, color: Colors.indigo),
                              SizedBox(width: 6),
                              Text(
                                '다음주로 미루기',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // Submit Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getQColor(_selectedQ),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
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
