import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';

class CategoryManageDialog extends StatefulWidget {
  final TodoProvider provider;

  const CategoryManageDialog({super.key, required this.provider});

  @override
  State<CategoryManageDialog> createState() => _CategoryManageDialogState();
}

class EmojiCategoryData {
  final String title;
  final List<String> emojis;

  const EmojiCategoryData(this.title, this.emojis);
}

class _CategoryManageDialogState extends State<CategoryManageDialog> {
  final List<String> _presetColors = [
    '#4A90E2', // Blue
    '#2ECC71', // Green
    '#F39C12', // Orange
    '#9B59B6', // Purple
    '#E74C3C', // Red
    '#1ABC9C', // Teal
    '#FD79A8', // Pink
    '#6C5CE7', // Indigo
    '#00CEC9', // Mint
    '#F1C40F', // Yellow
  ];

  static const List<EmojiCategoryData> _unicodeEmojiCategories = [
    EmojiCategoryData('😀 감정 & 사람', [
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗', '😚', '😙', '😋', '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨', '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '🤥', '😌', '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕', '🤢', '🤮', '🤧', '🥵', '🥶', '🥴', '😵', '🤯', '🤠', '🥳', '😎', '🤓', '🧐', '😕', '😟', '🙁', '😮', '😯', '😲', '😳', '🥺', '😦', '😧', '📁', '👏', '👍', '👎', '👊', '✊', '🤛', '🤜', '🤞', '✌️', '🤟', '🤘', '👌', '👈', '👉', '👆', '👇', '☝️', '✋', '🤚', '🖐️', '🖖', '👋', '🤙', '💪',
    ]),
    EmojiCategoryData('💼 업무 & 공부', [
      '📝', '📚', '📖', '💻', '🖥️', '📊', '📈', '📉', '📜', '📄', '📂', '📁', '📅', '📆', '✒️', '✏️', '🖊️', '🔍', '🔎', '💡', '📌', '📍', '📎', '✂️', '💼', '🗂️', '📦', '🏷️', '✉️', '📧', '📥', '📤', '🔔', '🔕', '⏰', '⏱️',
    ]),
    EmojiCategoryData('⚽ 운동 & 취미', [
      '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱', '🏓', '🏸', '🏒', '🏑', '🏏', '🎯', '⛳', '🪁', '🏹', '🎣', '🥊', '🥋', '🎽', '🛹', '🛷', '⛸️', '🥌', '🎿', '⛷️', '🏂', '🏋️', '🤸', '🤺', '🤼', '🤽', '🤾', '🏄', '🏊', '🚣', '🧗', '🚵', '🚴', '🏆', '🥇', '🥈', '🥉', '🏅', '🎖️', '🎨', '🎮', '🎲', '🧩', '🎬', '🎤', '🎧', '🎼', '🎵', '🎶', '🎹', '🥁',
    ]),
    EmojiCategoryData('🍎 음식 & 카페', [
      '🍏', '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🍈', '🍒', '🍑', '🥭', '🍍', '🥥', '🥝', '🍅', '🍆', '🥑', '🥦', '🥬', '🥒', '🌽', '🥕', '🍞', '🥐', '🥖', '🥨', '🥯', '🥞', '🧀', '🍖', '🍗', '🥩', '🥓', '🍔', '🍟', '🍕', '🌭', '🥪', '🌮', '🌯', '🍳', '🥘', '🍲', '🥣', '🥗', '🍿', '🍱', '🍘', '🍙', '🍚', '🍛', '🍜', '🍝', '🍠', '🍢', '🍣', '🍤', '🍥', '🍡', '🥟', '🥠', '🍦', '🍧', '🍨', '🍩', '🍪', '🎂', '🍰', '🧁', '🥧', '🍫', '🍬', '🍭', '🍮', '🍯', '☕', '🍵', '🍶', '🍾', '🍷', '🍸', '🍹', '🍺', '🍻', '🥂', '🥃', '🥤', '🥢',
    ]),
    EmojiCategoryData('✈️ 여행 & 일상', [
      '🚗', '🚕', '🚙', '🚌', '🏎️', '🚓', '🚑', '🚒', '🚐', '🚚', '🚛', '🚜', '🛵', '🏍️', '🚲', '🚨', '🚔', '🚍', '🚘', '🚖', '🚡', '🚠', '🚟', '🚃', '🚋', '🚝', '🚅', '🚈', '🚂', '🚆', '🚇', '🚊', '🚉', '✈️', '🛫', '🛬', '🛩️', '💺', '🛰️', '🚀', '🛸', '🚁', '🛶', '⛵', '🚤', '🛥️', '🛳️', '⛴️', '🚢', '⚓', '⛽', '🚧', '🚦', '🚥', '🏠', '🏡', '🏢', '🏣', '🏥', '🏦', '🏨', '🏪', '🏫', '🏬', '🏭', '🏰', '🏯', '💒', '🗼', '🗽', '⛪', '🕌', '🕍', '⛩️', '🕋', '⛲', '⛺', '🌁', '🌃', '🏙️', '🌄', '🌅',
    ]),
    EmojiCategoryData('🐻 동물 & 자연', [
      '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮', '🐷', '🐽', '🐸', '🐵', '🙈', '🙉', '🙊', '🐒', '🐔', '🐧', '🐦', '🐤', '🐣', '🐥', '🦆', '🦅', '🦉', '🦇', '🐺', '🐗', '🐴', '🦄', '🐝', '🐛', '🦋', '🐌', '🐞', '🐜', '🦟', '🕷️', '🕸️', '🦂', '🐢', '🐍', '🦎', '🦖', '🦕', '🐙', '🦑', '🦐', '🦞', '🦀', '🐡', '🐠', '🐟', '🐬', '🐳', '🐋', '🦈', '🐊', '🐅', '🐆', '🦍', '🦧', '🐘', '🦛', '🦏', '🐪', '🐫', '🦒', '🦘', '🦙', '🕊️', '🐕', '🐩', '🐈', '🐓', '🦃', '🦚', '🦜', '🌲', '🌳', '🌴', '🌱', '🌿', '☘️', '🍀', '🎍', '🎋', '🍃', '🍂', '🍁', '🍄', '🌾', '💐', '🌷', '🌹', '🥀', '🌺', '🌸', '🌼', '🌻', '🌞', '🌝', '🌛', '🌜', '🌚', '🌕', '🌖', '🌗', '🌘', '🌑', '🌒', '🌓', '🌔', '🌙', '🌎', '🌍', '🌏', '💫', '⭐️', '🌟', '✨', '⚡️', '☄️', '💥', '🔥', '🌪️', '🌈', '☀️', '🌤️', '⛅️', '🌥️', '☁️', '🌦️', '🌧️', '⛈️', '🌩️', '🌨️', '❄️',
    ]),
    EmojiCategoryData('🔣 기호 & 하트', [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '💔', '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟', '☮️', '✝️', '☪️', '🕉️', '☸️', '✡️', '🔯', '🕎', '☯️', '☦️', '🛐', '⛎', '♈️', '♉️', '♊️', '♋️', '♍️', '♎️', '♏️', '🏹', '♑️', '♒️', '♓️', '🆔', '⚛️', '☣️', '☢️', '📴', '📳', '🈶', '🈚️', '🈸', '🈺', '🈷️', '✴️', '🅰️', '🅱️', '🆎', '🆑', '🅾️', '🆘', '❌', '⭕️', '🛑', '⛔️', '📛', '🚫', '💯', '💢', '♨️', '🚷', '🚯', '🚳', '🔞', '📵', '🚭', '❗️', '❕', '❓', '❔', '‼️', '⁉️', '🔆', '🔅', '⚠️', '🚸', '🔱', '⚜️', '🔰', '♻️', '✅', '🈯️', '📊', '📈', '📉', '❇️', '✳️', '❎', '🌐', '💠', 'Ⓜ️', '🌀', '💤', '🏧', '🚾', '♿️', '🅿️', '🈳', '🈂️', '🛂', '🛃', '🛄', '🛅', '🚹', '🚼', '🚻', '🚮', '🎦', '📶', '🈁',
    ]),
  ];

