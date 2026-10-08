import 'package:flutter/material.dart';

import '../../app/coming_soon.dart';
import '../../l10n/app_localizations.dart';

/// 人生時間軸首頁（T07 實作）。
class TimelinePage extends StatelessWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoon(
      title: AppLocalizations.of(context).navTimeline,
      icon: Icons.schedule_outlined,
    );
  }
}
