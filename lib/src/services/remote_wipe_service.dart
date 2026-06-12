import 'cache_service.dart';
import 'dev_guard_logger.dart';
import 'device_token_service.dart';
import 'secure_storage_service.dart';
import 'usage_logger.dart';

/// Executes a hardened remote wipe — clears all local security state.
class RemoteWipeService {
  final String projectId;

  RemoteWipeService({required this.projectId});

  /// Full security reset. Token is preserved unless [revokeToken] is true.
  Future<void> execute({bool revokeToken = false}) async {
    final cache = CacheService(projectId: projectId);
    await cache.clear();
    await UsageLogger.clearLogs();
    try {
      await DevGuardLogger.clearAll();
    } catch (_) {}
    await SecureStorageService.deleteAllDeviceUserKeys();

    if (revokeToken) {
      await DeviceTokenService.clearToken();
    }
  }
}
