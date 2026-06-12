import '../models/device_metadata.dart';
import '../models/status_fetch_result.dart';

abstract interface class StatusChecker {
  Future<StatusFetchResult> fetchStatus(
    String projectId, {
    DeviceMetadata? metadata,
  });

  Future<bool> verifyAndUnlock(String projectId, String hashedKey);
}
