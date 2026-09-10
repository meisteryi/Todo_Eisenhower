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
import '../widgets/settings_dialog.dart';
import '../widgets/workout_view.dart';
import '../widgets/add_workout_sheet.dart';
import '../widgets/weekly_workout_stats_dialog.dart';
import '../widgets/workout_calendar_dialog.dart';
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
    widget.provider.addListener(_onProviderChanged);
    _currentQuoteIndex = Random().nextInt(QuotesData.list.length);
    _pageController = PageController(
      initialPage: widget.provider.activeQuadrant,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.provider.loadTodos();
      _checkIncinerationAlert();
    });
  }

  void _onProviderChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.provider.removeListener(_onProviderChanged);
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

                  final today = DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                  );
                  if (targetDate != null && targetDate.isAfter(today)) {
                    final diffDays = targetDate.difference(today).inDays;
                    final msg = diffDays == 1
                        ? '내일로 미뤄졌습니다 ☀️'
                        : '$diffDays일 후로 미뤄졌습니다 📅';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"$title" $msg'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
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

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SettingsDialog(provider: widget.provider),
    );
  }

  void _showAddWorkoutSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddWorkoutSheet(provider: widget.provider),
    );
  }

  void _openWorkoutCalendarDialog() {
    showDialog(
      context: context,
      builder: (ctx) => WorkoutCalendarDialog(provider: widget.provider),
    );
  }

  void _openWeeklyWorkoutStatsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => WeeklyWorkoutStatsDialog(provider: widget.provider),
    );
  }

  Widget _buildGoogleAuthButton() {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user != null) {
          return GestureDetector(
            onTap: _openSettingsDialog,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              child: Tooltip(
                message: '${user.displayName ?? "계정"} - 앱 전체 설정',
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
            icon: const Icon(Icons.settings_outlined, color: AppColors.q2),
            tooltip: '앱 전체 설정 및 계정 로그인',
            onPressed: _openSettingsDialog,
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
                        _buildModeChip(
                          'workout',
                          '운동 기록',
                          Icons.fitness_center,
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
                            _buildModeChip(
                              'workout',
                              '운동 기록',
                              Icons.fitness_center,
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
              ] else ...[
                PopupMenuButton<String>(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.more_vert),
                      if (trashCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  tooltip: '더보기 메뉴',
                  onSelected: (value) async {
                    if (value == 'settings') _openSettingsDialog();
                    if (value == 'help') _openHelpGuideDialog();
                    if (value == 'category') _openCategoryManageDialog();
                    if (value == 'routine') _openRoutineManageDialog();
                    if (value == 'trash') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TrashScreen(provider: widget.provider),
                        ),
                      );
                      widget.provider.loadTodos();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(
                            Icons.settings_rounded,
                            color: AppColors.q2,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text('앱 전체 설정'),
                        ],
                      ),
                    ),
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
                    PopupMenuItem(
                      value: 'trash',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          const Text('소각장 보관함'),
                          if (trashCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$trashCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
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
                            _buildDesktopSidebar(context, trashCount, viewMode),
                            Expanded(
                              child: viewMode == 'workout'
                                  ? WorkoutView(provider: widget.provider)
                                  : (viewMode == 'todomate'
                                      ? TodoMateView(
                                          provider: widget.provider,
                                          onEditTodo: (todo) =>
                                              _showAddTaskSheet(todoToEdit: todo),
                                        )
                                      : _buildEisenhowerView()),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            if (viewMode == 'todomate')
                              DateStripHeader(provider: widget.provider),
                            Expanded(
                              child: viewMode == 'workout'
                                  ? WorkoutView(provider: widget.provider)
                                  : (viewMode == 'todomate'
                                      ? TodoMateView(
                                          provider: widget.provider,
                                          onEditTodo: (todo) =>
                                              _showAddTaskSheet(todoToEdit: todo),
                                        )
                                      : _buildEisenhowerView()),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (viewMode == 'workout') {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => AddWorkoutSheet(provider: widget.provider),
                );
              } else {
                _showAddTaskSheet();
              }
            },
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

  Widget _buildDesktopSidebar(BuildContext context, int trashCount, String viewMode) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentStreak = widget.provider.workoutStreak;

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : theme.cardColor,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SECTION 1: View Modes
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      '메인 뷰',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildSidebarNavItem(
                    icon: Icons.grid_view_rounded,
                    iconColor: AppColors.q1,
                    title: '매트릭스 뷰',
                    subtitle: '아이젠하워 4분면 우선순위',
                    isSelected: viewMode == 'eisenhower',
                    onTap: () => widget.provider.setViewMode('eisenhower'),
                  ),
                  _buildSidebarNavItem(
                    icon: Icons.calendar_view_day_rounded,
                    iconColor: AppColors.q2,
                    title: '투두메이트 뷰',
                    subtitle: '카테고리별 일자 리스트',
                    isSelected: viewMode == 'todomate',
                    onTap: () => widget.provider.setViewMode('todomate'),
                  ),
                  _buildSidebarNavItem(
                    icon: Icons.fitness_center_rounded,
                    iconColor: Colors.orangeAccent,
                    title: '운동 기록',
                    subtitle: '루틴 및 세트 일지',
                    isSelected: viewMode == 'workout',
                    trailing: currentStreak > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '🔥 $currentStreak일',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orangeAccent,
                              ),
                            ),
                          )
                        : null,
                    onTap: () => widget.provider.setViewMode('workout'),
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  const SizedBox(height: 12),

                  // SECTION 2: Mode-specific quick action & calendars
                  if (viewMode == 'workout') ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(
                        '운동 빠른 실행',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildSidebarNavItem(
                      icon: Icons.add_circle_outline_rounded,
                      iconColor: AppColors.q2,
                      title: '새 운동 추가',
                      onTap: _showAddWorkoutSheet,
                    ),
                    _buildSidebarNavItem(
                      icon: Icons.insights_rounded,
                      iconColor: Colors.purpleAccent,
                      title: '주간 운동 통계',
                      onTap: _openWeeklyWorkoutStatsDialog,
                    ),
                    _buildSidebarNavItem(
                      icon: Icons.calendar_month_rounded,
                      iconColor: Colors.orangeAccent,
                      title: '월간 오운완 달력',
                      onTap: _openWorkoutCalendarDialog,
                    ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(
                        '할 일 빠른 실행',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildSidebarNavItem(
                      icon: Icons.add_task_rounded,
                      iconColor: AppColors.q2,
                      title: '새 할 일 추가',
                      onTap: () => _showAddTaskSheet(),
                    ),
                    const SizedBox(height: 8),
                    DateStripHeader(provider: widget.provider),
                  ],

                  const SizedBox(height: 12),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  const SizedBox(height: 12),

                  // SECTION 3: Management & Tools
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      '관리 및 설정',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildSidebarNavItem(
                    icon: Icons.category_outlined,
                    iconColor: Colors.indigo,
                    title: '카테고리 관리',
                    onTap: _openCategoryManageDialog,
                  ),
                  _buildSidebarNavItem(
                    icon: Icons.autorenew_rounded,
                    iconColor: Colors.teal,
                    title: '루틴 관리',
                    onTap: _openRoutineManageDialog,
                  ),
                  _buildSidebarNavItem(
                    icon: Icons.delete_outline_rounded,
                    iconColor: Colors.redAccent,
                    title: '소각장 보관함',
                    trailing: trashCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$trashCount',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : null,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrashScreen(provider: widget.provider),
                        ),
                      );
                      widget.provider.loadTodos();
                    },
                  ),
                  _buildSidebarNavItem(
                    icon: Icons.settings_outlined,
                    iconColor: AppColors.q2,
                    title: '앱 전체 설정',
                    onTap: _openSettingsDialog,
                  ),
                  _buildSidebarNavItem(
                    icon: Icons.help_outline_rounded,
                    iconColor: Colors.blue,
                    title: '사용 설명서',
                    onTap: _openHelpGuideDialog,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: isSelected
            ? (isDark
                ? theme.colorScheme.surfaceContainerHighest
                : theme.primaryColor.withValues(alpha: 0.12))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? theme.primaryColor : iconColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? theme.primaryColor
                              : (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87),
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
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

    if (_isPanelVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients &&
            _pageController.page?.round() != widget.provider.activeQuadrant) {
          _pageController.jumpToPage(widget.provider.activeQuadrant);
        }
      });
    }

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
        if (widget.provider.q0Todos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: GestureDetector(
              onTap: () => _onQuadrantSelected(0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inbox, color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '미분류(인박스) 할 일 ${widget.provider.q0Todos.length}개가 있습니다. 탭하여 사분면으로 지정하세요!',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.amberAccent
                              : Colors.amber.shade900,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Colors.amber,
                    ),
                  ],
                ),
              ),
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
                        onEditTodo: (todo) =>
                            _showAddTaskSheet(todoToEdit: todo),
                      ),
                      TodoListPage(
                        quadrant: 1,
                        provider: widget.provider,
                        onCloseDetail: () =>
                            setState(() => _isPanelVisible = false),
                        onEditTodo: (todo) =>
                            _showAddTaskSheet(todoToEdit: todo),
                      ),
                      TodoListPage(
                        quadrant: 2,
                        provider: widget.provider,
                        onCloseDetail: () =>
                            setState(() => _isPanelVisible = false),
                        onEditTodo: (todo) =>
                            _showAddTaskSheet(todoToEdit: todo),
                      ),
                      TodoListPage(
                        quadrant: 3,
                        provider: widget.provider,
                        onCloseDetail: () =>
                            setState(() => _isPanelVisible = false),
                        onEditTodo: (todo) =>
                            _showAddTaskSheet(todoToEdit: todo),
                      ),
                      TodoListPage(
                        quadrant: 4,
                        provider: widget.provider,
                        onCloseDetail: () =>
                            setState(() => _isPanelVisible = false),
                        onEditTodo: (todo) =>
                            _showAddTaskSheet(todoToEdit: todo),
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
