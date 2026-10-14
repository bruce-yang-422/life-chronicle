import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// 品牌區顯示正式中英文名稱。
class TimelineMasthead extends StatelessWidget {
  const TimelineMasthead({super.key, this.trailing});
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (l10n.appTitle != l10n.timelineBrandEnglish) ...[
                  const SizedBox(height: 3),
                  Text(
                    l10n.timelineBrandEnglish,
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 3.2,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) Positioned(right: 8, top: 4, child: trailing!),
        ],
      ),
    );
  }
}
