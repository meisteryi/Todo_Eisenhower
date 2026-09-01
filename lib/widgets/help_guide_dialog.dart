import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HelpGuideDialog extends StatelessWidget {
  const HelpGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: DefaultTabController(
          length: 4,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Row(
                children: [
                  Icon(Icons.help_outline_rounded, color: AppColors.q2),
                  SizedBox(width: 8),
                  Text('사용 설명서 & 기능 안내', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: '닫기',
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                indicatorColor: AppColors.q2,
                labelColor: AppColors.q2,
                unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.grid_view_rounded, size: 18), text: '매트릭스 사분면'),
                  Tab(icon: Icon(Icons.local_fire_department_rounded, size: 18), text: 'Q4 자동 소각'),
                  Tab(icon: Icon(Icons.calendar_view_day_rounded, size: 18), text: '투두메이트 & 루틴'),
                  Tab(icon: Icon(Icons.timer_outlined, size: 18), text: '뽀모도로 타이머'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildMatrixGuide(context, isDark),
                _buildIncineratorGuide(context, isDark),
                _buildTodoMateGuide(context, isDark),
                _buildPomodoroGuide(context, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatrixGuide(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '💡 아이젠하워 매트릭스란?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          '긴급성과 중요도를 기준으로 할 일을 4개의 사분면으로 분류하여 최선의 시간 관리를 도와주는 시스템입니다.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        _buildQuadrantCard(
          title: '1사분면 (Q1) - 긴급하고 중요함',
          subtitle: '즉시 실행해야 하는 위기 및 마감 직전의 필수 과제',
          color: AppColors.q1,
          icon: Icons.priority_high_rounded,
          badge: 'DO FIRST',
          isDark: isDark,
        ),
        _buildQuadrantCard(
          title: '2사분면 (Q2) - 긴급하지 않지만 중요함',
          subtitle: '장기 성장을 위해 가장 집중해야 할 핵심 목표 및 계획 (운동, 공부, 건강)',
          color: AppColors.q2,
          icon: Icons.star_rounded,
          badge: 'SCHEDULE',
          isDark: isDark,
        ),
        _buildQuadrantCard(
          title: '3사분면 (Q3) - 긴급하지만 중요하지 않음',
          subtitle: '빠르게 처리하거나 타인에게 위임해야 할 단순 요청 및 소음',
          color: AppColors.q3,
          icon: Icons.bolt_rounded,
          badge: 'DELEGATE',
          isDark: isDark,
        ),
        _buildQuadrantCard(
          title: '4사분면 (Q4) - 긴급하지도 중요하지도 않음',
          subtitle: '시간을 낭비하게 만드는 불필요한 요소 (7일 방치 시 자동 소각)',
          color: AppColors.q4,
          icon: Icons.delete_sweep_rounded,
          badge: 'ELIMINATE',
          isDark: isDark,
        ),
        _buildQuadrantCard(
          title: '임시 보관함 (Q0) - 미분류',
          subtitle: '아직 사분면을 정하지 않은 할 일을 임시 보관하는 공간',
          color: AppColors.q0,
          icon: Icons.inbox_rounded,
          badge: 'INBOX',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildIncineratorGuide(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 36),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '자동 소각 시스템 규칙',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Q4 사분면의 방치된 항목을 자동으로 정리하여 중요한 일에만 집중할 수 있도록 돕습니다.',
                      style: TextStyle(fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildRuleStep(
          stepNumber: '1',
          title: '7일 자동 소각 주기',
          description: 'Q4 사분면(긴급하지도 중요하지도 않은 일)에 등록된 태스크가 생성 후 7일(168시간) 동안 완료되지 않으면, 앱 실행 시 자동으로 소각됩니다.',
          icon: Icons.timer_3_rounded,
          isDark: isDark,
        ),
        _buildRuleStep(
          stepNumber: '2',
          title: '소각장 보관함 (휴지통) 이관',
          description: '소각된 태스크는 완전히 사라지지 않고 [소각장 보관함]으로 안전하게 이동합니다. 상단 불꽃/휴지통 아이콘을 눌러 확인할 수 있습니다.',
          icon: Icons.delete_outline_rounded,
          isDark: isDark,
        ),
        _buildRuleStep(
          stepNumber: '3',
          title: '언제든지 복원 가능',
          description: '소각장에 보관된 태스크는 [복원] 버튼을 눌러 언제든지 원래 사분면으로 복원하거나, 필요 없으면 [영구 삭제]할 수 있습니다.',
          icon: Icons.restore_rounded,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildTodoMateGuide(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFeatureItem(
          icon: Icons.calendar_view_day_rounded,
          iconColor: Colors.teal,
          title: '투두메이트 뷰',
          description: '날짜별 주간 스트립 헤더를 이용하여 매일매일의 할 일을 일자별, 카테고리별로 깔끔하게 모아볼 수 있습니다.',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.category_rounded,
          iconColor: Colors.indigo,
          title: '카테고리 커스텀',
          description: '원하는 이모지, 색상, 카테고리명을 직접 등록하여 업무, 학업, 운동, 개인 라이프스타일에 맞게 할 일을 분류하세요.',
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.autorenew_rounded,
          iconColor: Colors.purple,
          title: '루틴 자동화',
          description: '매일 또는 특정 요일(월/수/금 등)에 반복되는 습관이나 업무를 루틴으로 설정하면 지정된 날짜에 할 일이 자동으로 생성됩니다.',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildPomodoroGuide(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.q2.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.q2.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.timer_outlined, color: AppColors.q2, size: 36),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '25분 뽀모도로 집중 타이머',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.q2),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '몰입 상태를 유지하도록 도와주는 뽀모도로 기법으로 태스크를 완성하세요.',
                      style: TextStyle(fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildRuleStep(
          stepNumber: '1',
          title: '타이머 시작',
          description: '할 일 카드 우측의 타이머(⏱️) 아이콘을 터치하면 25분 카운트다운 집중 타이머가 동작합니다.',
          icon: Icons.play_arrow_rounded,
          isDark: isDark,
        ),
        _buildRuleStep(
          stepNumber: '2',
          title: '자동 완료 처리',
          description: '25분 타이머가 모두 완료되면 알림과 함께 해당 할 일이 자동으로 완료(체크) 처리됩니다.',
          icon: Icons.check_circle_outline_rounded,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildQuadrantCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required String badge,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleStep({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.q2,
            child: Text(
              stepNumber,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: AppColors.q2),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
