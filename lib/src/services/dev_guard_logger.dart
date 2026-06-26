import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_vault_logger/flutter_vault_logger.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../ffi/devguard_ffi.dart';
import '../internal/_obf.dart';
import 'plugin_crash_reporter.dart';

/// Internal logging service for DevGuard.
/// 
/// Uses [flutter_vault_logger] for Errors and Warnings, and a custom
/// encrypted Hive box for Info logs.
class DevGuardLogger {
  static final String _infoBoxName = Obf.infoBoxName;
  
  static bool _initialized = false;
  static bool showConsoleLogs = false; // Hidden until Authorized Diagnostic

  /// [deviceId] is used to derive per-device AES key material (not stored in source).
  static Future<void> init({required String deviceId}) async {
    if (_initialized) return;

    try {
      await Hive.initFlutter();
      DevGuardFFI.init();
      final vaultKey = _deriveVaultKey(deviceId);
      final vaultIV = _deriveVaultIV(deviceId);
      
      // 1. Initialize Error Vault (flutter_vault_logger)
      await CrashLogService.init(VaultLoggerConfig(
        encryptionKey: vaultKey,
        encryptionIV: vaultIV,
        maxLogCount: 1000,
        fileExtension: Obf.errExt,
      ));

      // 2. Initialize Info Vault (Custom Hive Box)
      if (!Hive.isAdapterRegistered(222)) {
        // CrashLogModel is used for Info logs too for consistency
        Hive.registerAdapter(CrashLogModelAdapter());
      }
      
      await Hive.openBox<CrashLogModel>(_infoBoxName);
      
      _initialized = true;
    } catch (e) {
      debugPrint('DevGuardLogger: Initialization failed: $e');
    }
  }

  static void enableConsoleLogs() {
    showConsoleLogs = true;
    debugPrint('${Obf.logTag} [DEBUG] Console logs enabled via Diagnostic Authorization.');
  }

  static void info(String message, {Map<String, dynamic>? data}) {
    _log(message, level: 'INFO', data: data);
  }

  static void warning(String message, {Map<String, dynamic>? data}) {
    _log(message, level: 'WARNING', data: data);
    // Also save to Error Vault
    CrashLogService.logError(
      message,
      context: 'WARNING',
      logStackTraceIfNull: true,
    );
  }

  static void error(dynamic error, {StackTrace? stackTrace, String? context}) {
    final message = error.toString();
    _log(message, level: 'ERROR', data: {'context': context});
    
    // Save to Error Vault
    CrashLogService.logError(
      error,
      stackTrace: stackTrace,
      context: context ?? 'ERROR',
    );

    unawaited(
      PluginCrashReporter.report(
        error: error,
        stackTrace: stackTrace,
        context: context,
        crashType: 'vault_error',
      ),
    );
  }

  static void debug(String message, {Map<String, dynamic>? data}) {
    _log(message, level: 'DEBUG', data: data);
  }

  static void _log(String message, {required String level, Map<String, dynamic>? data}) {
    final timestamp = DateTime.now();
    final formatted = '${Obf.logTag} [$level] $message ${data != null ? jsonEncode(data) : ""}';
    
    if (showConsoleLogs) {
      debugPrint(formatted);
    }

    if (!_initialized) return;

    try {
      if (level == 'INFO' || level == 'DEBUG') {
        final box = Hive.box<CrashLogModel>(_infoBoxName);
        final log = CrashLogModel(
          timestamp: timestamp,
          error: message,
          stackTrace: 'N/A',
          context: level,
          deviceInfo: '',
          appVersion: '',
        );

        if (box.length >= 1000) {
          box.deleteAt(0);
        }
        box.add(log);
      }
    } catch (e) {
      // Fail silently to avoid recursion or app crash
    }
  }

  static List<CrashLogModel> getErrorLogs() => CrashLogService.getLogs();
  
  static List<CrashLogModel> getInfoLogs() {
    if (!_initialized) return [];
    try {
      final box = Hive.box<CrashLogModel>(_infoBoxName);
      return box.values.toList().reversed.toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearErrors() async {
    await CrashLogService.clearLogs();
  }

  static Future<void> clearInfo() async {
    if (_initialized) {
      final box = Hive.box<CrashLogModel>(_infoBoxName);
      await box.clear();
    }
  }

  static Future<void> clearAll() async {
    await clearErrors();
    await clearInfo();
  }

  static Future<String> exportErrors() => CrashLogService.exportEncryptedLogs();
  
  static int getErrorCount() => CrashLogService.getLogs().length;

  static String _deriveVaultKey(String deviceId) {
    final hex = DevGuardFFI.deriveLogKeyHex(
      passcode: deviceId,
      salt: Obf.vaultKeySalt,
    );
    return String.fromCharCodes(_hexToBytes(hex));
  }

  static String _deriveVaultIV(String deviceId) {
    final hex = DevGuardFFI.deriveLogKeyHex(
      passcode: deviceId,
      salt: Obf.vaultIvSalt,
    );
    return String.fromCharCodes(_hexToBytes(hex).take(16));
  }

  static List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }
}
