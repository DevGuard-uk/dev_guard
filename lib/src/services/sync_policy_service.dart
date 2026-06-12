import '../models/guard_response.dart';
import 'secure_storage_service.dart';

class SyncPolicyService {
  static const String _lastSyncKey = 'dev_guard_last_sync';

  DateTime? _lastLifecycleSync;

  Future<bool> shouldSync({
    required GuardResponse? cachedResponse,
    required bool forceLogs,
    String? trigger,
  }) async {
    if (forceLogs) return true;

    final lifecycleSync = cachedResponse?.lifecycleSync;

    if (trigger == 'foreground' ||
        trigger == 'background' ||
        trigger == 'appLaunch') {
      // Determine whether this lifecycle trigger is enabled BEFORE touching the
      // debounce timestamp. Otherwise a skipped trigger (e.g. background with
      // onBackground:false) would stamp the debounce window and suppress the
      // immediately-following foreground sync.
      bool enabled;
      if (lifecycleSync != null) {
        if (trigger == 'foreground') {
          enabled = lifecycleSync['onForeground'] == true;
        } else if (trigger == 'background') {
          enabled = lifecycleSync['onBackground'] == true;
        } else {
          enabled = lifecycleSync['onAppLaunch'] == true;
        }
      } else {
        // No server lifecycle policy: sync on foreground/appLaunch, not background.
        enabled = trigger != 'background';
      }

      if (!enabled) return false;

      final now = DateTime.now();
      if (_lastLifecycleSync != null &&
          now.difference(_lastLifecycleSync!).inMinutes < 1) {
        return false;
      }
      _lastLifecycleSync = now;
      return true;
    }

    if (trigger == 'heartbeat') {
      return _evaluateSyncPolicy(cachedResponse?.syncPolicy ?? 'immediate');
    }

    if (lifecycleSync != null) return true;

    return _evaluateSyncPolicy(cachedResponse?.syncPolicy ?? 'immediate');
  }

  Future<bool> _evaluateSyncPolicy(String policy) async {
    if (policy == 'immediate') return true;
    if (policy == 'onDemand') return false;

    final lastSyncStr = await SecureStorageService.read(_lastSyncKey);
    final lastSync = lastSyncStr != null ? int.tryParse(lastSyncStr) ?? 0 : 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (policy == 'daily') return now - lastSync > 86400000;
    if (policy == 'weekly') return now - lastSync > 604800000;
    return true;
  }

  Future<void> recordSuccessfulSync() async {
    await SecureStorageService.write(
      _lastSyncKey,
      DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }
}
