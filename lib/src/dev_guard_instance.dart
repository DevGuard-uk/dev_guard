import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:root_jailbreak_guard/root_jailbreak_guard.dart';
import 'ffi/devguard_ffi.dart';
import 'models/guard_response.dart';
import 'models/license_status.dart';
import 'models/status_fetch_result.dart';
import 'services/cache_service.dart';
import 'services/dev_guard_logger.dart';
import 'services/hardware_service.dart';
import 'services/remote_wipe_service.dart';
import 'services/rest_checker.dart';
import 'services/secure_storage_service.dart';
import 'services/status_checker.dart';
import 'services/sync_policy_service.dart';
import 'services/usage_logger.dart';
import 'services/device_token_service.dart';
import 'services/guard_enforcement.dart';
import 'widgets/dev_guard_wrapper.dart';

/// Defines how the plugin behaves when offline with no cache.
enum FailSafe {
  open,
  closed,
}

/// Core DevGuard engine. Use [DevGuard] static methods or hold an instance directly.
class DevGuardInstance {
  static const String defaultStatusUrl = 'https://api.devguard.uk/devguard';

  static DevGuardInstance? _shared;
  static DevGuardInstance get shared => _shared ??= DevGuardInstance._();

  DevGuardInstance._();

  factory DevGuardInstance() => DevGuardInstance._();

  String? _projectId;
  GuardResponse? _cachedResponse;
  StatusChecker? _checker;
  FailSafe _failSafe = FailSafe.open;
  final StreamController<GuardResponse?> _statusController =
      StreamController<GuardResponse?>.broadcast();
  Timer? _heartbeatTimer;
  bool _heartbeatPaused = false;
  final SyncPolicyService _syncPolicy = SyncPolicyService();

  GuardResponse? get currentResponse => _cachedResponse;
  Stream<GuardResponse?> get onStatusChanged => _statusController.stream;
  String? get projectId => _projectId;
  StatusChecker? get checker => _checker;
  FailSafe get failSafe => _failSafe;
  bool get isInitialized => _projectId != null && _checker != null;

  set _currentResponse(GuardResponse? response) {
    if (_cachedResponse == response) return;
    _cachedResponse = response;
    _statusController.add(response);
  }

  /// Initializes DevGuard.
  ///
  /// [projectId] — your project's unique ID (from the DevGuard portal).
  /// [secret] — your account **Master Secret** (Settings → Master Secret).
  ///   Required for portal/developer projects so requests authenticate against
  ///   your account. Admins whose projects have no secret configured may omit it.
  /// [statusUrl] — override the API endpoint (defaults to the DevGuard API).
  /// [failSafe] — behavior when offline with no cache ([FailSafe.open] / [FailSafe.closed]).
  /// [apiKey] — deprecated alias for [secret].
  Future<void> init({
    required String projectId,
    String? secret,
    String? statusUrl,
    @Deprecated('Use `secret` (Settings → Master Secret) instead.') String? apiKey,
    FailSafe failSafe = FailSafe.open,
  }) async {
    try {
      _projectId = projectId;
      _failSafe = failSafe;

      final effectiveUrl = statusUrl ?? defaultStatusUrl;
      _checker = RestChecker(baseUrl: effectiveUrl, secret: secret ?? apiKey);

      UsageLogger.configure(responseProvider: () => _cachedResponse);

      if (_cachedResponse == null) {
        _currentResponse = GuardResponse(
          status: LicenseStatus.pending,
          message: 'Verifying license status...',
        );
      }

      Future.microtask(() => _backgroundInit(projectId));
    } catch (e, st) {
      DevGuardLogger.error(e, stackTrace: st, context: 'CriticalInit');
      if (_cachedResponse == null) {
        _currentResponse = GuardResponse(
          status: LicenseStatus.active,
          message: 'Security initialization failed. Running in fallback mode.',
        );
      }
    }
  }

