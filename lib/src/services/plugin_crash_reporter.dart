import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/sdk_identity.dart';
import '../ffi/devguard_ffi.dart';
import '../internal/_obf.dart';
import 'status_url_resolver.dart';

typedef PluginCrashMetadataProvider = Future<Map<String, dynamic>?> Function();

/// Fire-and-forget plugin crash telemetry to the DevGuard API.
class PluginCrashReporter {
  static String? _projectId;
  static String? _secret;
  static String _baseUrl = DevGuardFFI.defaultStatusUrl();
  static PluginCrashMetadataProvider? _metadataProvider;

  static void configure({
    required String projectId,
    String? secret,
    String? baseUrl,
    PluginCrashMetadataProvider? metadataProvider,
  }) {
    _projectId = projectId;
    _secret = secret;
    _baseUrl = resolveStatusUrl(baseUrl);
    _metadataProvider = metadataProvider;
  }

  static Future<void> report({
    required dynamic error,
    StackTrace? stackTrace,
    String? context,
    bool isFatal = false,
    String crashType = 'sdk_internal',
  }) async {
    final projectId = _projectId;
    if (projectId == null || projectId.isEmpty) return;

    try {
      final metadata = await _metadataProvider?.call() ?? {};
      final deviceId = metadata['deviceId']?.toString();
      if (deviceId == null || deviceId.isEmpty) return;
      if (!DevGuardFFI.isAllowedStatusUrl(_baseUrl)) return;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      DevGuardFFI.init();
      final signature = DevGuardFFI.generateSignature(projectId, timestamp);

      final body = {
        Obf.projectId: projectId,
        'deviceId': deviceId,
        'errorMessage': error.toString(),
        'stackTrace': stackTrace?.toString(),
        'errorName': error.runtimeType.toString(),
        'crashType': crashType,
        'isFatal': isFatal,
        'sdkRuntime': metadata['sdkRuntime'] ?? kSdkRuntime,
        'sdkVersion': metadata['sdkVersion'] ?? kSdkVersion,
        'hostPlatform': metadata['hostPlatform'],
        'hostPlatformVersion': metadata['hostPlatformVersion'],
        'appVersion': metadata['version'],
        'occurredAt': DateTime.now().toUtc().toIso8601String(),
        if (context != null) 'clientMeta': {'context': context},
      };

      final uri = Uri.parse(_telemetryUrl());
      await http
          .post(
            uri,
            headers: {
              Obf.contentType: Obf.appJson,
              if (DevGuardFFI.isAllowedStatusUrl(_baseUrl)) ...{
                Obf.hdrSig: signature,
                Obf.hdrTs: timestamp.toString(),
                if (_secret != null && _secret!.isNotEmpty) Obf.hdrApiKey: _secret!,
              },
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Never block app flows on crash telemetry.
    }
  }

  static String _telemetryUrl() {
    final base = _baseUrl.replaceAll(RegExp(r'/+$'), '');
    if (base.endsWith('/devguard')) {
      return base.replaceAll(RegExp(r'/devguard$'), '/api/v1/telemetry/plugin-crash');
    }
    return '$base/api/v1/telemetry/plugin-crash';
  }
}
