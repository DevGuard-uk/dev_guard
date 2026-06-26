import '../ffi/devguard_ffi.dart';
import '../internal/_obf.dart';

/// Resolves the DevGuard status API URL.
///
/// When [statusUrl] is omitted, returns the obfuscated production endpoint
/// (native reconstruction when available). Custom values must be HTTPS and
/// hosted on [Obf.allowedApiHostSuffix] or a subdomain.
String resolveStatusUrl(String? statusUrl) {
  final trimmed = statusUrl?.trim();
  final candidate = (trimmed == null || trimmed.isEmpty)
      ? DevGuardFFI.defaultStatusUrl()
      : trimmed;

  if (!DevGuardFFI.isAllowedStatusUrl(candidate)) {
    throw ArgumentError(Obf.invalidStatusUrlLog);
  }

  return candidate;
}
