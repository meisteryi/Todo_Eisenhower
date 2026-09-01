class Todo {
  final int? id;
  final String title;
  final int
  quadrant; // 0: Inbox, 1: Q1 (Do), 2: Q2 (Decide), 3: Q3 (Delegate), 4: Q4 (Delete)
  final int? categoryId;
  final int? routineId;
  final DateTime targetDate;
  final bool isCompleted;
  final bool isTrash;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? deletedAt;
  final String? location;
  final String? timeStr;
  final String? dueTimeStr;
  final String? memo;
  final bool hasNotification;
  final int
  notificationOffset; // 0: 정시, 10: 10분 전, 30: 30분 전, 60: 1시간 전, custom

  Todo({
    this.id,
    required this.title,
    required this.quadrant,
    this.categoryId,
    this.routineId,
    DateTime? targetDate,
    this.isCompleted = false,
    this.isTrash = false,
    this.dueDate,
    required this.createdAt,
    this.completedAt,
    this.deletedAt,
    this.location,
    this.timeStr,
    this.dueTimeStr,
    this.memo,
    this.hasNotification = false,
    this.notificationOffset = 0,
  }) : targetDate = targetDate ?? DateTime.now();

  Todo copyWith({
    int? id,
    String? title,
    int? quadrant,
    int? categoryId,
    int? routineId,
    DateTime? targetDate,
    bool? isCompleted,
    bool? isTrash,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? deletedAt,
    String? location,
    String? timeStr,
    String? dueTimeStr,
    String? memo,
    bool? hasNotification,
    int? notificationOffset,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      quadrant: quadrant ?? this.quadrant,
      categoryId: categoryId ?? this.categoryId,
      routineId: routineId ?? this.routineId,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
      isTrash: isTrash ?? this.isTrash,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      location: location ?? this.location,
      timeStr: timeStr ?? this.timeStr,
      dueTimeStr: dueTimeStr ?? this.dueTimeStr,
      memo: memo ?? this.memo,
      hasNotification: hasNotification ?? this.hasNotification,
      notificationOffset: notificationOffset ?? this.notificationOffset,
    );
  }

  Map<String, dynamic> toMap() {
    final targetDateStr =
        "${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";
    return {
      if (id != null) 'id': id,
      'title': title,
      'quadrant': quadrant,
      'category_id': categoryId,
      'routine_id': routineId,
      'target_date': targetDateStr,
      'is_completed': isCompleted ? 1 : 0,
      'is_trash': isTrash ? 1 : 0,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'location': location,
      'time_str': timeStr,
      'due_time_str': dueTimeStr,
      'memo': memo,
      'has_notification': hasNotification ? 1 : 0,
      'notification_offset': notificationOffset,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    DateTime parsedTargetDate = DateTime.now();
    if (map['target_date'] != null) {
      final parts = (map['target_date'] as String).split('-');
      if (parts.length == 3) {
        parsedTargetDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } else if (map['created_at'] != null) {
      final parsedCreated = DateTime.parse(map['created_at'] as String);
      parsedTargetDate = DateTime(
        parsedCreated.year,
        parsedCreated.month,
        parsedCreated.day,
      );
    }

    return Todo(
      id: map['id'] as int?,
      title: (map['title'] ?? '') as String,
      quadrant: (map['quadrant'] as int?) ?? 0,
      categoryId: map['category_id'] as int?,
      routineId: map['routine_id'] as int?,
      targetDate: parsedTargetDate,
      isCompleted: map['is_completed'] == 1 || map['is_completed'] == true,
      isTrash: map['is_trash'] == 1 || map['is_trash'] == true,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at'] as String)
          : null,
      location: map['location']?.toString(),
      timeStr: map['time_str']?.toString(),
      dueTimeStr: map['due_time_str']?.toString(),
      memo: map['memo']?.toString(),
      hasNotification:
          map['has_notification'] == 1 || map['has_notification'] == true,
      notificationOffset: (map['notification_offset'] as int?) ?? 0,
    );
  }
}
