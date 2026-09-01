import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category_model.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';

class RoutineManageDialog extends StatefulWidget {
  final TodoProvider provider;

  const RoutineManageDialog({super.key, required this.provider});

  @override
  State<RoutineManageDialog> createState() => _RoutineManageDialogState();
}

class _RoutineManageDialogState extends State<RoutineManageDialog> {
  void _showAddRoutineSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddRoutineSheet(
        provider: widget.provider,
        onAddRoutine: (
          title,
          quadrant,
          categoryId,
          repeatType,
          repeatDays,
          startDate,
          endDate,
          location,
          timeStr,
          dueTimeStr,
          memo,
          hasNotification,
          notificationOffset,
        ) async {
          await widget.provider.addRoutine(
            title: title,
            quadrant: quadrant,
            categoryId: categoryId,
            repeatType: repeatType,
            repeatDays: repeatDays,
            startDate: startDate,
            endDate: endDate,
            location: location,
            timeStr: timeStr,
            dueTimeStr: dueTimeStr,
            memo: memo,
            hasNotification: hasNotification,
            notificationOffset: notificationOffset,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final routines = widget.provider.routines;

        return Dialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 620),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.autorenew_rounded, color: AppColors.q2, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          '루틴 관리',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: routines.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.repeat_rounded, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                '등록된 반복 루틴이 없습니다.',
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: routines.length,
                          itemBuilder: (context, index) {
                            final r = routines[index];
                            final cat = widget.provider.categories.firstWhere(
                              (c) => c.id == r.categoryId,
                              orElse: () => Category(id: null, name: '미분류', colorHex: '#94A3B8', emoji: '📁'),
                            );

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.q2.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                                ),
                                title: Text(
                                  r.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    decoration: r.isActive ? null : TextDecoration.lineThrough,
                                  ),
                                ),
                                subtitle: Text(
                                  '${cat.name} • ${_formatRepeatDays(r.repeatDays)}${r.timeStr != null ? ' (${r.timeStr})' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Manual spawn button
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.q2, size: 22),
                                      tooltip: '오늘 할 일로 수동 추가',
                                      onPressed: () async {
                                        await widget.provider.instantiateRoutineAsTodo(r);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("'${r.title}' 할 일이 추가되었습니다!"),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    Switch.adaptive(
                                      value: r.isActive,
                                      activeThumbColor: AppColors.q2,
                                      onChanged: (val) {
                                        widget.provider.toggleRoutineActive(r);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
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
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _showAddRoutineSheet,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(
                      '새 루틴 등록하기',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.q2,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatRepeatDays(String repeatDays) {
    if (repeatDays == '1,2,3,4,5,6,7') return '매일';
    if (repeatDays == '1,2,3,4,5') return '평일(월~금)';
    if (repeatDays == '6,7') return '주말(토,일)';

    final weekdayLabels = {1: '월', 2: '화', 3: '수', 4: '목', 5: '금', 6: '토', 7: '일'};
    final days = repeatDays.split(',').map((e) => int.tryParse(e.trim())).whereType<int>();
    return '매주 ${days.map((d) => weekdayLabels[d]).join(', ')}';
  }
}

/// Full Feature Routine Creation Sheet matching AddTaskSheet
class AddRoutineSheet extends StatefulWidget {
  final TodoProvider provider;
  final Function(
    String title,
    int quadrant,
    int? categoryId,
    String repeatType,
    String repeatDays,
    DateTime startDate,
    DateTime? endDate,
    String? location,
    String? timeStr,
    String? dueTimeStr,
    String? memo,
    bool hasNotification,
    int notificationOffset,
  ) onAddRoutine;

  const AddRoutineSheet({
    super.key,
    required this.provider,
    required this.onAddRoutine,
  });

  @override
  State<AddRoutineSheet> createState() => _AddRoutineSheetState();
}

class _AddRoutineSheetState extends State<AddRoutineSheet> {
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _timeController;
  late TextEditingController _dueTimeController;
  late TextEditingController _memoController;

  int _selectedQ = 1;
  int? _selectedCategoryId;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7]; // Default everyday

  bool _hasNotification = false;
  int _notificationOffset = 0;

  bool _isCalendarExpanded = false;
  DateTime _calendarMonth = DateTime.now();
  bool _isSelectingRangeEnd = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _locationController = TextEditingController();
    _timeController = TextEditingController();
    _dueTimeController = TextEditingController();
    _memoController = TextEditingController();

    if (widget.provider.categories.isNotEmpty) {
      _selectedCategoryId = widget.provider.categories.first.id;
    }
    _calendarMonth = DateTime(_startDate.year, _startDate.month, 1);
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
        return Colors.teal;
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
    int selectedMinuteIndex = 0;

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
    final minutesList = List.generate(12, (index) => index * 5);

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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        titleLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          final hStr = selectedHour.toString().padLeft(2, '0');
                          final mStr = minutesList[selectedMinuteIndex].toString().padLeft(2, '0');
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
                      Expanded(
                        child: CupertinoPicker(
                          magnification: 1.2,
                          squeeze: 1.2,
                          useMagnifier: true,
                          itemExtent: 36,
                          scrollController: FixedExtentScrollController(initialItem: selectedHour),
                          onSelectedItemChanged: (int index) => selectedHour = index,
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
                      Expanded(
                        child: CupertinoPicker(
                          magnification: 1.2,
                          squeeze: 1.2,
                          useMagnifier: true,
                          itemExtent: 36,
                          scrollController: FixedExtentScrollController(initialItem: selectedMinuteIndex),
                          onSelectedItemChanged: (int index) => selectedMinuteIndex = index,
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
      text: currentHours > 0 ? '$currentHours' : '',
    );
    final minsController = TextEditingController(
      text: currentMins > 0 ? '$currentMins' : '',
    );

    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            '알림 시간 직접 설정',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: hoursController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '0', suffixText: '시간'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: minsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '0', suffixText: '분 전'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final h = int.tryParse(hoursController.text.trim()) ?? 0;
                final m = int.tryParse(minsController.text.trim()) ?? 0;
                final totalMins = (h * 60) + m;
                Navigator.pop(ctx, totalMins);
              },
              child: const Text('설정'),
            ),
          ],
        );
      },
    );
  }

