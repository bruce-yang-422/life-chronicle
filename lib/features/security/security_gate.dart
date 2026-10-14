import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import 'security_dialogs.dart';

/// 包住整個 Navigator，鎖定時連已開啟的詳情與對話框都不可見。
class SecurityGate extends ConsumerStatefulWidget {
  const SecurityGate({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends ConsumerState<SecurityGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final service = ref.read(securityProvider);
    if (state == AppLifecycleState.resumed) {
      service.resume();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      service.leave();
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(securityProvider);
    final blocked =
        service.loading ||
        service.error != null ||
        service.locked ||
        service.hidden;
    return Stack(
      children: [
        Offstage(
          offstage: blocked,
          child: TickerMode(enabled: !blocked, child: widget.child),
        ),
        if (blocked)
          Positioned.fill(
            child: HeroControllerScope.none(
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => const _UnlockPage(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _UnlockPage extends ConsumerStatefulWidget {
  const _UnlockPage();
  @override
  ConsumerState<_UnlockPage> createState() => _UnlockPageState();
}

class _UnlockPageState extends ConsumerState<_UnlockPage> {
  final input = TextEditingController();
  bool waiting = false;
  String? error;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> _authenticate(bool native) async {
    final service = ref.read(securityProvider);
    final l = AppLocalizations.of(context);
    setState(() => waiting = true);
    try {
      final success = native
          ? await service.authenticateNative(
              l.securityReason,
              prompt: securityPrompt(l),
            )
          : await service.authenticatePassword(
              input.text,
              familyName: l.securityFamilyName,
            );
      if (mounted) {
        if (success) {
          input.clear();
        } else {
          setState(() => error = l.securityFailed);
        }
      }
    } catch (failure) {
      if (mounted) setState(() => error = securityError(l, failure));
    } finally {
      if (mounted) setState(() => waiting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final service = ref.watch(securityProvider);
    if (service.loading || service.hidden) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (service.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.securityStorageError),
              TextButton(onPressed: service.load, child: Text(l.timelineRetry)),
            ],
          ),
        ),
      );
    }
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(24),
                children: [
                  const Icon(Icons.lock_outline, size: 48),
                  Text(
                    l.securityTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextField(
                    controller: input,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(labelText: l.securityPassword),
                  ),
                  if (error != null) Text(error!),
                  if (waiting) const LinearProgressIndicator(),
                  FilledButton(
                    onPressed: waiting ? null : () => _authenticate(false),
                    child: Text(l.securityUnlock),
                  ),
                  TextButton.icon(
                    onPressed: waiting ? null : () => _authenticate(true),
                    icon: const Icon(Icons.fingerprint),
                    label: Text(l.securityNative),
                  ),
                  TextButton(
                    onPressed: waiting
                        ? null
                        : () => resetForgottenPassword(context),
                    child: Text(l.securityForgot),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
