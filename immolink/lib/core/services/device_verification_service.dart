import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'device_fingerprint_service.dart';

/// Status of device verification
enum DeviceVerificationStatus {
  /// Device is verified and can send encrypted messages
  verified,

  /// Device is pending email verification
  pendingVerification,

  /// Device verification failed or expired
  failed,

  /// Unknown status (not yet checked)
  unknown,
}

class DeviceVerificationResult {
  final DeviceVerificationStatus status;
  final String? message;
  final DateTime? verifiedAt;
  final String? deviceId;

  DeviceVerificationResult({
    required this.status,
    this.message,
    this.verifiedAt,
    this.deviceId,
  });

  factory DeviceVerificationResult.fromJson(Map<String, dynamic> json) {
    return DeviceVerificationResult(
      status: DeviceVerificationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DeviceVerificationStatus.unknown,
      ),
      message: json['message'],
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'])
          : null,
      deviceId: json['deviceId'],
    );
  }

  bool get isVerified => status == DeviceVerificationStatus.verified;
  bool get isPending => status == DeviceVerificationStatus.pendingVerification;
}

/// Service to handle device verification with email confirmation
class DeviceVerificationService {
  static final DeviceVerificationService _instance =
      DeviceVerificationService._();
  static DeviceVerificationService get instance => _instance;
  DeviceVerificationService._();

  final String _baseUrl =
      'https://immolink.ddns.net'; // Replace with your actual backend URL
  final DeviceFingerprintService _fingerprintService =
      DeviceFingerprintService.instance;

  DeviceVerificationResult? _cachedStatus;
  Timer? _statusPollTimer;

  static const String _storageKeyVerified = 'device_verified';
  static const String _storageKeyDeviceId = 'device_id';
  static const String _storageKeyVerifiedAt = 'device_verified_at';

