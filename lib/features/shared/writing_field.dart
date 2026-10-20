import 'package:flutter/material.dart';

/// 書寫欄位明確顯示邊界，不受分組清單的無框輸入主題影響。
InputDecoration writingDecoration(BuildContext context, String hint) {
  final colors = Theme.of(context).colorScheme;
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    hintText: hint,
    hintMaxLines: 3,
    filled: true,
    fillColor: colors.surfaceContainerLowest,
    contentPadding: const EdgeInsets.all(12),
    border: border(colors.outlineVariant),
    enabledBorder: border(colors.outlineVariant),
    focusedBorder: border(colors.primary, 2),
    errorBorder: border(colors.error),
    focusedErrorBorder: border(colors.error, 2),
  );
}
