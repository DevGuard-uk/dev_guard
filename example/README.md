# DevGuard Flutter Example

Minimal example app for the DevGuard Flutter plugin.

## Release builds

When shipping this example (or your production app), use Dart obfuscation:

```bash
flutter build apk --obfuscate --split-debug-info=./debug_info
flutter build ios --obfuscate --split-debug-info=./debug_info
```

See the plugin README **Security Best Practices** for SDK and host-app hardening.
