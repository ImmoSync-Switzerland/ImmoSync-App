import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Service to generate unique device fingerprints for device verification
class DeviceFingerprintService {
  static final DeviceFingerprintService _instance =
      DeviceFingerprintService._();
  static DeviceFingerprintService get instance => _instance;
  DeviceFingerprintService._();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  String? _cachedFingerprint;
  Map<String, dynamic>? _cachedDeviceInfo;

  /// Get a unique fingerprint for this device
  Future<String> getDeviceFingerprint() async {
    if (_cachedFingerprint != null) {
      return _cachedFingerprint!;
    }

    final deviceInfo = await getDeviceInfo();

    // Create a string from device identifiers
    final identifiers = [
      deviceInfo['model'] ?? '',
      deviceInfo['brand'] ?? '',
      deviceInfo['deviceId'] ?? '',
      deviceInfo['platform'] ?? '',
    ].join('|');

    // Generate SHA-256 hash of identifiers
    final bytes = utf8.encode(identifiers);
    final digest = sha256.convert(bytes);
    _cachedFingerprint = digest.toString();

    return _cachedFingerprint!;
  }

  /// Get detailed device information
  Future<Map<String, dynamic>> getDeviceInfo() async {
    if (_cachedDeviceInfo != null) {
      return _cachedDeviceInfo!;
    }

    Map<String, dynamic> deviceData = {};

    try {
      if (kIsWeb) {
        // Web platform
        final webInfo = await _deviceInfo.webBrowserInfo;
        deviceData = {
          'platform': 'web',
          'browserName': webInfo.browserName.name,
          'userAgent': webInfo.userAgent ?? '',
          'vendor': webInfo.vendor ?? '',
          'model': '${webInfo.browserName.name} Browser',
          'brand': 'Web',
          'deviceId': webInfo.userAgent?.hashCode.toString() ?? 'unknown',
        };
      } else if (Platform.isAndroid) {
        // Android
        final androidInfo = await _deviceInfo.androidInfo;
        deviceData = {
          'platform': 'android',
          'model': androidInfo.model,
          'brand': androidInfo.brand,
          'manufacturer': androidInfo.manufacturer,
          'deviceId': androidInfo.id, // Android ID
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        // iOS
        final iosInfo = await _deviceInfo.iosInfo;
        deviceData = {
          'platform': 'ios',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'deviceId': iosInfo.identifierForVendor ?? 'unknown',
          'brand': 'Apple',
        };
      } else if (Platform.isWindows) {
        // Windows
        final windowsInfo = await _deviceInfo.windowsInfo;
        deviceData = {
          'platform': 'windows',
          'computerName': windowsInfo.computerName,
          'numberOfCores': windowsInfo.numberOfCores,
          'systemMemoryInMegabytes': windowsInfo.systemMemoryInMegabytes,
          'deviceId': windowsInfo.computerName.hashCode.toString(),
          'model': 'Windows PC',
          'brand': 'Windows',
        };
      } else if (Platform.isMacOS) {
        // macOS
        final macInfo = await _deviceInfo.macOsInfo;
        deviceData = {
          'platform': 'macos',
          'model': macInfo.model,
          'computerName': macInfo.computerName,
          'hostName': macInfo.hostName,
          'deviceId': macInfo.systemGUID ?? 'unknown',
          'brand': 'Apple',
        };
      } else if (Platform.isLinux) {
        // Linux
        final linuxInfo = await _deviceInfo.linuxInfo;
        deviceData = {
          'platform': 'linux',
          'name': linuxInfo.name,
          'version': linuxInfo.version,
          'id': linuxInfo.id,
          'deviceId': linuxInfo.machineId ?? 'unknown',
          'model': 'Linux PC',
          'brand': 'Linux',
        };
      }
    } catch (e) {
      debugPrint('[DeviceFingerprint] Error getting device info: $e');
      // Fallback device info
      deviceData = {
        'platform': Platform.operatingSystem,
        'model': 'Unknown',
        'brand': 'Unknown',
        'deviceId': 'unknown_${DateTime.now().millisecondsSinceEpoch}',
      };
    }

    _cachedDeviceInfo = deviceData;
    return deviceData;
  }

  /// Get a human-readable device name
  Future<String> getDeviceName() async {
    final info = await getDeviceInfo();
    final platform = info['platform'] ?? 'Unknown';
    final model = info['model'] ?? 'Unknown';
    final brand = info['brand'] ?? '';

    if (brand.isNotEmpty && brand != model) {
      return '$brand $model ($platform)';
    }
    return '$model ($platform)';
  }

  /// Clear cached data (useful for testing)
  void clearCache() {
    _cachedFingerprint = null;
    _cachedDeviceInfo = null;
  }
}