  void _showUnicodeEmojiPicker(
    BuildContext context,
    Function(String emoji) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return DefaultTabController(
          length: _unicodeEmojiCategories.length,
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.65,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.emoji_emotions_outlined, color: Colors.amber),
                          SizedBox(width: 8),
                          Text(
                            '유니코드 이모지 선택',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: Theme.of(ctx).primaryColor,
                  labelColor: Theme.of(ctx).primaryColor,
                  unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                  tabs: _unicodeEmojiCategories.map((cat) {
                    final firstEmoji = cat.emojis.first;
                    final titleParts = cat.title.split(' ');
                    final categoryName = titleParts.length > 1
                        ? titleParts.sublist(1).join(' ')
                        : cat.title;
                    return Tab(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(firstEmoji, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 6),
                            Text(
                              categoryName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: _unicodeEmojiCategories.map((cat) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemCount: cat.emojis.length,
                        itemBuilder: (context, index) {
                          final emoji = cat.emojis[index];
                          return InkWell(
                            onTap: () {
                              onSelect(emoji);
                              Navigator.pop(ctx);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(emoji, style: const TextStyle(fontSize: 30)),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddOrEditCategoryDialog({Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    String selectedEmoji = category?.emoji ?? '📝';
    String selectedColor = category?.colorHex ?? _presetColors.first;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(category == null ? '신규 카테고리 추가' : '카테고리 수정'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            _showUnicodeEmojiPicker(context, (emoji) {
                              setDialogState(() {
                                selectedEmoji = emoji;
                              });
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 72,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(selectedEmoji, style: const TextStyle(fontSize: 28)),
                                const Text(
                                  '이모지 변경',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: '카테고리 이름',
                              hintText: '예: 공부, 운동, 일상',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            autofocus: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('테마 색상 선택', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _presetColors.map((hex) {
                        final color = _parseColor(hex);
                        final isSelected = hex == selectedColor;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColor = hex;
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    if (category == null) {
                      widget.provider.addCategory(name, selectedColor, selectedEmoji);
                    } else {
                      final updated = category.copyWith(
                        name: name,
                        colorHex: selectedColor,
                        emoji: selectedEmoji,
                      );
                      widget.provider.updateCategory(updated);
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _parseColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  Widget _buildProxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double scale = Tween<double>(begin: 1.0, end: 1.05).transform(animValue);
        final double elevation = Tween<double>(begin: 0.0, end: 10.0).transform(animValue);

        return Transform.scale(
          scale: scale,
          child: Material(
            elevation: elevation,
            shadowColor: Colors.black.withValues(alpha: 0.35),
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Future<bool?> _confirmDeleteCategory(BuildContext context, Category cat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text(
              '카테고리 삭제',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          '\'${cat.name}\' 카테고리를 삭제하시겠습니까?\n(해당 카테고리에 속한 할 일은 미분류 상태로 유지됩니다)',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.provider.categories;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 580),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.category_rounded, color: AppColors.q2, size: 22),
                    SizedBox(width: 8),
                    Text(
                      '카테고리 관리',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '💡 꾹 누르면 순서 변경, 왼쪽으로 밀면 삭제할 수 있습니다.',
              style: TextStyle(
                fontSize: 11,
                color: theme.hintColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: categories.isEmpty
                  ? Center(
                      child: Text(
                        '등록된 카테고리가 없습니다.',
                        style: TextStyle(color: theme.hintColor),
                      ),
                    )
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      proxyDecorator: _buildProxyDecorator,
                      itemCount: categories.length,
                      onReorderItem: (oldIndex, newIndex) {
                        widget.provider.reorderCategories(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final color = _parseColor(cat.colorHex);

                        return ReorderableDelayedDragStartListener(
                          key: ValueKey('category_${cat.id ?? index}'),
                          index: index,
                          child: Dismissible(
                            key: ValueKey('category_dismiss_${cat.id ?? index}'),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              return await _confirmDeleteCategory(context, cat);
                            },
                            onDismissed: (direction) {
                              widget.provider.deleteCategory(cat.id!);
                            },
                            background: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.shade200,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '삭제',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkInputBg
                                    : AppColors.lightInputBg,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _showAddOrEditCategoryDialog(category: cat),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        // Emoji Icon Container
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.18),
                                            shape: BoxShape.circle,
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            cat.emoji,
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        // Category Name
                                        Expanded(
                                          child: Text(
                                            cat.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        // Edit icon button
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                            color: theme.hintColor,
                                          ),
                                          onPressed: () {
                                            _showAddOrEditCategoryDialog(category: cat);
                                          },
                                          padding: const EdgeInsets.all(6),
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () => _showAddOrEditCategoryDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  '새 카테고리 추가',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.q2,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
