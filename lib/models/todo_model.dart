class Todo {
  final int? id;
  final String title;
  final int quadrant; // 1: Q1 (Do), 2: Q2 (Decide), 3: Q3 (Delegate), 4: Q4 (Delete)
  final bool isCompleted;
  final bool isTrash;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? deletedAt;

  Todo({
    this.id,
    required this.title,
    required this.quadrant,
    this.isCompleted = false,
    this.isTrash = false,
    this.dueDate,
    required this.createdAt,
    this.completedAt,
    this.deletedAt,
  });

  Todo copyWith({
    int? id,
    String? title,
    int? quadrant,
    bool? isCompleted,
    bool? isTrash,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? deletedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      quadrant: quadrant ?? this.quadrant,
      isCompleted: isCompleted ?? this.isCompleted,
      isTrash: isTrash ?? this.isTrash,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'quadrant': quadrant,
      'is_completed': isCompleted ? 1 : 0,
      'is_trash': isTrash ? 1 : 0,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as int?,
      title: map['title'] as String,
      quadrant: map['quadrant'] as int,
      isCompleted: (map['is_completed'] as int) == 1,
      isTrash: (map['is_trash'] as int) == 1,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
    );
  }
}