  Future<void> _backgroundInit(String projectId) async {
    try {
      final deviceId = await HardwareService.quickResolveDeviceId();
      await DevGuardLogger.init(deviceId: deviceId);

      try {
        DevGuardFFI.init();
        DevGuardLogger.info('DevGuard: Secure Enclave Protocol Activated.');

        final isJailbroken = await RootJailbreakGuard.jailbroken;
        if (isJailbroken) {
          DevGuardLogger.warning(
            'DevGuard Security Alert: Compromised device detected.',
          );
          _currentResponse = GuardResponse(
            status: LicenseStatus.locked,
            title: 'Security Alert',
            message:
                'This application cannot run on jailbroken or rooted devices for security reasons.',
          );
          return;
        }
      } catch (e, st) {
        DevGuardLogger.error(e, stackTrace: st, context: 'SecureEnclaveInit');
      }

      final cache = CacheService(projectId: projectId);
      try {
        final cached = await cache.getResponse();
        if (cached != null) {
          _currentResponse = cached;
        } else if (_failSafe == FailSafe.closed) {
          _currentResponse = GuardResponse(
            status: LicenseStatus.pending,
            message: 'Connecting to security server...',
          );
        } else {
          _currentResponse = GuardResponse(
            status: LicenseStatus.active,
            message: '',
          );
        }
      } catch (e, st) {
        DevGuardLogger.error(e, stackTrace: st, context: 'CacheLoad');
      }

      try {
        final metadata = await HardwareService(
          cachedResponse: _cachedResponse,
        ).collect();
        DevGuardLogger.debug('DevGuard: Device ID: ${metadata.deviceId}');
      } catch (e, st) {
        DevGuardLogger.error(e, stackTrace: st, context: 'MetadataInit');
      }

      await UsageLogger.logEvent('app_open');
      await syncStatus(trigger: 'appLaunch');
      _startHeartbeat();
    } catch (e, st) {
      DevGuardLogger.error(e, stackTrace: st, context: 'BackgroundInit');
    }
  }

  Widget wrap({required Widget child}) {
    if (!isInitialized) {
      throw FlutterError(
        'DevGuard has not been initialized. Call DevGuard.init() before DevGuard.wrap().',
      );
    }

    return DevGuardWrapper(
      instance: this,
      projectId: _projectId!,
      initialResponse: _cachedResponse,
      checker: _checker!,
      failSafe: _failSafe,
      child: child,
    );
  }

  void setHeartbeatPaused(bool paused) {
    _heartbeatPaused = paused;
    if (paused) {
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
    } else if (_heartbeatTimer == null) {
      _startHeartbeat();
    }
  }

  void _startHeartbeat() {
    if (_heartbeatPaused) return;
    _heartbeatTimer?.cancel();

    int fallbackMinutes = 5;
    int jitterMinutes = 0;

    if (_cachedResponse?.lifecycleSync != null) {
      final syncMap = _cachedResponse!.lifecycleSync!;
      fallbackMinutes =
          (syncMap['fallbackIntervalHours'] as int? ?? 24) * 60;
      jitterMinutes = syncMap['jitterMaxMinutes'] as int? ?? 15;
    } else {
      fallbackMinutes = _cachedResponse?.pingInterval ?? 5;
    }

    final jitterOffset = jitterMinutes > 0
        ? (DateTime.now().millisecondsSinceEpoch % jitterMinutes)
        : 0;
    final interval = fallbackMinutes + jitterOffset;

    _heartbeatTimer = Timer.periodic(
      Duration(minutes: interval > 0 ? interval : 1),
      (_) async {
        if (!_heartbeatPaused) {
          await syncStatus(trigger: 'heartbeat');
        }
      },
    );
  }

