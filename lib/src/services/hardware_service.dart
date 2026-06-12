import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:android_id/android_id.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../ffi/devguard_ffi.dart';
import '../models/device_metadata.dart';
import '../models/guard_response.dart';
import '../platform/hardware_channel.dart';
import 'dev_guard_logger.dart';
import 'device_token_service.dart';
import 'secure_storage_service.dart';
import 'usage_logger.dart';

class HardwareService {
  final GuardResponse? cachedResponse;

  HardwareService({this.cachedResponse});

  /// Resolves device ID without touching [DevGuardLogger] (safe before vault init).
  static Future<String> quickResolveDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      try {
        const androidIdPlugin = AndroidId();
        final androidId = await androidIdPlugin.getId();
        if (androidId != null && androidId.isNotEmpty) {
          return androidId;
        }
      } catch (_) {}
      return androidInfo.id;
    }
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios';
    }
    return 'unknown';
  }

  bool get _advancedTelemetry =>
      cachedResponse?.betaFeatures['advancedTelemetry'] == true;

  Future<DeviceMetadata> collect({bool forceLogs = false}) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();

    String deviceId = 'unknown';
    String? deviceName;
    String? model;
    String? brand;
    String? os;
    bool isPhysicalDevice = true;

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = await _resolveAndroidDeviceId(androidInfo);
      deviceName = androidInfo.host;
      model = androidInfo.model;
      brand = androidInfo.brand;
      os = 'Android ${androidInfo.version.release}';
      isPhysicalDevice = androidInfo.isPhysicalDevice;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? 'unknown_ios';
      deviceName = iosInfo.name;
      model = iosInfo.utsname.machine;
      brand = 'Apple';
      os = 'iOS ${iosInfo.systemVersion}';
      isPhysicalDevice = iosInfo.isPhysicalDevice;
    }

    final username = await SecureStorageService.read('dev_guard_username');
    final email = await SecureStorageService.read('dev_guard_email');
    final phone = await SecureStorageService.read('dev_guard_phone');

    final customDataString =
        await SecureStorageService.read('dev_guard_custom_data');
    final Map<String, dynamic>? customData = customDataString != null
        ? jsonDecode(customDataString) as Map<String, dynamic>
        : null;

    return DeviceMetadata(
      deviceId: deviceId,
      deviceName: deviceName,
      model: model,
      brand: brand,
      os: os,
      appVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
      isPhysicalDevice: isPhysicalDevice,
      username: username,
      email: email,
      phone: phone,
      customData: customData,
      battery: _advancedTelemetry ? await _getBatteryLevel() : null,
      batteryCharging: _advancedTelemetry ? await _getBatteryCharging() : null,
      batteryThermal: _advancedTelemetry ? await _getBatteryThermal() : null,
      networkType: _advancedTelemetry ? await _getNetworkType() : null,
      usageLogs: forceLogs ? await UsageLogger.getLogs() : null,
      vaultErrors: (forceLogs || DevGuardLogger.getErrorLogs().length > 20)
          ? DevGuardLogger.getErrorLogs().map((l) => l.toJson()).toList()
          : null,
      vaultInfo: forceLogs
          ? DevGuardLogger.getInfoLogs().map((l) => l.toJson()).toList()
          : null,
      deviceToken: await DeviceTokenService.getToken(),
      fingerprint: DeviceTokenService.generateFingerprint(
        deviceId: deviceId,
        model: model,
        os: os,
      ),
      storage: _advancedTelemetry ? await _getStorage() : null,
      ram: _advancedTelemetry ? await _getRAM() : null,
      location: _advancedTelemetry ? await _getLocationPassive() : null,
    );
  }

  Future<String> _resolveAndroidDeviceId(AndroidDeviceInfo androidInfo) async {
    try {
      const androidIdPlugin = AndroidId();
      final androidId = await androidIdPlugin.getId();
      if (androidId != null && androidId.isNotEmpty) {
        return androidId;
      }
    } catch (e, st) {
      DevGuardLogger.error(e, stackTrace: st, context: 'AndroidId');
    }
    return androidInfo.id;
  }

  Future<String?> _getRAM() async {
    if (Platform.isAndroid) {
      try {
        final result = await Process.run('cat', ['/proc/meminfo']);
        final lines = result.stdout.toString().split('\n');
        final memTotal = lines.firstWhere((l) => l.contains('MemTotal'));
        final totalKb =
            int.tryParse(memTotal.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return '${(totalKb / (1024 * 1024)).toStringAsFixed(1)} GB';
      } catch (_) {
        return null;
      }
    }

    if (Platform.isIOS) {
      final ramMb = DevGuardFFI.getTotalRamMb();
      if (ramMb != null) {
        return '${(ramMb / 1024).toStringAsFixed(1)} GB';
      }
    }
    return null;
  }

  Future<String?> _getStorage() async {
    if (Platform.isAndroid) {
      try {
        final result = await Process.run('df', ['-h', '/data']);
        final lines = result.stdout.toString().split('\n');
        if (lines.length > 1) {
          final parts = lines[1].split(RegExp(r'\s+'));
          if (parts.length > 1) {
            return '${parts[1]} Total';
          }
        }
      } catch (_) {}
    }

    if (Platform.isIOS) {
      return HardwareChannel.getIosStorageTotal();
    }
    return null;
  }

  Future<String?> _getBatteryLevel() async {
    try {
      final battery = Battery();
      final level = await battery.batteryLevel;
      return '$level%';
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getBatteryCharging() async {
    try {
      final battery = Battery();
      final state = await battery.batteryState;
      switch (state) {
        case BatteryState.charging:
          return 'charging';
        case BatteryState.full:
          return 'full';
        case BatteryState.discharging:
          return 'discharging';
        case BatteryState.connectedNotCharging:
          return 'connected_not_charging';
        case BatteryState.unknown:
          return 'unknown';
      }
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getBatteryThermal() async {
    // Thermal state requires platform APIs; report normalized placeholder.
    if (Platform.isIOS || Platform.isAndroid) {
      return 'NORMAL';
    }
    return null;
  }

  Future<String?> _getNetworkType() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.wifi)) return 'WiFi';
      if (connectivity.contains(ConnectivityResult.mobile)) return 'Mobile';
      if (connectivity.contains(ConnectivityResult.ethernet)) return 'Ethernet';
      return 'Other';
    } catch (_) {
      return null;
    }
  }

  /// Collects GPS only if permission is already granted — never prompts during sync.
  ///
  /// Uses [Geolocator.getLastKnownPosition] so sync does not wake the GPS radio.
  /// Expected platform failures (disabled services, simulators, denied permission)
  /// return null silently — they must not pollute the error vault.
  Future<String?> _getLocationPassive() async {
    if (!Platform.isAndroid && !Platform.isIOS) return null;

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        return null;
      }

      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;

      return '${position.latitude.toStringAsFixed(4)},'
          '${position.longitude.toStringAsFixed(4)}';
    } on PlatformException catch (e) {
      if (_isBenignLocationFailure(e)) return null;
      DevGuardLogger.debug(
        'Passive GPS unavailable',
        data: {'code': e.code},
      );
      return null;
    } catch (_) {
      return null;
    }
  }

  bool _isBenignLocationFailure(PlatformException e) {
    const benignCodes = {
      'SERVICE_STATUS_ERROR',
      'PERMISSION_DENIED',
      'PERMISSION_DEFINITIONS_NOT_FOUND',
      'LOCATION_SERVICES_DISABLED',
    };
    return benignCodes.contains(e.code);
  }
}
