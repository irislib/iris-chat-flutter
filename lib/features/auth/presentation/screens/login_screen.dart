import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/providers/auth_provider.dart';
import '../../../../config/providers/chat_provider.dart';
import '../../../../config/providers/invite_provider.dart';
import '../../../../config/providers/login_device_registration_provider.dart';
import '../../../../core/ffi/ndr_ffi.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _keyController = TextEditingController();
  bool _showKeyInput = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _createIdentity() async {
    // "Create new identity" must start from a clean local state so we don't
    // leak prior-account chats into a brand new account.
    await ref.read(databaseServiceProvider).deleteDatabase();
    ref.invalidate(sessionStateProvider);
    ref.invalidate(chatStateProvider);
    ref.invalidate(groupStateProvider);
    ref.invalidate(inviteStateProvider);

    await ref.read(authStateProvider.notifier).createIdentity();
    final state = ref.read(authStateProvider);
    if (!state.isAuthenticated) return;

    await _autoRegisterCurrentDeviceForNewIdentity();
    if (!mounted) return;
    context.go('/chats');
  }

  Future<void> _autoRegisterCurrentDeviceForNewIdentity() async {
    final authState = ref.read(authStateProvider);
    final ownerPubkeyHex = authState.pubkeyHex;
    if (ownerPubkeyHex == null) return;

    final ownerPrivkeyHex = await ref
        .read(authRepositoryProvider)
        .getPrivateKey();
    if (ownerPrivkeyHex == null) return;

    try {
      await ref
          .read(loginDeviceRegistrationServiceProvider)
          .publishSingleDevice(
            ownerPubkeyHex: ownerPubkeyHex,
            ownerPrivkeyHex: ownerPrivkeyHex,
            devicePubkeyHex: ownerPubkeyHex,
          );
    } catch (_) {
      // Non-blocking: account creation should still complete even if relay
      // publishing fails.
    }
  }

  Future<void> _login() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;

    final registrationService = ref.read(
      loginDeviceRegistrationServiceProvider,
    );

    LoginDeviceRegistrationPreview? preview;
    var shouldRegisterDevice = false;
    try {
      preview = await registrationService.buildPreviewFromPrivateKeyNsec(key);
      if (!mounted) return;
      final decision = await _showDeviceRegistrationDialog(preview);
      if (decision == null) return;
      shouldRegisterDevice = decision;
    } catch (_) {
      // Allow auth flow to surface invalid key / storage errors.
    }

    await ref.read(authStateProvider.notifier).login(key);
    final state = ref.read(authStateProvider);
    if (!state.isAuthenticated) return;

    if (shouldRegisterDevice && preview != null) {
      try {
        await registrationService.publishDeviceList(
          ownerPubkeyHex: preview.ownerPubkeyHex,
          ownerPrivkeyHex: preview.ownerPrivkeyHex,
          devices: preview.devicesIfRegistered,
        );
      } catch (_) {
        // Non-blocking: login succeeds even if relay publishing fails.
      }
    }

    if (!mounted) return;
    context.go('/chats');
  }

  Future<bool?> _showDeviceRegistrationDialog(
    LoginDeviceRegistrationPreview preview,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Register This Device?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!preview.deviceListLoaded) ...[
                  const Text(
                    'Could not fully load device list from relays. You can still sign in.',
                  ),
                  if (preview.deviceListLoadError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      preview.deviceListLoadError!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
                _buildDeviceListSection(
                  title: 'Current devices',
                  devices: preview.existingDevices,
                  currentDevicePubkeyHex: preview.currentDevicePubkeyHex,
                ),
                const SizedBox(height: 12),
                _buildDeviceListSection(
                  title: 'After registering this device',
                  devices: preview.devicesIfRegistered,
                  currentDevicePubkeyHex: preview.currentDevicePubkeyHex,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Sign In Without Registering'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sign In and Register'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceListSection({
    required String title,
    required List<FfiDeviceEntry> devices,
    required String currentDevicePubkeyHex,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (devices.isEmpty)
          const Text('No registered devices')
        else
          for (final device in devices)
            Text(
              '• ${_shortPubkey(device.identityPubkeyHex)}${_isCurrentDevice(device.identityPubkeyHex, currentDevicePubkeyHex) ? ' (this device)' : ''}',
            ),
      ],
    );
  }

  bool _isCurrentDevice(String devicePubkeyHex, String currentDevicePubkeyHex) {
    return devicePubkeyHex.trim().toLowerCase() ==
        currentDevicePubkeyHex.trim().toLowerCase();
  }

  String _shortPubkey(String pubkeyHex) {
    if (pubkeyHex.length <= 16) return pubkeyHex;
    return '${pubkeyHex.substring(0, 8)}...${pubkeyHex.substring(pubkeyHex.length - 8)}';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Logo/Title
              Image.asset('assets/icons/app_icon.png', width: 100, height: 100),
              const SizedBox(height: 24),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: 'iris',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                    const TextSpan(text: ' chat'),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Error message
              if (authState.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    authState.error!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Key input (if showing)
              if (_showKeyInput) ...[
                TextField(
                  controller: _keyController,
                  decoration: InputDecoration(
                    labelText: 'Private Key (nsec)',
                    hintText: 'Enter your private key',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _showKeyInput = false;
                          _keyController.clear();
                        });
                        ref.read(authStateProvider.notifier).clearError();
                      },
                    ),
                  ),
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: authState.isLoading ? null : _login,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
              ] else ...[
                // Create new identity button
                FilledButton.icon(
                  onPressed: authState.isLoading ? null : _createIdentity,
                  icon: const Icon(Icons.add),
                  label: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create New Identity'),
                ),
                const SizedBox(height: 12),
                // Import existing key button
                OutlinedButton.icon(
                  onPressed: authState.isLoading
                      ? null
                      : () => setState(() => _showKeyInput = true),
                  icon: const Icon(Icons.key),
                  label: const Text('Import Existing Key'),
                ),
                const SizedBox(height: 12),
                // Link device button (delegated device login)
                TextButton.icon(
                  onPressed: authState.isLoading
                      ? null
                      : () => context.push('/link'),
                  icon: const Icon(Icons.devices),
                  label: const Text('Link This Device'),
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
