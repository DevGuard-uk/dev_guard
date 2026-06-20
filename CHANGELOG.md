# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [1.0.1] - 2026-06-20

### Added
- **SDK obfuscation layer**: Runtime XOR decode for protocol, storage, logger, and lock-screen literals.
- **Opaque native FFI exports** (`dg_x9` … `dg_e1`) and **policy gate** `DevGuardFFI.evaluatePolicy()` for emulator / compromised-device locks.
- **`tool/gen_obf.dart`**: regenerates encoded string table (maintainers).

### Changed
- `RestChecker`, `DevGuardLogger`, cache/token services, and `PaymentWall` default copy now use `Obf.*` instead of plaintext strings.
- Rebuilt Android `.so` and iOS `xcframework` with renamed exports.

### Documentation
- README: emulator blocking, two-layer obfuscation guidance, security best practices, and expanded feature descriptions.

## [1.0.0] - 2026-06-13

Initial public release.

### Added
- **Native Security (FFI)**: SHA256 signing via compiled binary.
- **REST Protocol**: Secure telemetry tunnel.
- **Glassmorphic Lock Screen**: WhatsApp / Email / Call support buttons and optional unlock-key entry.
- **Warning Banner**: Non-blocking in-app payment / license reminders.
- **Advanced Telemetry**: Optional battery, RAM, network, and storage collection.
- **Hardware Fingerprinting**, device tokens, remote wipe, fail-safe modes, diagnostic overlay.
- Customer-facing README with ACTIVE / WARNING / LOCKED screenshot gallery.
- Bundled example app with DevGuard Secure welcome UI and live status badge.

### Changed
- Lock screen unlock entry label: **Enter Unlock Key**.
- Updated direct dependencies to latest pub.dev releases: `android_id` ^0.5.1, `battery_plus` ^7.0.0, `connectivity_plus` ^7.1.1, `device_info_plus` ^13.1.0, `geolocator` ^14.0.3, `package_info_plus` ^10.1.0, `flutter_secure_storage` ^10.3.1, and `flutter_vault_logger` ^0.1.2.
- Documented host-app toolchain requirements in README (Flutter ≥ 3.41, Android Java 17 / AGP ≥ 8.12.1 / Gradle ≥ 8.13).