  /// Register a new device and request email verification
  /// Returns the device verification result
  Future<DeviceVerificationResult> registerDevice({
    required String userId,
    required String authToken,
  }) async {
    try {
      debugPrint(
          '[DeviceVerification] Registering new device for user: $userId');

      final deviceId = await _fingerprintService.getDeviceFingerprint();
      final deviceInfo = await _fingerprintService.getDeviceInfo();
      final deviceName = await _fingerprintService.getDeviceName();

      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/device/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'userId': userId,
          'deviceId': deviceId,
          'deviceName': deviceName,
          'deviceInfo': deviceInfo,
        }),
      );

      debugPrint(
          '[DeviceVerification] Registration response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final result = DeviceVerificationResult.fromJson(data);

        _cachedStatus = result;
        await _saveVerificationStatus(result);

        // Start polling for verification if pending
        if (result.isPending) {
          startPollingVerificationStatus(
            userId: userId,
            authToken: authToken,
          );
        }

        return result;
      } else {
        debugPrint(
            '[DeviceVerification] Registration failed: ${response.body}');
        return DeviceVerificationResult(
          status: DeviceVerificationStatus.failed,
          message: 'Registration failed: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[DeviceVerification] Error registering device: $e');
      debugPrint('[DeviceVerification] Stack trace: $stackTrace');
      return DeviceVerificationResult(
        status: DeviceVerificationStatus.failed,
        message: 'Error: $e',
      );
    }
  }

  /// Check the current verification status of this device
  Future<DeviceVerificationResult> checkVerificationStatus({
    required String userId,
    required String authToken,
  }) async {
    try {
      final deviceId = await _fingerprintService.getDeviceFingerprint();

      final response = await http.get(
        Uri.parse(
            '$_baseUrl/api/auth/device/status?deviceId=$deviceId&userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      debugPrint(
          '[DeviceVerification] Status check response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = DeviceVerificationResult.fromJson(data);

        _cachedStatus = result;
        await _saveVerificationStatus(result);

        return result;
      } else {
        debugPrint(
            '[DeviceVerification] Status check failed: ${response.body}');
        return DeviceVerificationResult(
          status: DeviceVerificationStatus.unknown,
          message: 'Status check failed: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[DeviceVerification] Error checking status: $e');
      debugPrint('[DeviceVerification] Stack trace: $stackTrace');
      return DeviceVerificationResult(
        status: DeviceVerificationStatus.unknown,
        message: 'Error: $e',
      );
    }
  }

  /// Verify device using email token (usually called from deep link)
  Future<DeviceVerificationResult> verifyDevice({
    required String userId,
    required String verificationToken,
    required String authToken,
  }) async {
    try {
      final deviceId = await _fingerprintService.getDeviceFingerprint();

      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/device/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'userId': userId,
          'deviceId': deviceId,
          'verificationToken': verificationToken,
        }),
      );

      debugPrint(
          '[DeviceVerification] Verification response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = DeviceVerificationResult.fromJson(data);

        _cachedStatus = result;
        await _saveVerificationStatus(result);

        // Stop polling if verified
        if (result.isVerified) {
          stopPollingVerificationStatus();
        }

        return result;
      } else {
        debugPrint(
            '[DeviceVerification] Verification failed: ${response.body}');
        return DeviceVerificationResult(
          status: DeviceVerificationStatus.failed,
          message: 'Verification failed: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[DeviceVerification] Error verifying device: $e');
      debugPrint('[DeviceVerification] Stack trace: $stackTrace');
      return DeviceVerificationResult(
        status: DeviceVerificationStatus.failed,
        message: 'Error: $e',
      );
    }
  }

  /// Start polling for verification status (checks every 5 seconds)
  void startPollingVerificationStatus({
    required String userId,
    required String authToken,
    Duration interval = const Duration(seconds: 5),
  }) {
    stopPollingVerificationStatus(); // Stop any existing timer

    debugPrint('[DeviceVerification] Started polling verification status');

    _statusPollTimer = Timer.periodic(interval, (timer) async {
      final result = await checkVerificationStatus(
        userId: userId,
        authToken: authToken,
      );

      if (result.isVerified) {
        debugPrint('[DeviceVerification] Device verified! Stopping poll.');
        stopPollingVerificationStatus();
      }
    });
  }

  /// Stop polling for verification status
  void stopPollingVerificationStatus() {
    _statusPollTimer?.cancel();
    _statusPollTimer = null;
  }

  /// Get cached verification status (doesn't make network call)
  DeviceVerificationResult? getCachedStatus() {
    return _cachedStatus;
  }

  /// Load verification status from local storage
  Future<DeviceVerificationResult?> loadStoredStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final isVerified = prefs.getBool(_storageKeyVerified) ?? false;
      final deviceId = prefs.getString(_storageKeyDeviceId);
      final verifiedAtStr = prefs.getString(_storageKeyVerifiedAt);

      if (!isVerified || deviceId == null) {
        return null;
      }

      return DeviceVerificationResult(
        status: DeviceVerificationStatus.verified,
        deviceId: deviceId,
        verifiedAt:
            verifiedAtStr != null ? DateTime.parse(verifiedAtStr) : null,
      );
    } catch (e) {
      debugPrint('[DeviceVerification] Error loading stored status: $e');
      return null;
    }
  }

  /// Save verification status to local storage
  Future<void> _saveVerificationStatus(DeviceVerificationResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(_storageKeyVerified, result.isVerified);

      if (result.deviceId != null) {
        await prefs.setString(_storageKeyDeviceId, result.deviceId!);
      }

      if (result.verifiedAt != null) {
        await prefs.setString(
            _storageKeyVerifiedAt, result.verifiedAt!.toIso8601String());
      }
    } catch (e) {
      debugPrint('[DeviceVerification] Error saving status: $e');
    }
  }

  /// Clear verification status (for logout or testing)
  Future<void> clearVerificationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKeyVerified);
      await prefs.remove(_storageKeyDeviceId);
      await prefs.remove(_storageKeyVerifiedAt);

      _cachedStatus = null;
      stopPollingVerificationStatus();

      debugPrint('[DeviceVerification] Cleared verification status');
    } catch (e) {
      debugPrint('[DeviceVerification] Error clearing status: $e');
    }
  }

  /// Resend verification email
  Future<bool> resendVerificationEmail({
    required String userId,
    required String authToken,
  }) async {
    try {
      final deviceId = await _fingerprintService.getDeviceFingerprint();

      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/device/resend-verification'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'userId': userId,
          'deviceId': deviceId,
        }),
      );

      debugPrint(
          '[DeviceVerification] Resend verification response: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[DeviceVerification] Error resending verification email: $e');
      return false;
    }
  }
}
