# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [1.0.2] - 2026-06-22

### Added
- **`resolveBrandingFooter`**: shared helper for Enterprise white-label lock-screen footer copy and palette.

### Changed
- Default lock-screen palette when no branding colors are sent: `#d32f2f` / `#b71c1c`.
- Initial wrapper state is `ACTIVE` (no “Verifying license status…” flash before the first sync).
- Unlock key field uses obscured input.
- Brand website link shows a snackbar when the URL cannot be opened.

## [1.0.1] - 2026-06-20

### Added
- **Native security hardening** for protocol integrity and lock-screen protection.
- **Emulator and compromised-device blocking** via native policy checks.

### Changed
- Improved resilience of network communication and local storage handling.
- Updated native libraries for Android and iOS.

### Documentation
- README: emulator blocking, security best practices, and expanded feature descriptions.

## [1.0.0] - 2026-06-13

Initial public release.

### Added
- **Native Security**: SHA256 signing via compiled binary.
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
