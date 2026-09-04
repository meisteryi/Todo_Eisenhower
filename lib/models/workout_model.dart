import 'dart:convert';

class SetDetail {
  final int setIndex;
  final double weight;
  final int reps;
  final bool isCompleted;

  SetDetail({
    required this.setIndex,
    required this.weight,
    required this.reps,
    this.isCompleted = false,
  });

  SetDetail copyWith({
    int? setIndex,
    double? weight,
    int? reps,
    bool? isCompleted,
  }) {
    return SetDetail(
      setIndex: setIndex ?? this.setIndex,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'set_index': setIndex,
      'weight': weight,
      'reps': reps,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory SetDetail.fromMap(Map<String, dynamic> map) {
    return SetDetail(
      setIndex: (map['set_index'] as int?) ?? 1,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      reps: (map['reps'] as int?) ?? 0,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
    );
  }
}

class Workout {
  final int? id;
  final String title;
  final String emoji;
  final String category; // '웨이트', '유산소', '스트레칭', '기타'
  final String workoutType; // 'set', 'time', 'simple'
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final int targetMinutes;
  final String repeatDays; // e.g. "월,화,수,목,금,토,일"
  final int sortOrder;
  final bool isActive;
  final String createdAt;

  Workout({
    this.id,
    required this.title,
    this.emoji = '🏋️',
    this.category = '웨이트',
    this.workoutType = 'set',
    this.targetSets = 3,
    this.targetReps = 10,
    this.targetWeight = 0.0,
    this.targetMinutes = 30,
    this.repeatDays = '월,화,수,목,금,토,일',
    this.sortOrder = 0,
    this.isActive = true,
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Workout copyWith({
    int? id,
    String? title,
    String? emoji,
    String? category,
    String? workoutType,
    int? targetSets,
    int? targetReps,
    double? targetWeight,
    int? targetMinutes,
    String? repeatDays,
    int? sortOrder,
    bool? isActive,
    String? createdAt,
  }) {
    return Workout(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      workoutType: workoutType ?? this.workoutType,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      targetWeight: targetWeight ?? this.targetWeight,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      repeatDays: repeatDays ?? this.repeatDays,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'emoji': emoji,
      'category': category,
      'workout_type': workoutType,
      'target_sets': targetSets,
      'target_reps': targetReps,
      'target_weight': targetWeight,
      'target_minutes': targetMinutes,
      'repeat_days': repeatDays,
      'sort_order': sortOrder,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] as int?,
      title: map['title'] as String,
      emoji: (map['emoji'] as String?) ?? '🏋️',
      category: (map['category'] as String?) ?? '웨이트',
      workoutType: (map['workout_type'] as String?) ?? 'set',
      targetSets: (map['target_sets'] as int?) ?? 3,
      targetReps: (map['target_reps'] as int?) ?? 10,
      targetWeight: (map['target_weight'] as num?)?.toDouble() ?? 0.0,
      targetMinutes: (map['target_minutes'] as int?) ?? 30,
      repeatDays: (map['repeat_days'] as String?) ?? '월,화,수,목,금,토,일',
      sortOrder: (map['sort_order'] as int?) ?? 0,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: (map['created_at'] as String?) ?? DateTime.now().toIso8601String(),
    );
  }

  // Predefined default exercise routines for user convenience
  static List<Workout> defaultWorkouts() {
    return [
      Workout(
        title: '스쿼트',
        emoji: '🏋️‍♂️',
        category: '웨이트',
        workoutType: 'set',
        targetSets: 3,
        targetReps: 10,
        targetWeight: 60.0,
        repeatDays: '월,수,금',
        sortOrder: 1,
      ),
      Workout(
        title: '30분 야외 런닝',
        emoji: '🏃',
        category: '유산소',
        workoutType: 'time',
        targetMinutes: 30,
        repeatDays: '화,목,토',
        sortOrder: 2,
      ),
      Workout(
        title: '전신 스트레칭',
        emoji: '🧘',
        category: '스트레칭',
        workoutType: 'simple',
        repeatDays: '월,화,수,목,금,토,일',
        sortOrder: 3,
      ),
    ];
  }
}

class WorkoutLog {
  final int? id;
  final int workoutId;
  final String date; // YYYY-MM-DD
  final int completedSets;
  final List<SetDetail> setDetails;
  final int durationMinutes;
  final bool isCompleted;
  final String? completedAt;
  final String? memo;

  WorkoutLog({
    this.id,
    required this.workoutId,
    required this.date,
    this.completedSets = 0,
    this.setDetails = const [],
    this.durationMinutes = 0,
    this.isCompleted = false,
    this.completedAt,
    this.memo,
  });

  WorkoutLog copyWith({
    int? id,
    int? workoutId,
    String? date,
    int? completedSets,
    List<SetDetail>? setDetails,
    int? durationMinutes,
    bool? isCompleted,
    String? completedAt,
    String? memo,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      date: date ?? this.date,
      completedSets: completedSets ?? this.completedSets,
      setDetails: setDetails ?? this.setDetails,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toMap() {
    final setListMaps = setDetails.map((s) => s.toMap()).toList();
    return {
      if (id != null) 'id': id,
      'workout_id': workoutId,
      'date': date,
      'completed_sets': completedSets,
      'set_details_json': jsonEncode(setListMaps),
      'duration_minutes': durationMinutes,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt,
      'memo': memo,
    };
  }

  factory WorkoutLog.fromMap(Map<String, dynamic> map) {
    List<SetDetail> parsedSets = [];
    final jsonStr = map['set_details_json'] as String?;
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        parsedSets = decoded.map((e) => SetDetail.fromMap(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

    return WorkoutLog(
      id: map['id'] as int?,
      workoutId: map['workout_id'] as int,
      date: map['date'] as String,
      completedSets: (map['completed_sets'] as int?) ?? 0,
      setDetails: parsedSets,
      durationMinutes: (map['duration_minutes'] as int?) ?? 0,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      completedAt: map['completed_at'] as String?,
      memo: map['memo'] as String?,
    );
  }
}