  void _onInlineCalendarDayTap(DateTime day) {
    setState(() {
      final selectedDayOnly = DateTime(day.year, day.month, day.day);

      if (!_isSelectingRangeEnd) {
        _startDate = selectedDayOnly;
        _endDate = null;
        _isSelectingRangeEnd = true;
      } else {
        if (selectedDayOnly.isBefore(_startDate)) {
          _startDate = selectedDayOnly;
          _endDate = null;
          _isSelectingRangeEnd = true;
        } else if (selectedDayOnly.isAtSameMomentAs(_startDate)) {
          _endDate = null;
          _isSelectingRangeEnd = false;
          _isCalendarExpanded = false;
        } else {
          _endDate = selectedDayOnly;
          _isSelectingRangeEnd = false;
          _isCalendarExpanded = false;
        }
      }
    });
  }

  Widget _buildInlineCalendarGrid(ThemeData theme, bool isDark) {
    final firstOfMonth = DateTime(_calendarMonth.year, _calendarMonth.month, 1);
    final lastOfMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0);
    final firstDisplayDate = firstOfMonth.subtract(Duration(days: firstOfMonth.weekday - 1));
    final lastDisplayDate = lastOfMonth.add(Duration(days: 7 - lastOfMonth.weekday));

    final totalDays = lastDisplayDate.difference(firstDisplayDate).inDays + 1;
    final weeks = <List<DateTime>>[];
    for (int i = 0; i < totalDays; i += 7) {
      weeks.add(
        List.generate(7, (wIndex) {
          return firstDisplayDate.add(Duration(days: i + wIndex));
        }),
      );
    }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: () {
                  setState(() {
                    _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1, 1);
                  });
                },
              ),
              Text(
                DateFormat('yyyy년 MM월').format(_calendarMonth),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () {
                  setState(() {
                    _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdayNames.map((name) {
              return SizedBox(
                width: 32,
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          Column(
            children: weeks.map((week) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: week.map((day) {
                    final dayOnly = DateTime(day.year, day.month, day.day);
                    final startOnly = DateTime(_startDate.year, _startDate.month, _startDate.day);
                    final endOnly = _endDate != null ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day) : null;

                    final isStart = dayOnly.isAtSameMomentAs(startOnly);
                    final isEnd = endOnly != null && dayOnly.isAtSameMomentAs(endOnly);
                    final isInRange = endOnly != null && dayOnly.isAfter(startOnly) && dayOnly.isBefore(endOnly);
                    final isOutsideMonth = day.month != _calendarMonth.month;

                    BoxDecoration cellDeco;
                    TextStyle textStyle;

                    if (isStart || isEnd) {
                      cellDeco = BoxDecoration(
                        color: _getQColor(_selectedQ),
                        shape: BoxShape.circle,
                      );
                      textStyle = const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12);
                    } else if (isInRange) {
                      cellDeco = BoxDecoration(
                        color: _getQColor(_selectedQ).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      );
                      textStyle = TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      );
                    } else {
                      cellDeco = const BoxDecoration(shape: BoxShape.circle);
                      textStyle = TextStyle(
                        color: isOutsideMonth
                            ? (isDark ? Colors.white24 : Colors.black26)
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontSize: 12,
                      );
                    }

                    return GestureDetector(
                      onTap: () => _onInlineCalendarDayTap(day),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: cellDeco,
                        alignment: Alignment.center,
                        child: Text('${day.day}', style: textStyle),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final categories = widget.provider.categories;

    String dateRangeText;
    if (_endDate == null) {
      dateRangeText = '시작: ${DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_startDate)}';
    } else {
      dateRangeText =
          '${DateFormat('MM/dd(E)', 'ko_KR').format(_startDate)} ~ ${DateFormat('MM/dd(E)', 'ko_KR').format(_endDate!)}';
    }

    final weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getQColor(_selectedQ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '신규 루틴 등록',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Input
                  TextField(
                    controller: _titleController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: '루틴 제목을 입력하세요 (예: 영양제 먹기)...',
                      prefixIcon: Icon(Icons.autorenew_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Start/End Date Inline Range Selector
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isCalendarExpanded = !_isCalendarExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_month_rounded, size: 18, color: _getQColor(_selectedQ)),
                              const SizedBox(width: 8),
                              Text(
                                dateRangeText,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Icon(
                            _isCalendarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_isCalendarExpanded) _buildInlineCalendarGrid(theme, isDark),
                  const SizedBox(height: 12),

                  // Weekday Selection Chips
                  Text(
                    '반복 요일 설정',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('매일', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: _selectedDays.length == 7,
                        selectedColor: AppColors.q2,
                        showCheckmark: false,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedDays = [1, 2, 3, 4, 5, 6, 7];
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('평일(월~금)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: _selectedDays.length == 5 && !_selectedDays.contains(6) && !_selectedDays.contains(7),
                        selectedColor: AppColors.q2,
                        showCheckmark: false,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedDays = [1, 2, 3, 4, 5];
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('주말(토,일)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: _selectedDays.length == 2 && _selectedDays.contains(6) && _selectedDays.contains(7),
                        selectedColor: AppColors.q2,
                        showCheckmark: false,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedDays = [6, 7];
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: List.generate(7, (idx) {
                      final dayNum = idx + 1;
                      final isSelected = _selectedDays.contains(dayNum);

                      return FilterChip(
                        label: Text(
                          weekdayLabels[idx],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.q2,
                        backgroundColor: isDark ? AppColors.darkInputBg : AppColors.lightInputBg,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              if (!_selectedDays.contains(dayNum)) _selectedDays.add(dayNum);
                            } else {
                              if (_selectedDays.length > 1) _selectedDays.remove(dayNum);
                            }
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Start & Due Time Row
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _timeController,
                          readOnly: true,
                          onTap: () => _pickTimeForController(_timeController, '시작 시간'),
                          decoration: InputDecoration(
                            hintText: '시작 시간⏱️',
                            prefixIcon: const Icon(Icons.access_time_rounded, size: 18),
                            suffixIcon: _timeController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () => setState(() => _timeController.clear()),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            hintText: '위치/장소📍',
                            prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Memo Input
                  TextField(
                    controller: _memoController,
                    maxLines: 1,
                    decoration: const InputDecoration(
                      hintText: '상세 메모 및 주요 노트 입력...',
                      prefixIcon: Icon(Icons.notes_rounded, size: 18),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Notification Timing Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '알림 설정',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      SizedBox(
                        height: 24,
                        child: Switch.adaptive(
                          value: _hasNotification,
                          activeThumbColor: Colors.amber[700],
                          onChanged: (val) => setState(() => _hasNotification = val),
                        ),
                      ),
                    ],
                  ),
                  if (_hasNotification) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('정시', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            selected: _notificationOffset == 0,
                            selectedColor: Colors.amber[700],
                            showCheckmark: false,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                            onSelected: (val) {
                              if (val) setState(() => _notificationOffset = 0);
                            },
                          ),
                          const SizedBox(width: 4),
                          ChoiceChip(
                            label: const Text('10분 전', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            selected: _notificationOffset == 10,
                            selectedColor: Colors.amber[700],
                            showCheckmark: false,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                            onSelected: (val) {
                              if (val) setState(() => _notificationOffset = 10);
                            },
                          ),
                          const SizedBox(width: 4),
                          ChoiceChip(
                            label: const Text('30분 전', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            selected: _notificationOffset == 30,
                            selectedColor: Colors.amber[700],
                            showCheckmark: false,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                            onSelected: (val) {
                              if (val) setState(() => _notificationOffset = 30);
                            },
                          ),
                          const SizedBox(width: 4),
                          ChoiceChip(
                            label: const Text('1시간 전', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            selected: _notificationOffset == 60,
                            selectedColor: Colors.amber[700],
                            showCheckmark: false,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                            onSelected: (val) {
                              if (val) setState(() => _notificationOffset = 60);
                            },
                          ),
                          const SizedBox(width: 4),
                          ChoiceChip(
                            label: Text(
                              _notificationOffset != 0 &&
                                      _notificationOffset != 10 &&
                                      _notificationOffset != 30 &&
                                      _notificationOffset != 60
                                  ? '$_notificationOffset분 전'
                                  : '커스텀',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            selected: _notificationOffset != 0 &&
                                _notificationOffset != 10 &&
                                _notificationOffset != 30 &&
                                _notificationOffset != 60,
                            selectedColor: Colors.amber[700],
                            showCheckmark: false,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
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
                  ],
                  const SizedBox(height: 12),

                  // Category Selection
                  if (categories.isNotEmpty) ...[
                    Text(
                      '카테고리 선택',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
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
                          selectedColor: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
                          backgroundColor: Colors.transparent,
                          showCheckmark: false,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                          onSelected: (val) {
                            if (val) setState(() => _selectedCategoryId = null);
                          },
                        ),
                        ...categories.map((cat) {
                          final isSelected = _selectedCategoryId == cat.id;
                          final catColor = Color(int.parse(cat.colorHex.replaceFirst('#', '0xFF')));

                          return ChoiceChip(
                            label: Text(
                              '${cat.emoji} ${cat.name}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: catColor,
                            backgroundColor: catColor.withValues(alpha: 0.15),
                            showCheckmark: false,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                            onSelected: (val) {
                              if (val) setState(() => _selectedCategoryId = cat.id);
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Quadrant Priority Chips
                  Text(
                    '우선순위 사분면 지정',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [1, 2, 3, 4].map((q) {
                      final isSelected = _selectedQ == q;
                      final color = _getQColor(q);

                      return ChoiceChip(
                        label: Text(
                          '${_getQShortName(q)} (Q$q)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: color,
                        backgroundColor: color.withValues(alpha: 0.15),
                        showCheckmark: false,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                        onSelected: (val) {
                          if (val) setState(() => _selectedQ = q);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final title = _titleController.text.trim();
                if (title.isEmpty) return;

                _selectedDays.sort();
                final repeatDaysStr = _selectedDays.join(',');

                widget.onAddRoutine(
                  title,
                  _selectedQ,
                  _selectedCategoryId,
                  _selectedDays.length == 7 ? 'daily' : 'weekly',
                  repeatDaysStr,
                  _startDate,
                  _endDate,
                  _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
                  _timeController.text.trim().isNotEmpty ? _timeController.text.trim() : null,
                  _dueTimeController.text.trim().isNotEmpty ? _dueTimeController.text.trim() : null,
                  _memoController.text.trim().isNotEmpty ? _memoController.text.trim() : null,
                  _hasNotification,
                  _notificationOffset,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getQColor(_selectedQ),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                '루틴 저장하기',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
