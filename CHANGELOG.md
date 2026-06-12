# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-06-08

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
- Lock screen unlock entry label: **Enter Unlock Key** (parity with React Native SDK).
