import 'package:flutter/material.dart';

import '../../app/coming_soon.dart';
import '../../l10n/app_localizations.dart';

/// 搜尋與視圖（T11 實作）。
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoon(
      title: AppLocalizations.of(context).navSearch,
      icon: Icons.search,
    );
  }
}
