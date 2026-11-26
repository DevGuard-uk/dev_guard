import 'package:flutter/widgets.dart';
import 'src/dev_guard_instance.dart';
import 'src/models/guard_response.dart';
import 'src/services/diagnostic_batch_service.dart';
export 'src/dev_guard_instance.dart' show DevGuardInstance, FailSafe;
export 'src/models/license_status.dart';
export 'src/models/guard_response.dart';
export 'src/services/diagnostic_batch_service.dart' show DiagnosticBatchService, DiagnosticBatchResult;
export 'src/services/diagnostic_outbox.dart' show DiagnosticOutbox, DiagnosticRecord;
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
  /// [sdkKey] — preferred per-project ingest key (Portal → Project SDK key).
  /// Falls back to [secret] / deprecated [apiKey] (account Master Secret).
  /// [apiKey] — deprecated alias for [secret].
  static Future<void> init({
    required String projectId,
    String? secret,
    String? sdkKey,
    String? statusUrl,
    @Deprecated('Use `secret` or `sdkKey` instead.') String? apiKey,
    FailSafe failSafe = FailSafe.open,
  }) =>
      instance.init(
        projectId: projectId,
        secret: secret,
        sdkKey: sdkKey,
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

  /// Records a User Journey UI step for Portal/Console timelines.
  ///
  /// Never throws. Empty [screen] is ignored. Uploaded only when the plan
  /// enables `betaFeatures.userJourney`.
  static Future<void> setUserLog({
    required String screen,
    String? widget,
    String? className,
    String action = 'view',
    Map<String, dynamic>? extras,
  }) =>
      instance.setUserLog(
        screen: screen,
        widget: widget,
        className: className,
        action: action,
        extras: extras,
      );

  /// Exports local AES-256 encrypted vault diagnostic logs and uploads them to the DevGuard API.
  static Future<bool> uploadRawVault({String triggerSource = 'manual_request'}) =>
      instance.uploadRawVault(triggerSource: triggerSource);

  /// Flushes pending diagnostic outbox records to the server.
  static Future<DiagnosticBatchResult> flushDiagnosticBatch() =>
      instance.flushDiagnosticBatch();
}
