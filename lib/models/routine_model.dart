class Routine {
  final int? id;
  final int? categoryId;
  final String title;
  final int quadrant;
  final String repeatType; // 'daily', 'weekly', 'monthly'
  final String repeatDays; // Comma-separated weekdays (1=Mon, 7=Sun) or monthly day numbers
  final DateTime startDate;
  final DateTime? endDate;
  final String? location;
  final String? timeStr;
  final String? dueTimeStr;
  final String? memo;
  final bool hasNotification;
  final int notificationOffset;
  final bool isActive;

  Routine({
    this.id,
    this.categoryId,
    required this.title,
    this.quadrant = 1,
    required this.repeatType,
    required this.repeatDays,
    required this.startDate,
    this.endDate,
    this.location,
    this.timeStr,
    this.dueTimeStr,
    this.memo,
    this.hasNotification = false,
    this.notificationOffset = 0,
    this.isActive = true,
  });

  Routine copyWith({
    int? id,
    int? categoryId,
    String? title,
    int? quadrant,
    String? repeatType,
    String? repeatDays,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? timeStr,
    String? dueTimeStr,
    String? memo,
    bool? hasNotification,
    int? notificationOffset,
    bool? isActive,
  }) {
    return Routine(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      quadrant: quadrant ?? this.quadrant,
      repeatType: repeatType ?? this.repeatType,
      repeatDays: repeatDays ?? this.repeatDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      timeStr: timeStr ?? this.timeStr,
      dueTimeStr: dueTimeStr ?? this.dueTimeStr,
      memo: memo ?? this.memo,
      hasNotification: hasNotification ?? this.hasNotification,
      notificationOffset: notificationOffset ?? this.notificationOffset,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'title': title,
      'quadrant': quadrant,
      'repeat_type': repeatType,
      'repeat_days': repeatDays,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'location': location,
      'time_str': timeStr,
      'due_time_str': dueTimeStr,
      'memo': memo,
      'has_notification': hasNotification ? 1 : 0,
      'notification_offset': notificationOffset,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Routine.fromMap(Map<String, dynamic> map) {
    return Routine(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int?,
      title: (map['title'] ?? '') as String,
      quadrant: (map['quadrant'] as int?) ?? 1,
      repeatType: (map['repeat_type'] ?? 'daily') as String,
      repeatDays: (map['repeat_days'] ?? '') as String,
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : DateTime.now(),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      location: map['location']?.toString(),
      timeStr: map['time_str']?.toString(),
      dueTimeStr: map['due_time_str']?.toString(),
      memo: map['memo']?.toString(),
      hasNotification:
          map['has_notification'] == 1 || map['has_notification'] == true,
      notificationOffset: (map['notification_offset'] as int?) ?? 0,
      isActive: map['is_active'] == 1 || map['is_active'] == true,
    );
  }

  /// Checks whether this routine should occur on a specific [date]
  bool shouldOccurOn(DateTime date) {
    if (!isActive) return false;
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    if (dateOnly.isBefore(startOnly)) return false;

    if (endDate != null) {
      final endOnly = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (dateOnly.isAfter(endOnly)) return false;
    }

    if (repeatType == 'daily') {
      return true;
    } else if (repeatType == 'weekly') {
      final days = repeatDays
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .toList();
      return days.contains(date.weekday); // 1 = Monday, 7 = Sunday
    } else if (repeatType == 'monthly') {
      final days = repeatDays
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .toList();
      return days.contains(date.day);
    }
    return false;
  }
}
