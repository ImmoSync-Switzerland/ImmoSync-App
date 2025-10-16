import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/device_verification_service.dart';
import '../providers/auth_provider.dart';

/// Provider for device verification status
final deviceVerificationProvider = StateNotifierProvider<DeviceVerificationNotifier, AsyncValue<DeviceVerificationResult?>>((ref) {
  return DeviceVerificationNotifier(ref);
});

class DeviceVerificationNotifier extends StateNotifier<AsyncValue<DeviceVerificationResult?>> {
  final Ref _ref;
  final DeviceVerificationService _service = DeviceVerificationService.instance;

  DeviceVerificationNotifier(this._ref) : super(const AsyncValue.loading()) {
    _initializeDeviceVerification();
  }

  Future<void> _initializeDeviceVerification() async {
    try {
      // First try to load stored status
      final stored = await _service.loadStoredStatus();
      if (stored != null && stored.isVerified) {
        state = AsyncValue.data(stored);
        return;
      }

      // Get auth info
      final authState = _ref.read(authProvider);
      final userId = authState.userId;
      final authToken = authState.sessionToken;

      if (userId == null || authToken == null) {
        state = const AsyncValue.data(null);
        return;
      }

      // Check current status with backend
      final result = await _service.checkVerificationStatus(
        userId: userId,
        authToken: authToken,
      );

      // If device not registered, register it
      if (result.status == DeviceVerificationStatus.unknown) {
        final registerResult = await _service.registerDevice(
          userId: userId,
          authToken: authToken,
        );
        state = AsyncValue.data(registerResult);
      } else {
        state = AsyncValue.data(result);
      }

      // Start polling if pending verification
      if (result.isPending) {
        _service.startPollingVerificationStatus(
          userId: userId,
          authToken: authToken,
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      final authState = _ref.read(authProvider);
      final userId = authState.userId;
      final authToken = authState.sessionToken;

      if (userId == null || authToken == null) return;

      await _service.resendVerificationEmail(
        userId: userId,
        authToken: authToken,
      );
    } catch (e) {
      debugPrint('[DeviceVerification] Error resending email: $e');
    }
  }

  Future<void> checkStatus() async {
    try {
      final authState = _ref.read(authProvider);
      final userId = authState.userId;
      final authToken = authState.sessionToken;

      if (userId == null || authToken == null) return;

      final result = await _service.checkVerificationStatus(
        userId: userId,
        authToken: authToken,
      );

      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

/// Banner widget that shows device verification status
class DeviceVerificationBanner extends ConsumerWidget {
  const DeviceVerificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationState = ref.watch(deviceVerificationProvider);

    return verificationState.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (result) {
        if (result == null || result.isVerified) {
          return const SizedBox.shrink();
        }

        if (result.isPending) {
          return _buildPendingBanner(context, ref);
        }

        if (result.status == DeviceVerificationStatus.failed) {
          return _buildFailedBanner(context, ref);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPendingBanner(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.email_outlined, color: Colors.orange.shade900),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Gerät verifizieren',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bitte überprüfen Sie Ihre E-Mails und klicken Sie auf den Verifizierungslink.',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              ref.read(deviceVerificationProvider.notifier).resendVerificationEmail();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('E-Mail wurde erneut gesendet')),
              );
            },
            child: const Text(
              'Erneut senden',
              style: TextStyle(fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () {
              ref.read(deviceVerificationProvider.notifier).checkStatus();
            },
            tooltip: 'Status aktualisieren',
          ),
        ],
      ),
    );
  }

  Widget _buildFailedBanner(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      color: Colors.red.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade900),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Geräte-Verifizierung fehlgeschlagen. Bitte versuchen Sie es erneut.',
              style: TextStyle(
                color: Colors.red.shade900,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(deviceVerificationProvider.notifier).resendVerificationEmail();
            },
            child: const Text(
              'Erneut versuchen',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen dialog that blocks the app until device is verified
class DeviceVerificationDialog extends ConsumerStatefulWidget {
  const DeviceVerificationDialog({super.key});

  @override
  ConsumerState<DeviceVerificationDialog> createState() => _DeviceVerificationDialogState();
}

class _DeviceVerificationDialogState extends ConsumerState<DeviceVerificationDialog> {
  bool _isResending = false;

  @override
  Widget build(BuildContext context) {
    final verificationState = ref.watch(deviceVerificationProvider);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.email_outlined,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Gerät verifizieren',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Um die Sicherheit Ihres Kontos zu gewährleisten, müssen Sie dieses Gerät verifizieren.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Wir haben Ihnen eine E-Mail mit einem Verifizierungslink gesendet. Bitte klicken Sie auf den Link, um fortzufahren.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            verificationState.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text(
                'Fehler: $error',
                style: const TextStyle(color: Colors.red),
              ),
              data: (result) {
                if (result?.isVerified ?? false) {
                  // Device is verified, close dialog
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pop();
                  });
                  return const Icon(Icons.check_circle, color: Colors.green, size: 48);
                }

                return Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(deviceVerificationProvider.notifier).checkStatus();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Status aktualisieren'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isResending
                          ? null
                          : () async {
                              setState(() => _isResending = true);
                              await ref.read(deviceVerificationProvider.notifier).resendVerificationEmail();
                              if (mounted) {
                                setState(() => _isResending = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('E-Mail wurde erneut gesendet')),
                                );
                              }
                            },
                      child: _isResending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Verifizierungs-E-Mail erneut senden'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
