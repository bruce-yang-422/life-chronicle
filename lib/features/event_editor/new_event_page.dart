import 'package:flutter/material.dart';

import '../../app/coming_soon.dart';
import '../../l10n/app_localizations.dart';

/// 新增節點（T08 實作）。
class NewEventPage extends StatelessWidget {
  const NewEventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoon(
      title: AppLocalizations.of(context).navNewEvent,
      icon: Icons.add_circle_outline,
    );
  }
}
