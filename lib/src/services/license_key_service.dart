import '../ffi/devguard_ffi.dart';

class LicenseKeyService {
  String hashKey(String key) => DevGuardFFI.hashSha256Hex(key);
}
