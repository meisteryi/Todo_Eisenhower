import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../providers/todo_provider.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import 'help_guide_dialog.dart';
import '../screens/trash_screen.dart';

class SettingsDialog extends StatefulWidget {
  final TodoProvider provider;

  const SettingsDialog({super.key, required this.provider});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.settings_rounded, color: AppColors.q2, size: 24),
                    SizedBox(width: 8),
                    Text(
                      '앱 전체 설정',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 20),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: 계정 & 클라우드 동기화
                    _buildSectionHeader('👤 계정 및 클라우드 동기화', context),
                    const SizedBox(height: 8),
                    _buildAccountCard(user, isDark),
                    const SizedBox(height: 18),

                    // Section 2: 화면 및 테마 설정
                    _buildSectionHeader('🎨 화면 및 테마 설정', context),
                    const SizedBox(height: 8),
                    _buildCardWrapper(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. 기본 뷰 선택 (제목 & 설명 한 줄 + 아래에 토글 버튼)
                          Row(
                            children: [
                              const Icon(Icons.grid_view_rounded, color: AppColors.q1, size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                '기본 뷰 선택',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '(${widget.provider.activeViewMode == 'eisenhower' ? "매트릭스 뷰" : "투두메이트 뷰"})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<String>(
                              showSelectedIcon: false,
                              style: const ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              segments: const [
                                ButtonSegment(
                                  value: 'eisenhower',
                                  label: Text('매트릭스 뷰 🎯', style: TextStyle(fontSize: 12)),
                                ),
                                ButtonSegment(
                                  value: 'todomate',
                                  label: Text('투두메이트 뷰 📅', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                              selected: {widget.provider.activeViewMode},
                              onSelectionChanged: (newSelection) {
                                widget.provider.setViewMode(newSelection.first);
                                setState(() {});
                              },
                            ),
                          ),
                          const Divider(height: 20),

                          // 2. 매트릭스 기본 필터 (한 줄 가로 배치)
                          Row(
                            children: [
                              const Icon(Icons.tune_rounded, color: AppColors.q2, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    const Text(
                                      '매트릭스 필터',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        widget.provider.isMatrixFilterTodayOnly ? '🎯 오늘의 사분면' : '🌐 전체 사분면',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white60 : Colors.black54,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: widget.provider.isMatrixFilterTodayOnly,
                                  onChanged: (val) {
                                    widget.provider.setMatrixFilterTodayOnly(val);
                                    setState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Section 3: 소각장 (Q4 Incinerator) 규칙
                    _buildSectionHeader('🔥 4사분면 자동 소각 규칙', context),
                    const SizedBox(height: 8),
                    _buildCardWrapper(
                      isDark: isDark,
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Q4(삭제 대상) 소각 기한',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Q4 방치 태스크 7일 후 소각장 이동',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.deepOrangeAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '7일 소각',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Section 4: 데이터 관리 & 백업
                    _buildSectionHeader('📦 데이터 관리', context),
                    const SizedBox(height: 8),
                    _buildCardWrapper(
                      isDark: isDark,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    const Text(
                                      '소각장(휴지통)',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${widget.provider.trashTodos.length}개 보관 중',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 30,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TrashScreen(provider: widget.provider),
                                      ),
                                    );
                                    widget.provider.loadTodos();
                                  },
                                  child: const Text('보관함', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.cleaning_services_rounded, color: Colors.deepOrangeAccent, size: 18),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  '전체 일정 초기화',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 30,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: const BorderSide(color: Colors.redAccent),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () => _confirmClearAllTodos(context),
                                  child: const Text('모든 일정 삭제', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.menu_book_rounded, color: Colors.blue, size: 18),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  '사용 설명서 가이드',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 30,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    showDialog(
                                      context: context,
                                      builder: (context) => const HelpGuideDialog(),
                                    );
                                  },
                                  child: const Text('가이드 보기', style: TextStyle(fontSize: 11)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Section 5: 앱 정보
                    _buildSectionHeader('ℹ️ 앱 정보', context),
                    const SizedBox(height: 8),
                    _buildCardWrapper(
                      isDark: isDark,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('아이젠하워 투두 (Eisenhower)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('v1.0.0', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCardWrapper({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          width: 0.8,
        ),
      ),
      child: child,
    );
  }

  Widget _buildAccountCard(User? user, bool isDark) {
    final messenger = ScaffoldMessenger.of(context);

    if (user != null) {
      return _buildCardWrapper(
        isDark: isDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (user.photoURL != null)
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(user.photoURL!),
                  )
                else
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.q2,
                    child: Text(
                      (user.displayName ?? user.email ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? '구글 사용자',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        user.email ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_done_rounded, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '실시간 동기화 중',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 28,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: _isSyncing
                            ? const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync_rounded, size: 14),
                        label: const Text('수동 동기화', style: TextStyle(fontSize: 11)),
                        onPressed: _isSyncing
                            ? null
                            : () async {
                                setState(() => _isSyncing = true);
                                await SyncService.instance.startSync(
                                  user.uid,
                                  () => widget.provider.loadTodos(),
                                );
                                setState(() => _isSyncing = false);
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('⚡️ 클라우드 수동 동기화가 완료되었습니다!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                      ),
                    ),
                    SizedBox(
                      height: 28,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () async {
                          await AuthService().signOut();
                          setState(() {});
                          messenger.showSnackBar(
                            const SnackBar(content: Text('로그아웃 되었습니다.')),
                          );
                        },
                        child: const Text('로그아웃', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    return _buildCardWrapper(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Google 계정 연동 (미연동)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          const Text(
            '모든 기기(스마트폰, PC, Web)에서 일정이 실시간 동기화됩니다.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.login_rounded, size: 15),
              label: const Text('Google 계정 로그인', style: TextStyle(fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.q2,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () async {
                try {
                  final credential = await AuthService().signInWithGoogle();
                  if (credential != null) {
                    setState(() {});
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('🎉 ${credential.user?.displayName ?? "사용자"}님 환영합니다!'),
                        backgroundColor: Colors.green[700],
                      ),
                    );
                  }
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('로그인 오류: $e')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearAllTodos(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('전체 일정 초기화', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          '등록된 모든 일정을 완전히 삭제하시겠습니까?\n이 작업은 복구할 수 없습니다.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await widget.provider.clearAllTodos();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🧹 모든 일정 삭제가 완료되었습니다.'),
                    backgroundColor: Colors.deepOrange,
                  ),
                );
              }
            },
            child: const Text('전체 삭제'),
          ),
        ],
      ),
    );
  }
}
