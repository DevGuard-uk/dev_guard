# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [1.0.4] - 2026-06-26

### Security
- **`statusUrl` domain lock**: optional API override must use HTTPS on `devguard.uk` (or a subdomain). Off-domain URLs are rejected at init.
- **No secret leak**: Master Secret and HMAC headers are never sent to endpoints that fail domain validation.
- **Protected default endpoint**: production API URL is resolved from native-protected segments when available.

### Added
- `resolveStatusUrl()` helper and unit tests for allowed / rejected endpoints.

## [1.0.3] - 2026-06-25

### Added
- **Plugin runtime identity** on heartbeat metadata (`sdkRuntime`, `sdkVersion`, `hostPlatform`, `hostPlatformVersion`) via `sdk_identity.dart` and `HardwareService`.
- **`PluginCrashReporter`** — built into the SDK; fire-and-forget POST to `/api/v1/telemetry/plugin-crash` when diagnostic vault errors occur.
- Plugin crash telemetry API support for the DevGuard admin dashboard.

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
- **Native security hardening**: protocol and storage literals are protected at runtime; native policy gate blocks emulators and compromised devices when configured.
- Unit tests for decode helpers and policy gate behavior.

### Changed
- `RestChecker`, `DevGuardLogger`, cache/token services, and `PaymentWall` default copy use hardened literals instead of plaintext strings.
- Rebuilt Android `.so` and iOS `xcframework` with updated native exports.

### Documentation
- README security section updated for integrator-facing release guidance.

## [1.0.0] - 2026-06-13

Initial public release (see `deployment/dev_guard/` for the sanitized publish package).

### Added
- **Native Security (FFI)**: HMAC-SHA256 signing via compiled `devguard_core` binary.
- **REST Protocol**: `v1-gzip` secure telemetry tunnel.
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
