import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';

class AddWorkoutSheet extends StatefulWidget {
  final TodoProvider provider;
  final Workout? workoutToEdit;

  const AddWorkoutSheet({
    super.key,
    required this.provider,
    this.workoutToEdit,
  });

  @override
  State<AddWorkoutSheet> createState() => _AddWorkoutSheetState();
}

class _AddWorkoutSheetState extends State<AddWorkoutSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _minutesController;

  late String _selectedEmoji;
  late String _selectedCategory;
  late String _selectedWorkoutType;
  late Set<String> _selectedRepeatDays;

  final List<String> _categoryOptions = ['웨이트', '유산소', '스트레칭', '기타'];
  final List<String> _presetEmojis = ['🏋️‍♂️', '🏃', '🧘', '🚴', '🥊', '🏊', '🤸', '⚽', '🏀', '💪'];
  final List<String> _daysOfWeek = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void initState() {
    super.initState();
    final w = widget.workoutToEdit;
    _titleController = TextEditingController(text: w?.title ?? '');
    _setsController = TextEditingController(text: (w?.targetSets ?? 3).toString());
    _repsController = TextEditingController(text: (w?.targetReps ?? 10).toString());
    _weightController = TextEditingController(text: (w?.targetWeight ?? 0.0).toString());
    _minutesController = TextEditingController(text: (w?.targetMinutes ?? 30).toString());

    _selectedEmoji = w?.emoji ?? '🏋️‍♂️';
    _selectedCategory = w?.category ?? '웨이트';
    _selectedWorkoutType = w?.workoutType ?? 'set';

    if (w != null && w.repeatDays.isNotEmpty) {
      _selectedRepeatDays = w.repeatDays.split(',').toSet();
    } else {
      _selectedRepeatDays = _daysOfWeek.toSet();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _saveWorkout() {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final sets = int.tryParse(_setsController.text.trim()) ?? 3;
    final reps = int.tryParse(_repsController.text.trim()) ?? 0;
    final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 30;

    final repeatDaysStr = _daysOfWeek.where((d) => _selectedRepeatDays.contains(d)).join(',');

    final workout = Workout(
      id: widget.workoutToEdit?.id,
      title: title,
      emoji: _selectedEmoji,
      category: _selectedCategory,
      workoutType: _selectedWorkoutType,
      targetSets: sets,
      targetReps: reps,
      targetWeight: weight,
      targetMinutes: minutes,
      repeatDays: repeatDaysStr.isEmpty ? '월,화,수,목,금,토,일' : repeatDaysStr,
      sortOrder: widget.workoutToEdit?.sortOrder ?? (widget.provider.workouts.length + 1),
    );

    if (widget.workoutToEdit != null) {
      widget.provider.updateWorkout(workout);
    } else {
      widget.provider.addWorkout(workout);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.workoutToEdit != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? '🏋️ 운동 루틴 수정' : '🏋️ 신규 운동 루틴 추가',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Emoji & Title row
              Row(
                children: [
                  // Emoji selection button
                  GestureDetector(
                    onTap: _showEmojiPicker,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _selectedEmoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title TextField
                  Expanded(
                    child: TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: '운동 이름 (예: 벤치프레스, 런닝)',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return '운동 이름을 입력해 주세요.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category Selector
              Text('운동 카테고리', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _categoryOptions.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.q2.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.q2 : theme.textTheme.bodyMedium?.color,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Workout Type Selector
              Text('기록 측정 방식', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'set', label: Text('세트 수'), icon: Icon(Icons.fitness_center)),
                  ButtonSegment(value: 'time', label: Text('시간/목표'), icon: Icon(Icons.timer)),
                  ButtonSegment(value: 'simple', label: Text('단순 체크'), icon: Icon(Icons.check_circle_outline)),
                ],
                selected: {_selectedWorkoutType},
                onSelectionChanged: (newSelection) {
                  setState(() => _selectedWorkoutType = newSelection.first);
                },
              ),
              const SizedBox(height: 16),

              // Dynamic Input Fields according to Workout Type
              if (_selectedWorkoutType == 'set') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _setsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: '목표 세트 수',
                          suffixText: '세트',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _repsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: '횟수 (선택)',
                          suffixText: '회',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: '무게 (선택)',
                          suffixText: 'kg',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (_selectedWorkoutType == 'time') ...[
                TextFormField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '목표 운동 시간',
                    suffixText: '분',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Repeat Days
              Text('반복 요일', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: _daysOfWeek.map((day) {
                  final isSelected = _selectedRepeatDays.contains(day);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              if (_selectedRepeatDays.length > 1) {
                                _selectedRepeatDays.remove(day);
                              }
                            } else {
                              _selectedRepeatDays.add(day);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.q2
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  if (isEdit) ...[
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        widget.provider.deleteWorkout(widget.workoutToEdit!.id!);
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveWorkout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.q2,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEdit ? '수정 완료' : '운동 루틴 생성',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '이모지 선택',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                itemCount: _presetEmojis.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final emoji = _presetEmojis[index];
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedEmoji = emoji);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
