import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Centralized secure storage for DevGuard keys.
class SecureStorageService {
  static const FlutterSecureStorage storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<void> write(String key, String value) =>
      storage.write(key: key, value: value);

  static Future<String?> read(String key) => storage.read(key: key);

  static Future<void> delete(String key) => storage.delete(key: key);

  static Future<void> deleteAllDeviceUserKeys() async {
    await delete('dev_guard_username');
    await delete('dev_guard_email');
    await delete('dev_guard_phone');
    await delete('dev_guard_custom_data');
  }
}
