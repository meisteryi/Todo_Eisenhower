class Routine {
  final int? id;
  final int? categoryId;
  final String title;
  final String repeatType; // 'daily', 'weekly', 'monthly'
  final String repeatDays; // Comma-separated weekdays (1=Mon, 7=Sun) or monthly day numbers
  final DateTime startDate;
  final bool isActive;

  Routine({
    this.id,
    this.categoryId,
    required this.title,
    required this.repeatType,
    required this.repeatDays,
    required this.startDate,
    this.isActive = true,
  });

  Routine copyWith({
    int? id,
    int? categoryId,
    String? title,
    String? repeatType,
    String? repeatDays,
    DateTime? startDate,
    bool? isActive,
  }) {
    return Routine(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      repeatType: repeatType ?? this.repeatType,
      repeatDays: repeatDays ?? this.repeatDays,
      startDate: startDate ?? this.startDate,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'title': title,
      'repeat_type': repeatType,
      'repeat_days': repeatDays,
      'start_date': startDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Routine.fromMap(Map<String, dynamic> map) {
    return Routine(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int?,
      title: map['title'] as String,
      repeatType: map['repeat_type'] as String,
      repeatDays: map['repeat_days'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      isActive: (map['is_active'] as int) == 1,
    );
  }

  /// Checks whether this routine should occur on a specific [date]
  bool shouldOccurOn(DateTime date) {
    if (!isActive) return false;
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    if (dateOnly.isBefore(startOnly)) return false;

    if (repeatType == 'daily') {
      return true;
    } else if (repeatType == 'weekly') {
      final days = repeatDays.split(',').map((e) => int.tryParse(e.trim())).whereType<int>().toList();
      return days.contains(date.weekday); // 1 = Monday, 7 = Sunday
    } else if (repeatType == 'monthly') {
      final days = repeatDays.split(',').map((e) => int.tryParse(e.trim())).whereType<int>().toList();
      return days.contains(date.day);
    }
    return false;
  }
}
