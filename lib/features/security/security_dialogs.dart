import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/repositories/security_service.dart';
import '../../l10n/app_localizations.dart';

Map<String, String> securityPrompt(AppLocalizations l) => {
  'title': l.securityUnlock,
  'cancel': l.timelineCancel,
  'fallback': l.securityNative,
};

String securityError(AppLocalizations l, Object error) =>
    error is SecurityPaused
    ? l.securityPaused('${error.remaining.inSeconds + 1}')
    : l.securityFailed;

Future<bool> authorizePrivate(BuildContext context) async {
  final service = ProviderScope.containerOf(context).read(securityProvider);
  if (service.canReadPrivate) return true;
  if (service.family) {
    final l = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l.securityFamilyDenied),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.timelineCancel),
          ),
        ],
      ),
    );
    return false;
  }
  return authenticateSecurity(context, privateAccess: true);
}

Future<bool> authenticateSecurity(
  BuildContext context, {
  bool privateAccess = false,
  bool owner = false,
}) async {
  final service = ProviderScope.containerOf(context).read(securityProvider);
  if (owner && service.family) return false;
  final l = AppLocalizations.of(context);
  final input = TextEditingController();
  String? error;
  var waiting = false;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) {
        Future<void> attempt(bool native) async {
          setLocal(() => waiting = true);
          try {
            final success = native
                ? await service.authenticateNative(
                    l.securityReason,
                    prompt: securityPrompt(l),
                    privateAccess: privateAccess,
                    owner: owner,
                  )
                : await service.authenticatePassword(
                    input.text,
                    privateAccess: privateAccess,
                    owner: owner,
                    familyName: l.securityFamilyName,
                  );
            if (!context.mounted) return;
            if (success) {
              input.clear();
              Navigator.pop(context, true);
            } else {
              setLocal(() => error = l.securityFailed);
            }
          } catch (failure) {
            if (context.mounted) {
              setLocal(() => error = securityError(l, failure));
            }
          } finally {
            if (context.mounted) setLocal(() => waiting = false);
          }
        }

        return AlertDialog(
          title: Text(
            privateAccess ? l.securityPrivateUnlock : l.securityTitle,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: input,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: owner
                        ? l.securityAppPassword
                        : l.securityPassword,
                  ),
                ),
                if (error != null) Text(error!),
                if (waiting) const LinearProgressIndicator(),
                if (!(privateAccess && service.config.passwordOnly))
                  TextButton.icon(
                    onPressed: waiting ? null : () => attempt(true),
                    icon: const Icon(Icons.fingerprint),
                    label: Text(l.securityNative),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: waiting ? null : () => Navigator.pop(context, false),
              child: Text(l.timelineCancel),
            ),
            FilledButton(
              onPressed: waiting ? null : () => attempt(false),
              child: Text(l.securityUnlock),
            ),
          ],
        );
      },
    ),
  );
  Future<void>.delayed(const Duration(seconds: 1), input.dispose);
  return result == true;
}

Future<bool> confirmSecurityCodes(
  BuildContext context, {
  String? recovery,
  String? family,
}) async {
  final l = AppLocalizations.of(context);
  var copied = false;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => StatefulBuilder(
          builder: (context, setLocal) => AlertDialog(
            title: Text(l.securitySetup),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.securityConsequences),
                  if (recovery != null) ...[
                    Text(l.securityRecovery),
                    SelectableText(recovery),
                  ],
                  if (family != null) ...[
                    Text(l.securityFamily),
                    SelectableText(family),
                  ],
                  CheckboxListTile(
                    value: copied,
                    onChanged: (value) => setLocal(() => copied = value!),
                    title: Text(l.securityCopyConfirm),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l.timelineCancel),
              ),
              FilledButton(
                onPressed: copied ? () => Navigator.pop(context, true) : null,
                child: Text(l.securitySave),
              ),
            ],
          ),
        ),
      ) ==
      true;
}

Future<void> resetForgottenPassword(BuildContext context) async {
  final service = ProviderScope.containerOf(context).read(securityProvider);
  final l = AppLocalizations.of(context);
  try {
    // 必須先嘗試手機原生驗證，失敗後才顯示復原碼輸入。
    var authorized = await service.authenticateNative(
      l.securityReason,
      prompt: securityPrompt(l),
      owner: true,
    );
    if (!context.mounted) return;
    if (!authorized) {
      final code = TextEditingController();
      final supplied = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.securityRecovery),
          content: TextField(
            controller: code,
            obscureText: true,
            enableSuggestions: false,
            decoration: InputDecoration(labelText: l.securityRecovery),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.timelineCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, code.text),
              child: Text(l.securityReset),
            ),
          ],
        ),
      );
      Future<void>.delayed(const Duration(seconds: 1), code.dispose);
      if (supplied == null) return;
      authorized = await service.authorizeRecovery(supplied);
    }
    if (!context.mounted) return;
    if (!authorized) throw StateError(l.securityFailed);
    final password = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.securityReset),
        content: TextField(
          controller: password,
          obscureText: true,
          enableSuggestions: false,
          decoration: InputDecoration(labelText: l.securityAppPassword),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.timelineCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, password.text),
            child: Text(l.securityReset),
          ),
        ],
      ),
    );
    Future<void>.delayed(const Duration(seconds: 1), password.dispose);
    if (value == null) return;
    final codes = await SecurityService.prepareCodes(
      value,
      iterations: service.iterations,
    );
    if (context.mounted &&
        await confirmSecurityCodes(context, recovery: codes.recovery)) {
      await service.resetPassword(codes);
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(securityError(l, error))));
    }
  }
}
