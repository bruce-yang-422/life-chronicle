import '../shared/ios_group.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/repositories/security_service.dart';
import '../../l10n/app_localizations.dart';
import 'security_dialogs.dart';

class SecurityPage extends ConsumerStatefulWidget {
  const SecurityPage({super.key});
  @override
  ConsumerState<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends ConsumerState<SecurityPage> {
  bool authorized = false, busy = false, loaded = false;
  bool appLock = false,
      privateProtection = false,
      passwordOnly = false,
      hidePreview = false,
      familyPrivate = false;
  int timeout = 60;
  final password = TextEditingController();
  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  void _readConfig(SecurityService service) {
    if (loaded) return;
    loaded = true;
    final c = service.config;
    appLock = c.appLock;
    privateProtection = c.privateProtection;
    passwordOnly = c.passwordOnly;
    hidePreview = c.hidePreview;
    familyPrivate = c.familyPrivate;
    timeout = c.timeoutSeconds;
  }

  SecurityConfig get settings => SecurityConfig(
    appLock: appLock,
    privateProtection: privateProtection,
    passwordOnly: passwordOnly,
    hidePreview: hidePreview,
    timeoutSeconds: timeout,
    familyPrivate: familyPrivate,
  );

  Future<void> _save() async {
    final service = ref.read(securityProvider);
    final l = AppLocalizations.of(context);
    setState(() => busy = true);
    try {
      if (service.configured) {
        await service.updateConfig(settings);
      } else {
        final codes = await SecurityService.prepareCodes(
          password.text,
          iterations: service.iterations,
        );
        if (!mounted ||
            !await confirmSecurityCodes(
              context,
              recovery: codes.recovery,
              family: codes.family,
            )) {
          return;
        }
        await service.install(codes, settings);
        password.clear();
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(securityError(l, error))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _regenerate(bool recovery) async {
    final service = ref.read(securityProvider);
    final l = AppLocalizations.of(context);
    setState(() => busy = true);
    try {
      final staged = await service.prepareCode();
      if (!mounted ||
          !await confirmSecurityCodes(
            context,
            recovery: recovery ? staged.$1 : null,
            family: recovery ? null : staged.$1,
          )) {
        return;
      }
      await service.installCode(staged.$2, recovery: recovery);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(securityError(l, error))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final service = ref.watch(securityProvider);
    final content = service.family
        ? Center(child: Text(l.securityFamilyDenied))
        : service.configured && (!authorized || !service.ownerVerified)
        ? Center(
            child: FilledButton(
              onPressed: () async {
                final success = await authenticateSecurity(
                  context,
                  owner: true,
                );
                if (mounted && success) setState(() => authorized = true);
              },
              child: Text(l.securityUnlock),
            ),
          )
        : _settings(context, service, l);
    return Scaffold(
      appBar: AppBar(title: Text(l.securityTitle)),
      body: content,
    );
  }

  Widget _settings(
    BuildContext context,
    SecurityService service,
    AppLocalizations l,
  ) {
    _readConfig(service);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (!service.configured) ...[
              Text(l.securityConsequences),
              TextField(
                controller: password,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(labelText: l.securityAppPassword),
              ),
            ],
            const SizedBox(height: 16),
            IosGroup(
              children: [
                SwitchListTile.adaptive(
                  value: appLock,
                  onChanged: busy ? null : (v) => setState(() => appLock = v),
                  title: Text(l.securityAppLock),
                ),
                SwitchListTile.adaptive(
                  value: privateProtection,
                  onChanged: busy
                      ? null
                      : (v) => setState(() => privateProtection = v),
                  title: Text(l.securityProtectPrivate),
                ),
                if (privateProtection)
                  SwitchListTile.adaptive(
                    value: passwordOnly,
                    onChanged: busy
                        ? null
                        : (v) => setState(() => passwordOnly = v),
                    title: Text(l.securityPasswordOnly),
                  ),
                SwitchListTile.adaptive(
                  value: hidePreview,
                  onChanged: busy
                      ? null
                      : (v) => setState(() => hidePreview = v),
                  title: Text(l.securityHidePreview),
                ),
                DropdownButtonFormField<int>(
                  initialValue: timeout,
                  decoration: InputDecoration(labelText: l.securityTimeout),
                  items: [
                    DropdownMenuItem(
                      value: 0,
                      child: Text(l.securityImmediate),
                    ),
                    DropdownMenuItem(value: 60, child: Text(l.securityMinute)),
                    DropdownMenuItem(
                      value: 300,
                      child: Text(l.securityFiveMinutes),
                    ),
                  ],
                  onChanged: busy ? null : (v) => setState(() => timeout = v!),
                ),
                SwitchListTile.adaptive(
                  value: familyPrivate,
                  onChanged: busy
                      ? null
                      : (v) => setState(() => familyPrivate = v),
                  title: Text(l.securityFamilyPrivate),
                ),
              ],
            ),
            FilledButton(
              onPressed: busy ? null : _save,
              child: Text(l.securitySave),
            ),
            if (service.configured) ...[
              TextButton(
                onPressed: busy ? null : () => _regenerate(true),
                child: Text(l.securityRegenerateRecovery),
              ),
              TextButton(
                onPressed: busy ? null : () => _regenerate(false),
                child: Text(l.securityRegenerateFamily),
              ),
            ],
            if (busy) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
