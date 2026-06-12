import '../ffi/devguard_ffi.dart';
import 'secure_storage_service.dart';

/// Manages a persistent device registration token that survives
/// all standard wipe operations (cache clear, log clear, remote wipe).
/// Only a dedicated `revokeToken` remote command can remove it.
class DeviceTokenService {
  static const String _tokenKey = 'dev_guard_device_registration_token';
  static const String _fingerprintKey = 'dev_guard_device_fingerprint';
  
  /// Returns the locally stored registration token, or null if unregistered.
  static Future<String?> getToken() async {
    try {
      final scrambled = await SecureStorageService.read(_tokenKey);
      if (scrambled == null) return null;
      
      // Secondary protection: Descramble via native C++ library
      return DevGuardFFI.secureGetToken(scrambled);
    } catch (e) {
      return null;
    }
  }

  /// Persists a registration token received from the server.
  static Future<void> saveToken(String token, {bool useEnclave = false}) async {
    try {
      // Secondary protection: Scramble via native C++ library before storage
      final scrambled = DevGuardFFI.secureSaveToken(token);
      await SecureStorageService.write(_tokenKey, scrambled);
    } catch (_) {}
  }

  /// Removes the registration token. Only called on explicit admin revocation.
  static Future<void> clearToken() async {
    try {
      await SecureStorageService.delete(_tokenKey);
    } catch (_) {}
  }

  /// Generates a device fingerprint from hardware identifiers.
  /// This fingerprint persists even if the token is wiped, allowing
  /// the server to detect re-registrations from the same hardware.
  static String generateFingerprint({
    required String deviceId,
    required String? model,
    required String? os,
  }) {
    final raw = '$deviceId|${model ?? 'unknown'}|${os ?? 'unknown'}';
    return DevGuardFFI.hashSha256Hex(raw).substring(0, 16);
  }

  /// Stores the fingerprint locally for quick access.
  static Future<void> saveFingerprint(String fingerprint) async {
    try {
      await SecureStorageService.write(_fingerprintKey, fingerprint);
    } catch (_) {}
  }

  /// Returns the stored fingerprint.
  static Future<String?> getFingerprint() async {
    try {
      return await SecureStorageService.read(_fingerprintKey);
    } catch (_) {
      return null;
    }
  }
}
