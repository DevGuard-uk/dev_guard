import 'package:flutter/widgets.dart';
import 'src/dev_guard_instance.dart';
import 'src/models/guard_response.dart';
export 'src/dev_guard_instance.dart' show DevGuardInstance, FailSafe;
export 'src/models/license_status.dart';
export 'src/models/guard_response.dart';
export 'src/services/plugin_crash_reporter.dart' show PluginCrashReporter;

/// Static convenience API — delegates to [DevGuardInstance.shared].
class DevGuard {
  static DevGuardInstance get instance => DevGuardInstance.shared;

  static GuardResponse? get currentResponse => instance.currentResponse;

  static Stream<GuardResponse?> get onStatusChanged => instance.onStatusChanged;

  /// Initializes DevGuard.
  ///
  /// [projectId] — your project's unique ID from the DevGuard portal.
  /// [secret] — your account **Master Secret** (Settings → Master Secret).
  ///   Portal/developer projects must pass this; admins whose project has no
  ///   secret configured may omit it.
  /// [failSafe] — offline-with-no-cache behavior ([FailSafe.open] default).
  /// [statusUrl] — optional DevGuard API endpoint. Must use HTTPS on
  /// devguard.uk (defaults to the production API).
  /// [apiKey] — deprecated alias for [secret].
  static Future<void> init({
    required String projectId,
    String? secret,
    String? statusUrl,
    @Deprecated('Use `secret` (Settings → Master Secret) instead.') String? apiKey,
    FailSafe failSafe = FailSafe.open,
  }) =>
      instance.init(
        projectId: projectId,
        secret: secret,
        statusUrl: statusUrl,
        // ignore: deprecated_member_use_from_same_package
        apiKey: apiKey,
        failSafe: failSafe,
      );

  static Widget wrap({required Widget child}) => instance.wrap(child: child);

  static Future<void> syncStatus({
    bool forceLogs = false,
    String? trigger,
  }) =>
      instance.syncStatus(forceLogs: forceLogs, trigger: trigger);

  static Future<void> setDeviceUser({
    String? username,
    String? email,
    String? phone,
    Map<String, dynamic>? customData,
  }) =>
      instance.setDeviceUser(
        username: username,
        email: email,
        phone: phone,
        customData: customData,
      );
}
