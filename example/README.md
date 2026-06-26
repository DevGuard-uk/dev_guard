# DevGuard Example App

Minimal Flutter host app for the `dev_guard` plugin.

## Release builds

When shipping this example (or your production app), use Dart obfuscation:

```bash
flutter build apk --obfuscate --split-debug-info=./debug_info
flutter build ios --obfuscate --split-debug-info=./debug_info
```

See the plugin README **Security Best Practices** for host-app release hardening.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
