import 'package:flutter/material.dart';

/// 共用的 iOS 分組區塊；保留原有表單與無障礙語意。
class IosGroup extends StatelessWidget {
  const IosGroup({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Text(
                title!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Theme(
            data: theme.copyWith(
              inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            child: Material(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    if (index > 0) const Divider(height: 1, indent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: children[index],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IosPageTitle extends StatelessWidget {
  const IosPageTitle(this.title, {super.key, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
        ),
        ?action,
      ],
    ),
  );
}
