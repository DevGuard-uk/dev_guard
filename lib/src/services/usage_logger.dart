import 'dart:convert';
import '../internal/_obf.dart';
import '../ffi/devguard_ffi.dart';
import '../models/guard_response.dart';
import 'dev_guard_logger.dart';
import 'secure_storage_service.dart';

class UsageLogger {
  static final String _key = Obf.usageLogsKey;
  static String? _sessionPasscode;
  static GuardResponse? Function()? _responseProvider;

  static void configure({GuardResponse? Function()? responseProvider}) {
    _responseProvider = responseProvider;
  }

  static GuardResponse? get _currentResponse => _responseProvider?.call();

  static String? getSessionPasscode() => _sessionPasscode;

  static void setSessionPasscode(String passcode) {
    _sessionPasscode = passcode;
  }

  static Future<void> logEvent(
    String eventType, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final logs = await getLogs(passcode: _sessionPasscode);

      logs.add({
        'type': eventType,
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      });

      if (logs.length > 100) {
        logs.removeRange(0, logs.length - 100);
      }

      final jsonStr = jsonEncode(logs);
      final encrypted = _crypt(jsonStr, passcode: _sessionPasscode);
      await SecureStorageService.write(_key, base64Encode(encrypted));
    } catch (e, st) {
      DevGuardLogger.error(e, stackTrace: st, context: 'UsageLogger');
    }
  }

  static List<int> _crypt(String text, {String? passcode}) {
    final response = _currentResponse;
    final effectivePasscode = passcode ?? _sessionPasscode;
    final keyHex = DevGuardFFI.deriveLogKeyHex(
      passcode: effectivePasscode ?? response?.diagnosticPasscodeHash,
      salt: response?.title ?? Obf.saltDefault,
    );
    return DevGuardFFI.xorTransform(utf8.encode(text), _hexToBytes(keyHex));
  }

  static List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  static Future<List<Map<String, dynamic>>> getLogs({String? passcode}) async {
    try {
      final base64Data = await SecureStorageService.read(_key);
      if (base64Data == null) return [];

      final encrypted = base64Decode(base64Data);
      final response = _currentResponse;
      final decrypted = DevGuardFFI.xorTransform(
        encrypted,
        _hexToBytes(
          DevGuardFFI.deriveLogKeyHex(
            passcode:
                passcode ?? _sessionPasscode ?? response?.diagnosticPasscodeHash,
            salt: response?.title ?? Obf.saltDefault,
          ),
        ),
      );
      final jsonStr = utf8.decode(decrypted);
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearLogs() async {
    try {
      await SecureStorageService.delete(_key);
    } catch (_) {}
  }
}
