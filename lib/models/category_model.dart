class Category {
  final int? id;
  final String name;
  final String colorHex;
  final String emoji;
  final bool isVisible;
  final int sortOrder;

  Category({
    this.id,
    required this.name,
    required this.colorHex,
    this.emoji = '📝',
    this.isVisible = true,
    this.sortOrder = 0,
  });

  Category copyWith({
    int? id,
    String? name,
    String? colorHex,
    String? emoji,
    bool? isVisible,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      emoji: emoji ?? this.emoji,
      isVisible: isVisible ?? this.isVisible,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'color_hex': colorHex,
      'emoji': emoji,
      'is_visible': isVisible ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorHex: map['color_hex'] as String,
      emoji: (map['emoji'] as String?) ?? '📝',
      isVisible: (map['is_visible'] as int? ?? 1) == 1,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  // Predefined default categories for Todo Mate experience
  static List<Category> defaultCategories() {
    return [
      Category(id: 1, name: '업무 / 공부', colorHex: '#4A90E2', emoji: '📝', sortOrder: 1),
      Category(id: 2, name: '운동 / 건강', colorHex: '#2ECC71', emoji: '💪', sortOrder: 2),
      Category(id: 3, name: '쇼핑 / 일상', colorHex: '#F39C12', emoji: '🛒', sortOrder: 3),
      Category(id: 4, name: '취미 / 개인', colorHex: '#9B59B6', emoji: '🎨', sortOrder: 4),
    ];
  }
}
