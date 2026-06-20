import '../ffi/devguard_ffi.dart';
import '../internal/_obf.dart';
import '../models/device_metadata.dart';
import '../models/guard_response.dart';
import '../models/license_status.dart';

class GuardEnforcement {
  static GuardResponse apply(GuardResponse response, DeviceMetadata metadata) {
    final code = DevGuardFFI.evaluatePolicy(
      blockEmulators: response.blockEmulators,
      isPhysicalDevice: metadata.isPhysicalDevice,
      isCompromised: false,
    );
    if (code == PolicyLock.emulator) {
      return response.copyWith(
        status: LicenseStatus.locked,
        title: Obf.emulatorTitle,
        message: Obf.emulatorMessage,
      );
    }
    return response;
  }
}
