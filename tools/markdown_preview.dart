import 'package:flutter/material.dart';
import 'package:life_chronicle/features/shared/markdown_content.dart';
import 'package:life_chronicle/l10n/app_localizations.dart';

/// 獨立介面驗證，不讀寫正式資料庫或草稿。
void main() => runApp(
  MaterialApp(
    locale: const Locale('zh', 'TW'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      appBar: AppBar(title: const Text('Markdown / emoji 測試')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: MarkdownEditor(
          label: '記述',
          onChanged: (_) {},
          initialValue: '# 生活紀錄 🎉\n\n**重要回憶** 與 *感謝* 🙂\n\n- 旅行 👍🏽\n- 家人 👨‍👩‍👧‍👦\n\n> 平凡日子也值得留下\n\n| 年齡 | 生活紀錄 |\n| ---: | :--- |\n| 16 | **科展** 🎉 |\n| 35 | 新家 👨‍👩‍👧‍👦 |',
        ),
      ),
    ),
  ),
);
