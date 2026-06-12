import '../models/device_metadata.dart';
import '../models/guard_response.dart';
import '../models/license_status.dart';
import 'package:flutter/foundation.dart';

class GuardEnforcement {
  static GuardResponse apply(GuardResponse response, DeviceMetadata metadata) {
    if (response.blockEmulators && !metadata.isPhysicalDevice) {
      debugPrint('DevGuard: Emulator blocked by project policy.');
      return response.copyWith(
        status: LicenseStatus.locked,
        title: 'Emulator Detected',
        message:
            'This application cannot run on emulators or simulators for security reasons.',
      );
    }
    return response;
  }
}
