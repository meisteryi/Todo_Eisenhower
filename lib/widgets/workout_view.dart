import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';
import 'add_workout_sheet.dart';
import 'workout_calendar_dialog.dart';

class WorkoutView extends StatefulWidget {
  final TodoProvider provider;

  const WorkoutView({super.key, required this.provider});

  @override
  State<WorkoutView> createState() => _WorkoutViewState();
}

class _WorkoutViewState extends State<WorkoutView> {
  String _selectedCategoryFilter = '전체';

  final List<String> _categories = ['전체', '웨이트', '유산소', '스트레칭', '기타'];

  void _showAddWorkoutSheet({Workout? workoutToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddWorkoutSheet(
        provider: widget.provider,
        workoutToEdit: workoutToEdit,
      ),
    );
  }

  void _showCalendarDialog() {
    showDialog(
      context: context,
      builder: (context) => WorkoutCalendarDialog(provider: widget.provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workouts = widget.provider.workouts;
    final todayLogs = widget.provider.todayWorkoutLogs;
    final streak = widget.provider.workoutStreak;

    final filteredWorkouts = workouts.where((w) {
      if (_selectedCategoryFilter == '전체') return true;
      return w.category == _selectedCategoryFilter;
    }).toList();

    int totalWorkoutsCount = workouts.length;
    int completedWorkoutsCount = workouts.where((w) => todayLogs[w.id]?.isCompleted ?? false).length;
    bool isAllCompleted = totalWorkoutsCount > 0 && completedWorkoutsCount == totalWorkoutsCount;

    return Column(
      children: [
        // Top Streak & Summary Banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isAllCompleted
                  ? [const Color(0xFF2ECC71), const Color(0xFF1ABC9C)]
                  : [AppColors.q2, const Color(0xFF6C5CE7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (isAllCompleted ? Colors.green : AppColors.q2).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text(
                              '연속 $streak일째 오운완!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _showCalendarDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.calendar_month, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '캘린더',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isAllCompleted ? '🎉 오늘 운동 완벽 달성!' : '오늘의 운동 현황',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$completedWorkoutsCount / $totalWorkoutsCount 완료',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: totalWorkoutsCount > 0 ? (completedWorkoutsCount / totalWorkoutsCount) : 0.0,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: _categories.map((cat) {
              final isSelected = _selectedCategoryFilter == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: AppColors.q2,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategoryFilter = cat);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Workout Cards List
        Expanded(
          child: filteredWorkouts.isEmpty
              ? _buildEmptyState(theme)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: filteredWorkouts.length,
                  itemBuilder: (context, index) {
                    final workout = filteredWorkouts[index];
                    final log = todayLogs[workout.id];
                    return _buildWorkoutCard(context, workout, log);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏋️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            '등록된 운동 루틴이 없습니다.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.hintColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '매일 운동을 기록하고 습관을 만들어보세요!',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showAddWorkoutSheet(),
            icon: const Icon(Icons.add),
            label: const Text('신규 운동 루틴 추가'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.q2,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, Workout workout, WorkoutLog? log) {
    final theme = Theme.of(context);
    final isCompleted = log?.isCompleted ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCompleted
              ? AppColors.q2.withValues(alpha: 0.4)
              : theme.dividerColor.withValues(alpha: 0.2),
          width: isCompleted ? 1.5 : 1,
        ),
      ),
      elevation: 0,
      color: isCompleted
          ? AppColors.q2.withValues(alpha: 0.04)
          : theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header Row
            Row(
              children: [
                Text(workout.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            workout.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              color: isCompleted ? theme.hintColor : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              workout.category,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '반복: ${workout.repeatDays}',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: theme.hintColor),
                      ),
                    ],
                  ),
                ),

                // Edit Button
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () => _showAddWorkoutSheet(workoutToEdit: workout),
                ),

                // Overall Workout Toggle Checkbox
                IconButton(
                  icon: Icon(
                    isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isCompleted ? AppColors.q2 : theme.hintColor,
                    size: 28,
                  ),
                  onPressed: () {
                    widget.provider.toggleWorkoutCompletion(workout);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Card Body depending on Workout Type
            if (workout.workoutType == 'set')
              _buildSetTypeBody(workout, log)
            else if (workout.workoutType == 'time')
              _buildTimeTypeBody(workout, log)
            else
              _buildSimpleTypeBody(workout, log),
          ],
        ),
      ),
    );
  }

  Widget _buildSetTypeBody(Workout workout, WorkoutLog? log) {
    final theme = Theme.of(context);
    final sets = log?.setDetails ??
        List.generate(
          workout.targetSets,
          (i) => SetDetail(
            setIndex: i + 1,
            weight: workout.targetWeight,
            reps: workout.targetReps,
            isCompleted: false,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sets.length,
          itemBuilder: (context, index) {
            final setDetail = sets[index];
            final isSetCompleted = setDetail.isCompleted;

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSetCompleted
                    ? AppColors.q2.withValues(alpha: 0.08)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    '${setDetail.setIndex}세트',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSetCompleted ? AppColors.q2 : null,
                    ),
                  ),
                  const Spacer(),
                  // Clickable Weight & Reps Chip
                  InkWell(
                    onTap: () => _showEditSetDialog(workout, setDetail, sets.length),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSetCompleted
                              ? AppColors.q2.withValues(alpha: 0.4)
                              : theme.dividerColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (setDetail.weight > 0 && setDetail.reps > 0) ...[
                            Text(
                              '${setDetail.weight}kg  ×  ${setDetail.reps}회',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSetCompleted ? AppColors.q2 : theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ] else if (setDetail.weight > 0) ...[
                            Text(
                              '${setDetail.weight}kg',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSetCompleted ? AppColors.q2 : theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ] else if (setDetail.reps > 0) ...[
                            Text(
                              '${setDetail.reps}회',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSetCompleted ? AppColors.q2 : theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ] else ...[
                            Text(
                              '기록 입력',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_outlined, size: 12, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Completion Checkmark
                  InkWell(
                    onTap: () {
                      widget.provider.toggleSetCompletion(
                        workout: workout,
                        setIndex: setDetail.setIndex,
                        weight: setDetail.weight,
                        reps: setDetail.reps,
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isSetCompleted ? Icons.check_circle : Icons.panorama_fish_eye,
                        color: isSetCompleted ? AppColors.q2 : theme.hintColor,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                widget.provider.addSetToWorkout(workout);
              },
              icon: const Icon(Icons.add, size: 14),
              label: const Text('세트 추가', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.q2,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            if (sets.length > 1) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  widget.provider.deleteSetFromWorkout(
                    workout: workout,
                    setIndex: sets.length,
                  );
                },
                icon: const Icon(Icons.remove, size: 14),
                label: const Text('세트 삭제', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showEditSetDialog(Workout workout, SetDetail setDetail, int totalSetsCount) {
    final weightController = TextEditingController(text: setDetail.weight > 0 ? setDetail.weight.toString() : '');
    final repsController = TextEditingController(text: setDetail.reps > 0 ? setDetail.reps.toString() : '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '${setDetail.setIndex}세트 무게 및 횟수 수정',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: '무게 (kg, 선택)',
                  suffixText: 'kg',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '횟수 (회, 선택)',
                  suffixText: '회',
                ),
              ),
            ],
          ),
          actions: [
            if (totalSetsCount > 1)
              TextButton(
                onPressed: () {
                  widget.provider.deleteSetFromWorkout(workout: workout, setIndex: setDetail.setIndex);
                  Navigator.pop(ctx);
                },
                child: const Text('세트 삭제', style: TextStyle(color: Colors.redAccent)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final weight = double.tryParse(weightController.text.trim()) ?? 0.0;
                final reps = int.tryParse(repsController.text.trim()) ?? 0;
                widget.provider.updateSetDetail(
                  workout: workout,
                  setIndex: setDetail.setIndex,
                  weight: weight,
                  reps: reps,
                );
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.q2,
                foregroundColor: Colors.white,
              ),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeTypeBody(Workout workout, WorkoutLog? log) {
    final isCompleted = log?.isCompleted ?? false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.timer_outlined, size: 18, color: AppColors.q2),
            const SizedBox(width: 6),
            Text(
              '목표: ${workout.targetMinutes}분',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: () {
            widget.provider.toggleWorkoutCompletion(workout);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isCompleted ? Colors.grey.shade300 : AppColors.q2,
            foregroundColor: isCompleted ? Colors.black87 : Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(isCompleted ? '완료 취소' : '운동 완료하기'),
        ),
      ],
    );
  }

  Widget _buildSimpleTypeBody(Workout workout, WorkoutLog? log) {
    final isCompleted = log?.isCompleted ?? false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isCompleted ? '오늘 운동 완료!' : '체크박스를 눌러 완료하세요.',
          style: TextStyle(
            color: isCompleted ? AppColors.q2 : Theme.of(context).hintColor,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (!isCompleted)
          OutlinedButton.icon(
            onPressed: () {
              widget.provider.toggleWorkoutCompletion(workout);
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('완료'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.q2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
      ],
    );
  }
}
