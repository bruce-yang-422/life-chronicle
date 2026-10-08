import 'package:flutter/material.dart';

import '../../app/coming_soon.dart';
import '../../l10n/app_localizations.dart';

/// 資料與備份（T12、T13 實作）。
class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoon(
      title: AppLocalizations.of(context).navBackup,
      icon: Icons.storage_outlined,
    );
  }
}
