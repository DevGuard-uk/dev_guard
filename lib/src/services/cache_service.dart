import 'dart:convert';
import '../internal/_obf.dart';
import '../ffi/devguard_ffi.dart';
import '../models/guard_response.dart';
import 'secure_storage_service.dart';

class CacheService {
  static final String _key = Obf.cacheKey;
  final String? _projectId;

  CacheService({String? projectId}) : _projectId = projectId;

  String _encrypt(String plainText) {
    if (_projectId == null) return plainText;

    final key = utf8.encode(_projectId);
    final bytes = utf8.encode(plainText);
    final encrypted = DevGuardFFI.xorTransform(bytes, key);
    return base64Encode(encrypted);
  }

  String _decrypt(String encryptedText) {
    if (_projectId == null) return encryptedText;

    try {
      final bytes = base64Decode(encryptedText);
      final key = utf8.encode(_projectId);
      final decrypted = DevGuardFFI.xorTransform(bytes, key);
      return utf8.decode(decrypted);
    } catch (_) {
      return encryptedText;
    }
  }

  Future<void> saveResponse(GuardResponse response) async {
    final json = jsonEncode(response.toJson());
    await SecureStorageService.write(_key, _encrypt(json));
  }

  Future<GuardResponse?> getResponse() async {
    final data = await SecureStorageService.read(_key);
    if (data == null) return null;
    try {
      final decrypted = _decrypt(data);
      return GuardResponse.fromJson(jsonDecode(decrypted));
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    await SecureStorageService.delete(_key);
  }

  Future<int?> getLastWipeNonce() async {
    final val = await SecureStorageService.read(Obf.wipeNonceKey);
    return val != null ? int.tryParse(val) : null;
  }

  Future<void> setLastWipeNonce(int nonce) async {
    await SecureStorageService.write(
      Obf.wipeNonceKey,
      nonce.toString(),
    );
  }
}
