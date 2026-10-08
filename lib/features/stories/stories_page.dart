import 'package:flutter/material.dart';

import '../../app/coming_soon.dart';
import '../../l10n/app_localizations.dart';

/// 故事篇章（第二階段實作）。
class StoriesPage extends StatelessWidget {
  const StoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoon(
      title: AppLocalizations.of(context).navStories,
      icon: Icons.menu_book_outlined,
    );
  }
}
