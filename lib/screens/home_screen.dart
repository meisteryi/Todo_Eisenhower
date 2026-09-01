import 'dart:math';
import 'package:flutter/material.dart';
import '../models/todo_model.dart';
import '../models/quote_model.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/date_strip_header.dart';
import '../widgets/todo_mate_view.dart';
import '../widgets/category_manage_dialog.dart';
import '../widgets/routine_manage_dialog.dart';
import '../widgets/mini_map_tracker.dart';
import '../widgets/todo_list_page.dart';
import '../widgets/add_task_sheet.dart';
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
  bool _isPanelVisible = false;
  int _currentQuoteIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentQuoteIndex = Random().nextInt(QuotesData.list.length);
    _pageController = PageController(
      initialPage: widget.provider.activeQuadrant,
    );

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
              const Icon(Icons.local_fire_department, color: Colors.orangeAccent),
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

  void _onQuadrantSelected(int index) {
    if (_isPageChanging) return;

    final isActive = widget.provider.activeQuadrant == index;
    final wasVisible = _isPanelVisible;

    if (wasVisible && isActive) {
      setState(() {
        _isPanelVisible = false;
      });
      return;
    }

    _isPageChanging = true;
    if (!wasVisible) {
      setState(() {
        _isPanelVisible = true;
      });
    }

    widget.provider.setActiveQuadrant(index);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        if (!wasVisible) {
          _pageController.jumpToPage(index);
          _isPageChanging = false;
        } else {
          _pageController
              .animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              )
              .then((_) {
                _isPageChanging = false;
              });
        }
      } else {
        _isPageChanging = false;
      }
    });
  }

  void _onPageChanged(int pageIndex) {
    if (_isPageChanging) return;
    widget.provider.setActiveQuadrant(pageIndex);
  }

  void _showAddTaskSheet({Todo? todoToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AddTaskSheet(
          initialQuadrant: todoToEdit?.quadrant ?? widget.provider.activeQuadrant,
          categories: widget.provider.categories,
          initialCategoryId: todoToEdit?.categoryId,
          initialTargetDate: todoToEdit?.targetDate ?? widget.provider.selectedDate,
          onAddTask: (title, quadrant, categoryId, targetDate, dueDate) {
            if (todoToEdit == null) {
              widget.provider.addTodo(
                title,
                quadrant,
                categoryId: categoryId,
                targetDate: targetDate,
                dueDate: dueDate,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"$title" 할 일이 추가되었습니다.'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else {
              final updated = todoToEdit.copyWith(
                title: title,
                quadrant: quadrant,
                categoryId: categoryId,
                targetDate: targetDate,
                dueDate: dueDate,
              );
              widget.provider.updateTodo(updated);
            }
          },
        );
      },
    );
  }

  void _openCategoryManageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => CategoryManageDialog(provider: widget.provider),
    );
  }

  void _openRoutineManageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => RoutineManageDialog(provider: widget.provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trashCount = widget.provider.trashTodos.length;
    final viewMode = widget.provider.activeViewMode;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 700;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_box_outlined, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text(
                  '아이젠하워 투두',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        _buildModeChip('eisenhower', '매트릭스 뷰', Icons.grid_view),
                        _buildModeChip('todomate', '투두메이트 뷰', Icons.calendar_view_day),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            bottom: !isDesktop
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(42),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildModeChip('eisenhower', '매트릭스 뷰', Icons.grid_view),
                            _buildModeChip('todomate', '투두메이트 뷰', Icons.calendar_view_day),
                          ],
                        ),
                      ),
                    ),
                  )
                : null,
            actions: [
              IconButton(
                icon: const Icon(Icons.category_outlined),
                tooltip: '카테고리 관리',
                onPressed: _openCategoryManageDialog,
              ),
              IconButton(
                icon: const Icon(Icons.autorenew_outlined),
                tooltip: '루틴 관리',
                onPressed: _openRoutineManageDialog,
              ),
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
                          builder: (context) => TrashScreen(provider: widget.provider),
                        ),
                      );
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
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
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
            child: isDesktop
                ? Row(
                    children: [
                      Container(
                        width: 280,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            DateStripHeader(provider: widget.provider),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '빠른 실행',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ListTile(
                                    leading: const Icon(Icons.category, color: Colors.indigo),
                                    title: const Text('카테고리 관리'),
                                    onTap: _openCategoryManageDialog,
                                    dense: true,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.autorenew, color: Colors.teal),
                                    title: const Text('루틴 관리'),
                                    onTap: _openRoutineManageDialog,
                                    dense: true,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    title: Text('소각장 보관함 ($trashCount)'),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TrashScreen(provider: widget.provider),
                                        ),
                                      );
                                    },
                                    dense: true,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: viewMode == 'todomate'
                            ? TodoMateView(
                                provider: widget.provider,
                                onEditTodo: (todo) => _showAddTaskSheet(todoToEdit: todo),
                              )
                            : _buildEisenhowerView(),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      if (viewMode == 'todomate') DateStripHeader(provider: widget.provider),
                      Expanded(
                        child: viewMode == 'todomate'
                            ? TodoMateView(
                                provider: widget.provider,
                                onEditTodo: (todo) => _showAddTaskSheet(todoToEdit: todo),
                              )
                            : _buildEisenhowerView(),
                      ),
                    ],
                  ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddTaskSheet(),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('할 일 추가', style: TextStyle(fontWeight: FontWeight.bold)),
            elevation: 4,
          ),
        );
      },
    );
  }

  Widget _buildModeChip(String modeKey, String label, IconData icon) {
    final isSelected = widget.provider.activeViewMode == modeKey;

    return GestureDetector(
      onTap: () {
        widget.provider.setViewMode(modeKey);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEisenhowerView() {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          height: _isPanelVisible ? 185 : 400,
          child: MiniMapTracker(
            provider: widget.provider,
            onQuadrantSelected: _onQuadrantSelected,
            isDashboard: !_isPanelVisible,
          ),
        ),
        AnimatedCrossFade(
          firstChild: const Divider(height: 1),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _isPanelVisible ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 300),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _isPanelVisible
                ? PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      TodoListPage(quadrant: 0, provider: widget.provider),
                      TodoListPage(quadrant: 1, provider: widget.provider),
                      TodoListPage(quadrant: 2, provider: widget.provider),
                      TodoListPage(quadrant: 3, provider: widget.provider),
                      TodoListPage(quadrant: 4, provider: widget.provider),
                    ],
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 125,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkCard
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkDivider
                                    : AppColors.lightDivider,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.format_quote_rounded, color: AppColors.q2.withValues(alpha: 0.7), size: 24),
                                const SizedBox(height: 6),
                                Text(
                                  QuotesData.list[_currentQuoteIndex].text,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '- ${QuotesData.list[_currentQuoteIndex].author}',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.touch_app_outlined, size: 16, color: Colors.grey),
                              SizedBox(width: 8),
                              Text(
                                '사분면을 탭하여 세부 할 일 목록을 확인하세요.',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
