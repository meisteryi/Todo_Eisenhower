import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../providers/todo_provider.dart';

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
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '😅',
      '🤣',
      '😂',
      '🙂',
      '🙃',
      '😉',
      '😊',
      '😇',
      '🥰',
      '😍',
      '🤩',
      '😘',
      '😗',
      '😚',
      '😙',
      '😋',
      '😛',
      '😜',
      '🤪',
      '😝',
      '🤑',
      '🤗',
      '🤭',
      '🤫',
      '🤔',
      '🤐',
      '🤨',
      '😐',
      '😑',
      '😶',
      '😏',
      '😒',
      '🙄',
      '😬',
      '🤥',
      '😌',
      '😔',
      '😪',
      '🤤',
      '😴',
      '😷',
      '🤒',
      '🤕',
      '🤢',
      '🤮',
      '🤧',
      '🥵',
      '🥶',
      '🥴',
      '😵',
      '🤯',
      '🤠',
      '🥳',
      '😎',
      '🤓',
      '🧐',
      '😕',
      '😟',
      '🙁',
      '😮',
      '😯',
      '😲',
      '😳',
      '🥺',
      '😦',
      '😧',
      '📁',
      '👏',
      '👍',
      '👎',
      '👊',
      '✊',
      '🤛',
      '🤜',
      '🤞',
      '✌️',
      '🤟',
      '🤘',
      '👌',
      '👈',
      '👉',
      '👆',
      '👇',
      '☝️',
      '✋',
      '🤚',
      '🖐️',
      '🖖',
      '👋',
      '🤙',
      '💪',
    ]),
    EmojiCategoryData('💼 업무 & 공부', [
      '📝',
      '📚',
      '📖',
      '💻',
      '🖥️',
      '📊',
      '📈',
      '📉',
      '📜',
      '📄',
      '📂',
      '📁',
      '📅',
      '📆',
      '✒️',
      '✏️',
      '🖊️',
      '🔍',
      '🔎',
      '💡',
      '📌',
      '📍',
      '📎',
      '✂️',
      '💼',
      '🗂️',
      '📦',
      '🏷️',
      '✉️',
      '📧',
      '📥',
      '📤',
      '🔔',
      '🔕',
      '⏰',
      '⏱️',
    ]),
    EmojiCategoryData('⚽ 운동 & 취미', [
      '⚽',
      '🏀',
      '🏈',
      '⚾',
      '🥎',
      '🎾',
      '🏐',
      '🏉',
      '🥏',
      '🎱',
      '🏓',
      '🏸',
      '🏒',
      '🏑',
      '🏏',
      '🎯',
      '⛳',
      '🪁',
      '🏹',
      '🎣',
      '🥊',
      '🥋',
      '🎽',
      '🛹',
      '🛷',
      '⛸️',
      '🥌',
      '🎿',
      '⛷️',
      '🏂',
      '🏋️',
      '🤸',
      '🤺',
      '🤼',
      '🤽',
      '🤾',
      '🏄',
      '🏊',
      '🚣',
      '🧗',
      '🚵',
      '🚴',
      '🏆',
      '🥇',
      '🥈',
      '🥉',
      '🏅',
      '🎖️',
      '🎨',
      '🎮',
      '🎲',
      '🧩',
      '🎬',
      '🎤',
      '🎧',
      '🎼',
      '🎵',
      '🎶',
      '🎹',
      '🥁',
    ]),
    EmojiCategoryData('🍎 음식 & 카페', [
      '🍏',
      '🍎',
      '🍐',
      '🍊',
      '🍋',
      '🍌',
      '🍉',
      '🍇',
      '🍓',
      '🍈',
      '🍒',
      '🍑',
      '🥭',
      '🍍',
      '🥥',
      '🥝',
      '🍅',
      '🍆',
      '🥑',
      '🥦',
      '🥬',
      '🥒',
      '🌽',
      '🥕',
      '🍞',
      '🥐',
      '🥖',
      '🥨',
      '🥯',
      '🥞',
      '🧀',
      '🍖',
      '🍗',
      '🥩',
      '🥓',
      '🍔',
      '🍟',
      '🍕',
      '🌭',
      '🥪',
      '🌮',
      '🌯',
      '🍳',
      '🥘',
      '🍲',
      '🥣',
      '🥗',
      '🍿',
      '🍱',
      '🍘',
      '🍙',
      '🍚',
      '🍛',
      '🍜',
      '🍝',
      '🍠',
      '🍢',
      '🍣',
      '🍤',
      '🍥',
      '🍡',
      '🥟',
      '🥠',
      '🍦',
      '🍧',
      '🍨',
      '🍩',
      '🍪',
      '🎂',
      '🍰',
      '🧁',
      '🥧',
      '🍫',
      '🍬',
      '🍭',
      '🍮',
      '🍯',
      '☕',
      '🍵',
      '🍶',
      '🍾',
      '🍷',
      '🍸',
      '🍹',
      '🍺',
      '🍻',
      '🥂',
      '🥃',
      '🥤',
      '🥢',
    ]),
    EmojiCategoryData('✈️ 여행 & 일상', [
      '🚗',
      '🚕',
      '🚙',
      '🚌',
      '🏎️',
      '🚓',
      '🚑',
      '🚒',
      '🚐',
      '🚚',
      '🚛',
      '🚜',
      '🛵',
      '🏍️',
      '🚲',
      '🚨',
      '🚔',
      '🚍',
      '🚘',
      '🚖',
      '🚡',
      '🚠',
      '🚟',
      '🚃',
      '🚋',
      '🚝',
      '<ctrl42>',
      '🚅',
      '🚈',
      '🚂',
      '🚆',
      '🚇',
      '🚊',
      '🚉',
      '✈️',
      '🛫',
      '🛬',
      '🛩️',
      '💺',
      '🛰️',
      '🚀',
      '🛸',
      '🚁',
      '🛶',
      '⛵',
      '🚤',
      '🛥️',
      '🛳️',
      '⛴️',
      '🚢',
      '⚓',
      '⛽',
      '🚧',
      '🚦',
      '🚥',
      '🏠',
      '🏡',
      '🏢',
      '🏣',
      '🏥',
      '🏦',
      '🏨',
      '🏪',
      '🏫',
      '🏬',
      '🏭',
      '🏰',
      '🏯',
      '💒',
      '🗼',
      '🗽',
      '⛪',
      '🕌',
      '🕍',
      '⛩️',
      '🕋',
      '⛲',
      '⛺',
      '🌁',
      '🌃',
      '🏙️',
      '🌄',
      '🌅',
    ]),
    EmojiCategoryData('🐻 동물 & 자연', [
      '🐶',
      '🐱',
      '🐭',
      '🐹',
      '🐰',
      '🦊',
      '🐻',
      '🐼',
      '🐨',
      '🐯',
      '🦁',
      '🐮',
      '🐷',
      '🐽',
      '🐸',
      '🐵',
      '🙈',
      '🙉',
      '🙊',
      '🐒',
      '🐔',
      '🐧',
      '🐦',
      '🐤',
      '🐣',
      '🐥',
      '🦆',
      '🦅',
      '🦉',
      '🦇',
      '🐺',
      '🐗',
      '🐴',
      '🦄',
      '🐝',
      '🐛',
      '🦋',
      '🐌',
      '🐞',
      '🐜',
      '🦟',
      '<ctrl42>',
      '🕷️',
      '🕸️',
      '🦂',
      '🐢',
      '🐍',
      '🦎',
      '🦖',
      '🦕',
      '🐙',
      '🦑',
      '🦐',
      '🦞',
      '🦀',
      '🐡',
      '🐠',
      '🐟',
      '🐬',
      '🐳',
      '🐋',
      '🦈',
      '🐊',
      '🐅',
      '🐆',
      'Z',
      '🦍',
      '🦧',
      '🐘',
      '🦛',
      '🦏',
      '🐪',
      '🐫',
      '🦒',
      '🦘',
      '🦙',
      '🕊️',
      '🐕',
      '🐩',
      '🐈',
      '🐓',
      '🦃',
      '🦚',
      '🦜',
      '🌲',
      '🌳',
      '🌴',
      '🌱',
      '🌿',
      '☘️',
      '🍀',
      '🎍',
      '🎋',
      '🍃',
      '🍂',
      '🍁',
      '🍄',
      '🌾',
      '💐',
      '🌷',
      '🌹',
      '🥀',
      '🌺',
      '🌸',
      '🌼',
      '🌻',
      '🌞',
      '🌝',
      '🌛',
      '🌜',
      '🌚',
      '🌕',
      '🌖',
      '🌗',
      '🌘',
      '🌑',
      '🌒',
      '🌓',
      '🌔',
      '🌙',
      '🌎',
      '🌍',
      '🌏',
      '💫',
      '⭐️',
      '🌟',
      '✨',
      '⚡️',
      '☄️',
      '💥',
      '🔥',
      '🌪️',
      '🌈',
      '☀️',
      '🌤️',
      '⛅️',
      '🌥️',
      '☁️',
      '🌦️',
      '🌧️',
      '⛈️',
      '🌩️',
      '🌨️',
      '❄️',
    ]),
    EmojiCategoryData('🔣 기호 & 하트', [
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '💜',
      '🖤',
      '💔',
      '❣️',
      '💕',
      '💞',
      '💓',
      '💗',
      '💖',
      '💘',
      '💝',
      '💟',
      '☮️',
      '✝️',
      '☪️',
      '🕉️',
      '☸️',
      '✡️',
      '🔯',
      '🕎',
      '☯️',
      '☦️',
      '🛐',
      '⛎',
      '♈️',
      '♉️',
      '♊️',
      '♋️',
      '<ctrl42>',
      '♍️',
      '♎️',
      '♏️',
      '🏹',
      '♑️',
      '♒️',
      '♓️',
      '🆔',
      '⚛️',
      '☣️',
      '☢️',
      '📴',
      '📳',
      '🈶',
      '🈚️',
      '🈸',
      '🈺',
      '🈷️',
      '✴️',
      '🅰️',
      '🅱️',
      '🆎',
      '🆑',
      '🅾️',
      '🆘',
      '❌',
      '⭕️',
      '🛑',
      '⛔️',
      '📛',
      '🚫',
      '💯',
      '💢',
      '♨️',
      '🚷',
      '🚯',
      '🚳',
      '<ctrl42>',
      '🔞',
      '📵',
      '🚭',
      '❗️',
      '❕',
      '❓',
      '❔',
      '‼️',
      '⁉️',
      '🔆',
      '🔅',
      '⚠️',
      '🚸',
      '🔱',
      '⚜️',
      '🔰',
      '♻️',
      '✅',
      '🈯️',
      '📊',
      '📈',
      '📉',
      '❇️',
      '✳️',
      '❎',
      '🌐',
      '💠',
      'Ⓜ️',
      '🌀',
      '💤',
      '🏧',
      '🚾',
      '♿️',
      '🅿️',
      '🈳',
      '🈂️',
      '🛂',
      '🛃',
      '🛄',
      '🛅',
      '🚹',
      '<ctrl42>',
      '🚼',
      '🚻',
      '🚮',
      '🎦',
      '📶',
      '🈁',
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
                // Modal Handle Bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                // Title Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.emoji_emotions_outlined,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '유니코드 이모지 선택',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
                // Category Tabs
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: Theme.of(ctx).primaryColor,
                  labelColor: Theme.of(ctx).primaryColor,
                  unselectedLabelColor: isDark
                      ? Colors.grey[400]
                      : Colors.grey[600],
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
                            Text(
                              firstEmoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              categoryName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Tab Views (Emoji Grids)
                Expanded(
                  child: TabBarView(
                    children: _unicodeEmojiCategories.map((cat) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 30),
                              ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(category == null ? '신규 카테고리 추가' : '카테고리 수정'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Unicode Emoji Picker Selector Button
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  selectedEmoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
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
                        // Right: Category Name Input Field
                        Expanded(
                          child: TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: '카테고리 이름',
                              hintText: '예: 공부, 운동, 일상',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            autofocus: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '테마 색상 선택',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
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
                              border: isSelected
                                  ? Border.all(color: Colors.black, width: 3)
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
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
                      widget.provider.addCategory(
                        name,
                        selectedColor,
                        selectedEmoji,
                      );
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

  @override
  Widget build(BuildContext context) {
    final categories = widget.provider.categories;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 550),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.category, color: Colors.indigo),
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
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: categories.isEmpty
                  ? const Center(child: Text('등록된 카테고리가 없습니다.'))
                  : ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final color = _parseColor(cat.colorHex);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 0.5,
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                cat.emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                            title: Text(
                              cat.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () {
                                    _showAddOrEditCategoryDialog(category: cat);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    widget.provider.deleteCategory(cat.id!);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAddOrEditCategoryDialog(),
                icon: const Icon(Icons.add),
                label: const Text('새 카테고리 추가'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
