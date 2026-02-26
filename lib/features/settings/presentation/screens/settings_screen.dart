import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nostr/nostr.dart' as nostr;
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/providers/auth_provider.dart';
import '../../../../config/providers/chat_provider.dart';
import '../../../../config/providers/desktop_notification_provider.dart';
import '../../../../config/providers/device_manager_provider.dart';
import '../../../../config/providers/invite_provider.dart';
import '../../../../config/providers/messaging_preferences_provider.dart';
import '../../../../config/providers/mobile_push_provider.dart';
import '../../../../config/providers/startup_launch_provider.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../shared/utils/formatters.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final deviceState = ref.watch(deviceManagerProvider);
    final startupLaunchState = ref.watch(startupLaunchProvider);
    final messagingPreferences = ref.watch(messagingPreferencesProvider);
    final desktopNotificationsSupported = ref.watch(
      desktopNotificationsSupportedProvider,
    );
    final mobilePushSupported = ref.watch(mobilePushSupportedProvider);
    final npub = authState.pubkeyHex != null
        ? formatPubkeyAsNpub(authState.pubkeyHex!)
        : null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Identity section
          const _SectionHeader(title: 'Identity'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Public Key'),
            subtitle: Text(
              npub != null ? formatPubkeyForDisplay(npub) : 'Not logged in',
            ),
            trailing: npub != null
                ? IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: npub));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied public key')),
                        );
                      }
                    },
                  )
                : null,
          ),

          // Devices section
          const _SectionHeader(title: 'Devices'),
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Link a Device'),
            subtitle: Text(
              authState.isLinkedDevice
                  ? 'Linked devices cannot link new devices'
                  : 'Scan a link invite from the new device',
            ),
            onTap: authState.isLinkedDevice
                ? null
                : () => context.push('/invite/scan'),
          ),
          if (!authState.isLinkedDevice &&
              !deviceState.isCurrentDeviceRegistered)
            ListTile(
              leading: const Icon(Icons.app_registration),
              title: const Text('Register This Device'),
              subtitle: const Text(
                'Add this device to your encrypted messaging devices',
              ),
              onTap: deviceState.isUpdating
                  ? null
                  : () => _registerCurrentDevice(context, ref),
            ),
          if (authState.isLinkedDevice)
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Device Management'),
              subtitle: Text('Manage registered devices on your main client'),
            ),
          if (!authState.isLinkedDevice && deviceState.isLoading)
            const ListTile(
              leading: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Loading registered devices...'),
            ),
          if (!authState.isLinkedDevice &&
              !deviceState.isLoading &&
              deviceState.devices.isEmpty)
            const ListTile(
              leading: Icon(Icons.devices_other),
              title: Text('No registered devices yet'),
              subtitle: Text(
                'Register this device to enable multi-device sync',
              ),
            ),
          if (!authState.isLinkedDevice)
            ...deviceState.devices.map((device) {
              final isCurrent =
                  device.identityPubkeyHex ==
                  deviceState.currentDevicePubkeyHex;
              final addedAt = DateTime.fromMillisecondsSinceEpoch(
                device.createdAt * 1000,
              );
              return ListTile(
                leading: const Icon(Icons.computer),
                title: Text(
                  formatPubkeyForDisplay(
                    formatPubkeyAsNpub(device.identityPubkeyHex),
                  ),
                ),
                subtitle: Text(
                  isCurrent
                      ? 'This device • Added ${formatDate(addedAt)}'
                      : 'Added ${formatDate(addedAt)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: isCurrent ? 'Remove this device' : 'Delete device',
                  onPressed: deviceState.isUpdating
                      ? null
                      : () => _confirmDeleteDevice(
                          context,
                          ref,
                          identityPubkeyHex: device.identityPubkeyHex,
                          isCurrentDevice: isCurrent,
                        ),
                ),
              );
            }),
          if (deviceState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                deviceState.error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ),

          // Security section
          const _SectionHeader(title: 'Security'),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('Export Private Key'),
            subtitle: const Text('Backup your key securely'),
            onTap: () => _showExportKeyDialog(context, ref),
          ),

          // Messaging section
          const _SectionHeader(title: 'Messaging'),
          SwitchListTile(
            secondary: const Icon(Icons.keyboard),
            title: const Text('Send Typing Indicators'),
            subtitle: const Text(
              'Share when you are actively typing in a conversation',
            ),
            value: messagingPreferences.typingIndicatorsEnabled,
            onChanged: messagingPreferences.isLoading
                ? null
                : (value) => ref
                      .read(messagingPreferencesProvider.notifier)
                      .setTypingIndicatorsEnabled(value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.done_all),
            title: const Text('Send Delivery Receipts'),
            subtitle: const Text('Allow others to see when messages arrive'),
            value: messagingPreferences.deliveryReceiptsEnabled,
            onChanged: messagingPreferences.isLoading
                ? null
                : (value) => ref
                      .read(messagingPreferencesProvider.notifier)
                      .setDeliveryReceiptsEnabled(value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.visibility),
            title: const Text('Send Read Receipts'),
            subtitle: const Text('Allow others to see when you open messages'),
            value: messagingPreferences.readReceiptsEnabled,
            onChanged: messagingPreferences.isLoading
                ? null
                : (value) => ref
                      .read(messagingPreferencesProvider.notifier)
                      .setReadReceiptsEnabled(value),
          ),
          if (desktopNotificationsSupported)
            SwitchListTile(
              secondary: const Icon(Icons.notifications_active),
              title: const Text('Desktop Notifications'),
              subtitle: const Text(
                'Show incoming message and reaction alerts when app is unfocused',
              ),
              value: messagingPreferences.desktopNotificationsEnabled,
              onChanged: messagingPreferences.isLoading
                  ? null
                  : (value) => ref
                        .read(messagingPreferencesProvider.notifier)
                        .setDesktopNotificationsEnabled(value),
            ),
          if (mobilePushSupported)
            SwitchListTile(
              secondary: const Icon(Icons.phone_iphone),
              title: const Text('Mobile Push Notifications'),
              subtitle: const Text(
                'Register this device for server-delivered chat push alerts',
              ),
              value: messagingPreferences.mobilePushNotificationsEnabled,
              onChanged: messagingPreferences.isLoading
                  ? null
                  : (value) => ref
                        .read(messagingPreferencesProvider.notifier)
                        .setMobilePushNotificationsEnabled(value),
            ),
          if (messagingPreferences.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                messagingPreferences.error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ),

          // Application section
          if (startupLaunchState.isLoading || startupLaunchState.isSupported)
            const _SectionHeader(title: 'Application'),
          if (startupLaunchState.isLoading || startupLaunchState.isSupported)
            SwitchListTile(
              secondary: const Icon(Icons.power_settings_new),
              title: const Text('Launch on System Startup'),
              subtitle: Text(
                startupLaunchState.isLoading
                    ? 'Applying startup setting...'
                    : 'Automatically start iris chat when you log in',
              ),
              value: startupLaunchState.enabled,
              onChanged: startupLaunchState.isLoading
                  ? null
                  : (value) => ref
                        .read(startupLaunchProvider.notifier)
                        .setEnabled(value),
            ),
          if (startupLaunchState.error != null &&
              (startupLaunchState.isLoading || startupLaunchState.isSupported))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                startupLaunchState.error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ),

          // About section
          const _SectionHeader(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Source Code'),
            subtitle: const Text('github.com/irislib/iris-chat-flutter'),
            onTap: () =>
                _openUrl('https://github.com/irislib/iris-chat-flutter'),
          ),

          // Danger zone
          const _SectionHeader(title: 'Danger Zone'),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              'Logout',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: const Text('Remove local chats from this device'),
            onTap: () => _confirmLogout(context, ref),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
            title: Text(
              'Delete All Data',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: const Text('Remove all data including keys'),
            onTap: () => _confirmDeleteAll(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showExportKeyDialog(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authStateProvider);
    if (authState.isLinkedDevice) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Private Key'),
          content: const Text(
            'This is a linked device. It does not store your main private key.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final shouldCopy = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Private Key'),
        content: const Text(
          'Your private key gives full access to your identity. '
          'Never share it with anyone. Make sure to store it securely.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Copy'),
          ),
        ],
      ),
    );

    if ((shouldCopy ?? false) && context.mounted) {
      final authRepo = ref.read(authRepositoryProvider);
      final privkey = await authRepo.getPrivateKey();

      if (privkey != null && context.mounted) {
        final exportableKey = _toExportableNsec(privkey);
        await Clipboard.setData(ClipboardData(text: exportableKey));
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
        }
      }
    }
  }

  String _toExportableNsec(String privateKey) {
    final normalized = privateKey.trim().toLowerCase();

    // Existing installs store the private key as 64-char hex. Convert to nsec
    // so exported keys can be re-imported through the nsec-only login flow.
    if (RegExp(r'^[0-9a-f]{64}$').hasMatch(normalized)) {
      try {
        final encoded = nostr.Nip19.encodePrivkey(normalized);
        if (encoded is String && encoded.isNotEmpty) {
          return encoded;
        }
      } catch (_) {}
    }

    return privateKey;
  }

  Future<void> _registerCurrentDevice(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ok = await ref
        .read(deviceManagerProvider.notifier)
        .registerCurrentDevice();
    if (!context.mounted) return;

    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Device registered')));
      return;
    }

    final error = ref.read(deviceManagerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Failed to register device')),
    );
  }

  Future<void> _confirmDeleteDevice(
    BuildContext context,
    WidgetRef ref, {
    required String identityPubkeyHex,
    required bool isCurrentDevice,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCurrentDevice ? 'Remove This Device?' : 'Delete Device?'),
        content: Text(
          isCurrentDevice
              ? 'This removes the current device from your authorized device list. '
                    'You can register it again later.'
              : 'This device will no longer be authorized for encrypted messaging.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(isCurrentDevice ? 'Remove' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final ok = await ref
        .read(deviceManagerProvider.notifier)
        .deleteDevice(identityPubkeyHex);
    if (!context.mounted) return;

    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Device removed')));
      return;
    }

    final error = ref.read(deviceManagerProvider).error;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? 'Failed to remove device')));
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text(
          'This signs you out and deletes local chats from this device. '
          'Keep your private key to log back in later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      await ref.read(databaseServiceProvider).deleteDatabase();
      _invalidateChatProviders(ref);
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text(
          'This will permanently delete your identity, messages, and all app data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      // Clear database
      final dbService = ref.read(databaseServiceProvider);
      await dbService.deleteDatabase();
      _invalidateChatProviders(ref);

      // Clear secure storage
      final secureStorage = SecureStorageService();
      await secureStorage.clearIdentity();

      // Logout (clears auth state)
      await ref.read(authStateProvider.notifier).logout();

      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  void _invalidateChatProviders(WidgetRef ref) {
    ref.invalidate(sessionStateProvider);
    ref.invalidate(chatStateProvider);
    ref.invalidate(groupStateProvider);
    ref.invalidate(inviteStateProvider);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
