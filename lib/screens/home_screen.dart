import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/mini_map_tracker.dart';
import '../widgets/todo_list_page.dart';
import 'trash_screen.dart';

class HomeScreen extends StatefulWidget {
  final TodoProvider provider;

  const HomeScreen({super.key, required this.provider});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  bool _isPageChanging = false;

  @override
  void initState() {
    super.initState();
    // Default PageView index corresponds to activeQuadrant - 1
    _pageController = PageController(
      initialPage: widget.provider.activeQuadrant - 1,
    );

    // Fetch todos and check for incinerated tasks on startup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.provider.loadTodos();
      _checkIncinerationAlert();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _checkIncinerationAlert() {
    final count = widget.provider.lastIncineratedCount;
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Colors.orangeAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$count개의 오랫동안 방치된 태스크가 소각되어 휴지통으로 이동했습니다.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: '보기',
            textColor: Colors.orangeAccent,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TrashScreen(provider: widget.provider),
                ),
              );
            },
          ),
        ),
      );
      widget.provider.clearLastIncineratedCount();
    }
  }

  // Handle tap on MiniMapTracker grid
  void _onQuadrantSelected(int index) {
    if (_isPageChanging) return;
    _isPageChanging = true;
    widget.provider.setActiveQuadrant(index);
    _pageController
        .animateToPage(
          index - 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
        .then((_) {
          _isPageChanging = false;
        });
  }

  // Handle PageView swiping
  void _onPageChanged(int pageIndex) {
    if (_isPageChanging) return;
    widget.provider.setActiveQuadrant(pageIndex + 1);
  }

  // Show Quick Task Entry Bottom Sheet
  void _showAddTaskSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final titleController = TextEditingController();
    int selectedQ = widget.provider.activeQuadrant;
    DateTime? selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Color getQColor(int q) {
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

            void submitTask() {
              final text = titleController.text.trim();
              if (text.isEmpty) return;

              widget.provider.addTodo(text, selectedQ, dueDate: selectedDate);

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"$text" 할 일이 추가되었습니다.'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }

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
                      controller: titleController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: '할 일을 입력하세요...',
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
                            color: getQColor(selectedQ),
                            width: 2.0,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => submitTask(),
                    ),
                    const SizedBox(height: 16),

                    // Quadrant Segment Selection
                    Text(
                      '사분면 영역 지정',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [1, 2, 3, 4].map((q) {
                        final isSelected = selectedQ == q;
                        final qColor = getQColor(q);
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
                                setModalState(() {
                                  selectedQ = q;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? qColor
                                      : (isDark
                                            ? AppColors.darkBg
                                            : Colors.grey[100]),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? qColor
                                        : Colors.transparent,
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
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              selectedDate == null
                                  ? '마감 기한 지정 안 함'
                                  : '기한: ${DateFormat('yyyy.MM.dd HH:mm').format(selectedDate!)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: selectedDate == null
                                    ? (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary)
                                    : getQColor(selectedQ),
                                fontWeight: selectedDate == null
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 30),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 5),
                              ),
                            );

                            if (pickedDate != null) {
                              if (!context.mounted) return;
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: selectedDate != null
                                    ? TimeOfDay.fromDateTime(selectedDate!)
                                    : const TimeOfDay(hour: 12, minute: 0),
                              );

                              setModalState(() {
                                selectedDate = DateTime(
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
                        backgroundColor: getQColor(selectedQ),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: submitTask,
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final trashCount = widget.provider.trashTodos.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('아이젠하워 매트릭스 투두'),
        actions: [
          // Recycle Bin Navigation Button with Count Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline_outlined, size: 24),
                tooltip: '소각장 보관함',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TrashScreen(provider: widget.provider),
                    ),
                  );
                  // Refresh list after returning
                  widget.provider.loadTodos();
                },
              ),
              if (trashCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '$trashCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top fixed Grid tracker mini map
            MiniMapTracker(
              provider: widget.provider,
              onQuadrantSelected: _onQuadrantSelected,
            ),
            const Divider(height: 1),
            // Swipeable body view
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  TodoListPage(quadrant: 1, provider: widget.provider),
                  TodoListPage(quadrant: 2, provider: widget.provider),
                  TodoListPage(quadrant: 3, provider: widget.provider),
                  TodoListPage(quadrant: 4, provider: widget.provider),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskSheet,
        backgroundColor: AppColors.q2,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
