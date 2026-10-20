import 'dart:convert';

enum TagMatchMode { all, any }

/// 主題條件是權威資料，符合條件的事件清單是即時計算的衍生結果。
class ThemeRule {
  ThemeRule({
    required this.mode,
    required Iterable<String> include,
    Iterable<String> exclude = const [],
  }) : include = Set.unmodifiable(include),
       exclude = Set.unmodifiable(exclude) {
    if (this.include.isEmpty ||
        this.include.any((s) => s.isEmpty) ||
        this.exclude.any((s) => s.isEmpty) ||
        this.include.intersection(this.exclude).isNotEmpty) {
      throw const FormatException('invalid_theme_rule');
    }
  }
  final TagMatchMode mode;
  final Set<String> include, exclude;
  bool matches(Set<String> tags) =>
      !exclude.any(tags.contains) &&
      (mode == TagMatchMode.all
          ? include.every(tags.contains)
          : include.any(tags.contains));
  Map<String, Object?> toJson() => {
    'mode': mode.name,
    'include': include.toList()..sort(),
    'exclude': exclude.toList()..sort(),
  };
  String encode() => jsonEncode(toJson());
  factory ThemeRule.decode(String value) {
    final json = jsonDecode(value) as Map<String, dynamic>;
    if (json.keys.toSet().difference({
      'mode',
      'include',
      'exclude',
    }).isNotEmpty) {
      throw const FormatException('unknown_theme_rule_field');
    }
    return ThemeRule(
      mode: TagMatchMode.values.byName(json['mode'] as String),
      include: (json['include'] as List).cast<String>(),
      exclude: (json['exclude'] as List).cast<String>(),
    );
  }
  ThemeRule remap(Map<String, String> ids) => ThemeRule(
    mode: mode,
    include: include.map((id) => ids[id] ?? id),
    exclude: exclude.map((id) => ids[id] ?? id),
  );
}