  Future<void> syncStatus({
    bool forceLogs = false,
    String? trigger,
  }) async {
    try {
      if (!isInitialized) {
        DevGuardLogger.error(
          'Sync failed - Project ID or Checker missing.',
          context: 'syncStatus_init',
        );
        return;
      }

      DevGuardLogger.info(
        'DevGuard: Starting sync (forceLogs: $forceLogs, trigger: $trigger)...',
      );

      if (!forceLogs &&
          !await _syncPolicy.shouldSync(
            cachedResponse: _cachedResponse,
            forceLogs: forceLogs,
            trigger: trigger,
          )) {
        DevGuardLogger.debug('DevGuard: Sync skipped due to policy.');
        return;
      }

      final metadata = await HardwareService(
        cachedResponse: _cachedResponse,
      ).collect(forceLogs: forceLogs);

      final fetchResult = await _checker!
          .fetchStatus(_projectId!, metadata: metadata)
          .timeout(
            const Duration(seconds: 50),
            onTimeout: () => const StatusFetchResult(
              failure: StatusFetchFailure.timeout,
            ),
          );

      if (fetchResult.isSignatureMismatch) {
        DevGuardLogger.error(
          'DevGuard Security Alert: Response signature mismatch — locking app.',
          context: 'syncStatus_signature',
        );
        _currentResponse = GuardResponse(
          status: LicenseStatus.locked,
          title: 'Security Alert',
          message:
              'Server response verification failed. Possible tampering detected.',
        );
        return;
      }

      final freshResponse = fetchResult.response;
      if (freshResponse != null) {
        DevGuardLogger.info(
          'DevGuard: Fresh response received. Passcode: ${freshResponse.diagnosticPasscodeHash}',
        );

        await _handleRemoteCommand(freshResponse.remoteCommand);

        if (freshResponse.deviceToken != null) {
          await DeviceTokenService.saveToken(
            freshResponse.deviceToken!,
            useEnclave: freshResponse.betaFeatures['secureEnclave'] == true,
          );
          DevGuardLogger.info('DevGuard: Device registration token saved.');
        }

        final enforced = GuardEnforcement.apply(freshResponse, metadata);
        var intervalChanged = _heartbeatIntervalChanged(
          _cachedResponse,
          enforced,
        );

        _currentResponse = enforced;
        await CacheService(projectId: _projectId!).saveResponse(enforced);
        await _syncPolicy.recordSuccessfulSync();

        if (metadata.usageLogs != null && metadata.usageLogs!.isNotEmpty) {
          await UsageLogger.clearLogs();
        }
        if (metadata.vaultErrors != null && metadata.vaultErrors!.isNotEmpty) {
          await DevGuardLogger.clearErrors();
        }
        if (metadata.vaultInfo != null && metadata.vaultInfo!.isNotEmpty) {
          await DevGuardLogger.clearInfo();
        }

        if (intervalChanged) {
          _startHeartbeat();
        }
      } else {
        DevGuardLogger.warning(
          'DevGuard Warning: Server returned no valid response.',
        );
      }
    } catch (e, st) {
      DevGuardLogger.error(e, stackTrace: st, context: 'syncStatus');
    }
  }

  bool _heartbeatIntervalChanged(
    GuardResponse? oldResponse,
    GuardResponse newResponse,
  ) {
    if (oldResponse?.lifecycleSync != null &&
        newResponse.lifecycleSync != null) {
      final oldSync = oldResponse!.lifecycleSync!;
      final newSync = newResponse.lifecycleSync!;
      return oldSync['fallbackIntervalHours'] !=
              newSync['fallbackIntervalHours'] ||
          oldSync['jitterMaxMinutes'] != newSync['jitterMaxMinutes'];
    }
    return oldResponse?.pingInterval != newResponse.pingInterval;
  }

  Future<void> _handleRemoteCommand(String? command) async {
    if (command == null || command == 'none') return;

    DevGuardLogger.info('DevGuard: Executing remote command: $command');

    if (command == 'syncLogs') {
      await syncStatus(forceLogs: true);
    } else if (command == 'clearLogs') {
      await UsageLogger.clearLogs();
    } else if (command == 'wipeCache') {
      await CacheService(projectId: _projectId!).clear();
    } else if (command == 'revokeToken') {
      await DeviceTokenService.clearToken();
      debugPrint('DevGuard: Device registration token revoked by admin.');
    }
  }

  Future<void> setDeviceUser({
    String? username,
    String? email,
    String? phone,
    Map<String, dynamic>? customData,
  }) async {
    if (username != null) {
      await SecureStorageService.write('dev_guard_username', username);
    } else {
      await SecureStorageService.delete('dev_guard_username');
    }

    if (email != null) {
      await SecureStorageService.write('dev_guard_email', email);
    } else {
      await SecureStorageService.delete('dev_guard_email');
    }

    if (phone != null) {
      await SecureStorageService.write('dev_guard_phone', phone);
    } else {
      await SecureStorageService.delete('dev_guard_phone');
    }

    if (customData != null) {
      await SecureStorageService.write(
        'dev_guard_custom_data',
        jsonEncode(customData),
      );
    } else {
      await SecureStorageService.delete('dev_guard_custom_data');
    }

    if (username == null &&
        email == null &&
        phone == null &&
        customData == null) {
      return;
    }

    await syncStatus(forceLogs: true);
  }

  Future<void> executeRemoteWipe({required int nonce}) async {
    final cache = CacheService(projectId: _projectId!);
    final lastHandled = await cache.getLastWipeNonce();

    if (lastHandled != null && nonce <= lastHandled) return;

    await RemoteWipeService(projectId: _projectId!).execute();
    await cache.setLastWipeNonce(nonce);
    DevGuardLogger.warning(
      'DevGuard: Hardened Remote Wipe triggered (Nonce: $nonce).',
    );
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _statusController.close();
  }
}
