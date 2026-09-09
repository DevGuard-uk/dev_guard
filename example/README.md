# DevGuard Example App

Minimal Flutter host app for the `dev_guard` plugin.

## Release builds

When shipping this example (or your production app), use Dart obfuscation:

```bash
flutter build apk --obfuscate --split-debug-info=./debug_info
flutter build ios --obfuscate --split-debug-info=./debug_info
```

See the plugin README **Security Best Practices** for host-app release hardening.

## iOS CocoaPods (root_jailbreak_guard)

`root_jailbreak_guard` ^1.1.1 depends on `IOSSecuritySuite` ~> 2.2.0. If `flutter build ios` / `pod install` fails with a lock conflict against `IOSSecuritySuite` 1.9.x:

```bash
rm -f ios/Podfile.lock
cd ios && pod install --repo-update
```

`ios/Podfile.lock` is gitignored; regenerate it locally after bumping that plugin.

## iOS physical device signing

`flutter run` on a real iPhone needs a valid `DEVELOPMENT_TEAM` in `ios/Runner.xcodeproj` (same Apple ID signed into Xcode on this Mac). A stale team ID fails with “Unable to log in with account …” / “No signing certificate … found”. Set the team in Xcode → Runner → Signing & Capabilities, or align `DEVELOPMENT_TEAM` with the development example.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
