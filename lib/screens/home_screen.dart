import 'dart:math';
import 'package:flutter/material.dart';
import '../models/quote_model.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';
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
  bool _isPanelVisible = false; // State to track collapse/expand lists
  int _currentQuoteIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentQuoteIndex = Random().nextInt(QuotesData.list.length);
    // Default PageView index corresponds to activeQuadrant - 1
    _pageController = PageController(
      initialPage: widget.provider.activeQuadrant,
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

    final isActive = widget.provider.activeQuadrant == index;
    final wasVisible = _isPanelVisible;

    if (wasVisible && isActive) {
      // Collapse panel if active quadrant is tapped again
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
          // Jump immediately if the panel was closed so the correct page slides up
          _pageController.jumpToPage(index);
          _isPageChanging = false;
        } else {
          // Slide smoothly if the panel was already open
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

  // Handle PageView swiping
  void _onPageChanged(int pageIndex) {
    if (_isPageChanging) return;
    widget.provider.setActiveQuadrant(pageIndex);
  }

  // Show Quick Task Entry Bottom Sheet
  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AddTaskSheet(
          initialQuadrant: widget.provider.activeQuadrant,
          onAddTask: (title, quadrant, dueDate) {
            widget.provider.addTodo(title, quadrant, dueDate: dueDate);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"$title" 할 일이 추가되었습니다.'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
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
        title: const Text('Matrix Todo'),
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
            // Animated height MiniMapTracker
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              height: _isPanelVisible ? 185 : 380,
              child: MiniMapTracker(
                provider: widget.provider,
                onQuadrantSelected: _onQuadrantSelected,
                isDashboard: !_isPanelVisible,
              ),
            ),

            // Visual divider (only when panel is visible)
            AnimatedCrossFade(
              firstChild: const Divider(height: 1),
              secondChild: const SizedBox.shrink(),
              crossFadeState: _isPanelVisible
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 300),
            ),

            // Scrollable list area (PageView)
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.4),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: _isPanelVisible
                    ? Column(
                        key: const ValueKey('expanded_panel'),
                        children: [
                          Expanded(
                            child: PageView(
                              controller: _pageController,
                              onPageChanged: _onPageChanged,
                              children: [
                                TodoListPage(
                                  quadrant: 0,
                                  provider: widget.provider,
                                ),
                                TodoListPage(
                                  quadrant: 1,
                                  provider: widget.provider,
                                ),
                                TodoListPage(
                                  quadrant: 2,
                                  provider: widget.provider,
                                ),
                                TodoListPage(
                                  quadrant: 3,
                                  provider: widget.provider,
                                ),
                                TodoListPage(
                                  quadrant: 4,
                                  provider: widget.provider,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Center(
                        key: const ValueKey('collapsed_tip'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Quote Card
                              Container(
                                width: double.infinity,
                                height: 125,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkCard
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.darkDivider
                                        : AppColors.lightDivider,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? 0.3
                                            : 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.format_quote_rounded,
                                      color: AppColors.q2.withValues(
                                        alpha: 0.7,
                                      ),
                                      size: 24,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      QuotesData.list[_currentQuoteIndex].text,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FontStyle.italic,
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '- ${QuotesData.list[_currentQuoteIndex].author}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Grid selection hint
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.touch_app_outlined,
                                    size: 16,
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '사분면을 탭하여 세부 할 일 목록을 확인하세요.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
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
