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
import '../widgets/help_guide_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'trash_screen.dart';

class HomeScreen extends StatefulWidget {
  final TodoProvider provider;

  const HomeScreen({super.key, required this.provider});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late PageController _pageController;
  bool _isPageChanging = false;
  bool _isPanelVisible = false;
  int _currentQuoteIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.provider.loadTodos();
    }
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
          initialQuadrant:
              todoToEdit?.quadrant ?? widget.provider.activeQuadrant,
          categories: widget.provider.categories,
          initialCategoryId: todoToEdit?.categoryId,
          initialTargetDate:
              todoToEdit?.targetDate ?? widget.provider.selectedDate,
          initialTodo: todoToEdit,
          onAddTask:
              (
                title,
                quadrant,
                categoryId,
                targetDate,
                dueDate,
                location,
                timeStr,
                dueTimeStr,
                memo,
                hasNotification,
                notificationOffset,
              ) {
                if (todoToEdit == null) {
                  widget.provider.addTodo(
                    title,
                    quadrant,
                    categoryId: categoryId,
                    targetDate: targetDate,
                    dueDate: dueDate,
                    location: location,
                    timeStr: timeStr,
                    dueTimeStr: dueTimeStr,
                    memo: memo,
                    hasNotification: hasNotification,
                    notificationOffset: notificationOffset,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"$title" 할 일이 추가되었습니다.'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  final enteringQ4 = quadrant == 4 && todoToEdit.quadrant != 4;
                  final updated = todoToEdit.copyWith(
                    title: title,
                    quadrant: quadrant,
                    categoryId: categoryId,
                    targetDate: targetDate,
                    dueDate: dueDate,
                    location: location,
                    timeStr: timeStr,
                    dueTimeStr: dueTimeStr,
                    memo: memo,
                    hasNotification: hasNotification,
                    notificationOffset: notificationOffset,
                    createdAt: enteringQ4
                        ? DateTime.now()
                        : todoToEdit.createdAt,
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

  void _openHelpGuideDialog() {
    showDialog(context: context, builder: (ctx) => const HelpGuideDialog());
  }

  void _showProfileDialog(User user) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.account_circle, color: AppColors.q2),
              SizedBox(width: 8),
              Text('내 계정 정보'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user.photoURL != null)
                CircleAvatar(
                  radius: 36,
                  backgroundImage: NetworkImage(user.photoURL!),
                )
              else
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.q2,
                  child: Text(
                    (user.displayName ?? user.email ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                user.displayName ?? '구글 사용자',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email ?? '',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_done_rounded,
                      size: 14,
                      color: Colors.green,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Google 계정 연동 완료',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                await AuthService().signOut();
                messenger.showSnackBar(
                  const SnackBar(content: Text('로그아웃 되었습니다.')),
                );
              },
              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
              label: const Text(
                '로그아웃',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGoogleAuthButton() {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user != null) {
          return GestureDetector(
            onTap: () => _showProfileDialog(user),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Tooltip(
                message: '${user.displayName ?? "프로필"} 계정 정보',
                child: user.photoURL != null
                    ? CircleAvatar(
                        radius: 14,
                        backgroundImage: NetworkImage(user.photoURL!),
                      )
                    : CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.q2,
                        child: Text(
                          (user.displayName ?? user.email ?? 'U')[0]
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),
          );
        } else {
          return IconButton(
            icon: const Icon(Icons.login_rounded, color: AppColors.q2),
            tooltip: '구글 계정 로그인',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final credential = await AuthService().signInWithGoogle();
                if (credential != null) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        '🎉 ${credential.user?.displayName ?? "사용자"}님 환영합니다!',
                      ),
                      backgroundColor: Colors.green[700],
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orangeAccent,
                          ),
                          SizedBox(width: 8),
                          Text('구글 로그인 안내', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      content: SelectableText(
                        '오류 메세지:\n$e',
                        style: const TextStyle(fontSize: 13),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('확인'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
          );
        }
      },
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
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        _buildModeChip('eisenhower', '매트릭스 뷰', Icons.grid_view),
                        _buildModeChip(
                          'todomate',
                          '투두메이트 뷰',
                          Icons.calendar_view_day,
                        ),
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
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildModeChip(
                              'eisenhower',
                              '매트릭스 뷰',
                              Icons.grid_view,
                            ),
                            _buildModeChip(
                              'todomate',
                              '투두메이트 뷰',
                              Icons.calendar_view_day,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : null,
            actions: [
              _buildGoogleAuthButton(),
              if (isDesktop) ...[
                IconButton(
                  icon: const Icon(Icons.help_outline_rounded),
                  tooltip: '사용 설명서',
                  onPressed: _openHelpGuideDialog,
                ),
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
              ] else ...[
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: '더보기 메뉴',
                  onSelected: (value) {
                    if (value == 'help') _openHelpGuideDialog();
                    if (value == 'category') _openCategoryManageDialog();
                    if (value == 'routine') _openRoutineManageDialog();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'help',
                      child: Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text('사용 설명서'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'category',
                      child: Row(
                        children: [
                          Icon(Icons.category, color: Colors.indigo, size: 20),
                          SizedBox(width: 10),
                          Text('카테고리 관리'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'routine',
                      child: Row(
                        children: [
                          Icon(Icons.autorenew, color: Colors.teal, size: 20),
                          SizedBox(width: 10),
                          Text('루틴 관리'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
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
                _buildActivePomodoroBar(),
                Expanded(
                  child: isDesktop
                      ? Row(
                          children: [
                            Container(
                              width: 280,
                              alignment: Alignment.topCenter,
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).dividerColor.withValues(alpha: 0.1),
                                  ),
                                ),
                              ),
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    DateStripHeader(provider: widget.provider),
                                    const Divider(height: 1),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            leading: const Icon(
                                              Icons.help_outline,
                                              color: Colors.blue,
                                            ),
                                            title: const Text('사용 설명서'),
                                            onTap: _openHelpGuideDialog,
                                            dense: true,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          ListTile(
                                            leading: const Icon(
                                              Icons.category,
                                              color: Colors.indigo,
                                            ),
                                            title: const Text('카테고리 관리'),
                                            onTap: _openCategoryManageDialog,
                                            dense: true,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          ListTile(
                                            leading: const Icon(
                                              Icons.autorenew,
                                              color: Colors.teal,
                                            ),
                                            title: const Text('루틴 관리'),
                                            onTap: _openRoutineManageDialog,
                                            dense: true,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          ListTile(
                                            leading: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                            ),
                                            title: Text(
                                              '소각장 보관함 ($trashCount)',
                                            ),
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      TrashScreen(
                                                        provider:
                                                            widget.provider,
                                                      ),
                                                ),
                                              );
                                            },
                                            dense: true,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: viewMode == 'todomate'
                                  ? TodoMateView(
                                      provider: widget.provider,
                                      onEditTodo: (todo) =>
                                          _showAddTaskSheet(todoToEdit: todo),
                                    )
                                  : _buildEisenhowerView(),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            if (viewMode == 'todomate')
                              DateStripHeader(provider: widget.provider),
                            Expanded(
                              child: viewMode == 'todomate'
                                  ? TodoMateView(
                                      provider: widget.provider,
                                      onEditTodo: (todo) =>
                                          _showAddTaskSheet(todoToEdit: todo),
                                    )
                                  : _buildEisenhowerView(),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddTaskSheet(),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            elevation: 4,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildActivePomodoroBar() {
    final provider = widget.provider;
    if (provider.pomodoroTodoId == null) return const SizedBox.shrink();

    final activeTodo = provider.todos.firstWhere(
      (t) => t.id == provider.pomodoroTodoId,
      orElse: () => Todo(title: '할 일', quadrant: 1, createdAt: DateTime.now()),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.q1,
        boxShadow: [
          BoxShadow(
            color: AppColors.q1.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.timer_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '⏱️ 뽀모도로 몰입 중',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    activeTodo.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                provider.pomodoroTimeFormatted,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                provider.isTimerRunning
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
                color: Colors.white,
                size: 26,
              ),
              onPressed: () {
                if (provider.isTimerRunning) {
                  provider.pausePomodoro();
                } else {
                  if (activeTodo.id != null) {
                    provider.startPomodoro(activeTodo.id!);
                  }
                }
              },
              tooltip: provider.isTimerRunning ? '일시 정지' : '다시 시작',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
            IconButton(
              icon: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                provider.toggleTodoCompletion(activeTodo);
              },
              tooltip: '완료 처리',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white70,
                size: 20,
              ),
              onPressed: () {
                provider.stopPomodoro();
              },
              tooltip: '타이머 종료',
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
          ],
        ),
      ),
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
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrixFilterChip(bool isTodayOnly, String label) {
    final isSelected = widget.provider.isMatrixFilterTodayOnly == isTodayOnly;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        widget.provider.setMatrixFilterTodayOnly(isTodayOnly);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildEisenhowerView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 700;
    return Column(
      children: [
        // Matrix Filter Header (오늘의 사분면 vs 전체 사분면)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    widget.provider.isMatrixFilterTodayOnly
                        ? Icons.today_rounded
                        : Icons.language_rounded,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.provider.isMatrixFilterTodayOnly
                        ? '오늘의 사분면 모드'
                        : '전체 사분면 모드',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMatrixFilterChip(true, '오늘의 사분면 🎯'),
                    _buildMatrixFilterChip(false, '전체 사분면 🌐'),
                  ],
                ),
              ),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          height: _isPanelVisible ? 185 : (isDesktop ? 320 : 360),
          child: MiniMapTracker(
            provider: widget.provider,
            onQuadrantSelected: _onQuadrantSelected,
            isDashboard: !_isPanelVisible,
          ),
        ),
        AnimatedCrossFade(
          firstChild: const Divider(height: 1),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _isPanelVisible
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 300),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            layoutBuilder:
                (Widget? currentChild, List<Widget> previousChildren) {
                  return ClipRect(
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: <Widget>[...previousChildren, ?currentChild],
                    ),
                  );
                },
            child: _isPanelVisible
                ? PageView(
                    key: const ValueKey('matrix_detail_pageview'),
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      TodoListPage(
                        quadrant: 0,
                        provider: widget.provider,
                        onCloseDetail: () =>
                            setState(() => _isPanelVisible = false),
                      ),
                      TodoListPage(
                        quadrant: 1,
                        provider: widget.provider,
                        onCloseDetail: () =>
                            setState(() => _isPanelVisible = false),
                      ),
                      TodoListPage(
                        quadrant: 2,
                        provider: widget.provider,
                        onCloseDetail: () =>
                            setState(() => _isPanelVisible = false),
                      ),
                      TodoListPage(
                        quadrant: 3,
                        provider: widget.provider,
                        onCloseDetail: () =>
                            setState(() => _isPanelVisible = false),
                      ),
                      TodoListPage(
                        quadrant: 4,
                        provider: widget.provider,
                        onCloseDetail: () =>
                            setState(() => _isPanelVisible = false),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    key: const ValueKey('matrix_dashboard_scrollview'),
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkCard
                                : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? 0.15
                                      : 0.03,
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
                                color: AppColors.q2.withValues(alpha: 0.7),
                                size: 24,
                              ),
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
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '사분면을 탭하여 세부 할 일 목록을 확인하세요.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
