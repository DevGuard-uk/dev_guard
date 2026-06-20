import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../ffi/devguard_ffi.dart';
import '../internal/_obf.dart';
import '../models/device_metadata.dart';
import '../models/guard_response.dart';
import '../models/status_fetch_result.dart';
import 'dev_guard_logger.dart';
import 'status_checker.dart';

class RestChecker implements StatusChecker {
  final String baseUrl;
  final String? secret;

  RestChecker({required this.baseUrl, this.secret});

  Map<String, String> _authHeaders({
    required String signature,
    required int timestamp,
    bool includeTunnel = false,
  }) {
    final headers = <String, String>{
      Obf.contentType: Obf.appJson,
      Obf.hdrSig: signature,
      Obf.hdrTs: timestamp.toString(),
      Obf.hdrApiKey: secret ?? '',
    };
    if (includeTunnel) {
      headers[Obf.hdrTunnel] = Obf.tunnelV1;
    }
    return headers;
  }

  @override
  Future<StatusFetchResult> fetchStatus(
    String projectId, {
    DeviceMetadata? metadata,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final signature = DevGuardFFI.generateSignature(projectId, timestamp);

      final metadataMap = metadata?.toQueryParameters() ?? {};
      final metadataJson = jsonEncode(metadataMap);
      final compressed = gzip.encode(utf8.encode(metadataJson));
      final encodedPayload = base64Encode(compressed);

      final body = {
        Obf.projectId: projectId,
        Obf.deviceId: metadata?.deviceId,
        Obf.version: metadata?.appVersion,
        Obf.isPhysicalDevice: metadata?.isPhysicalDevice,
        Obf.location: metadata?.location,
        Obf.payloadField: encodedPayload,
      };

      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: _authHeaders(
              signature: signature,
              timestamp: timestamp,
              includeTunnel: true,
            ),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 50));

      if (response.statusCode == 200) {
        final serverSignature = response.headers[Obf.respSig];

        if (serverSignature == null) {
          DevGuardLogger.warning(Obf.missingSigLog);
          return const StatusFetchResult(
            failure: StatusFetchFailure.signatureMismatch,
          );
        }

        if (!DevGuardFFI.verifyResponse(response.body, serverSignature)) {
          final data = jsonDecode(response.body);
          if (data is Map &&
              data[Obf.betaFeatures] is Map &&
              data[Obf.betaFeatures][Obf.bypassSignature] == true) {
            DevGuardLogger.warning(Obf.invalidSigBypassLog);
          } else {
            DevGuardLogger.error(
              Obf.invalidSigLog,
              context: Obf.ctxRestSigVerify,
            );
            return const StatusFetchResult(
              failure: StatusFetchFailure.signatureMismatch,
            );
          }
        }

        final data = jsonDecode(response.body);
        return StatusFetchResult(
          response: GuardResponse.fromJson(
            Map<String, dynamic>.from(data as Map),
          ),
        );
      }

      DevGuardLogger.warning(
        'DevGuard Warning: Server returned status ${response.statusCode}. Body: ${response.body}',
      );
      return const StatusFetchResult(failure: StatusFetchFailure.networkError);
    } on TimeoutException {
      DevGuardLogger.warning('DevGuard Warning: Sync timed out after 50 seconds.');
      return const StatusFetchResult(failure: StatusFetchFailure.timeout);
    } catch (e, st) {
      DevGuardLogger.error(e, stackTrace: st, context: Obf.ctxRestFetchStatus);
      return const StatusFetchResult(failure: StatusFetchFailure.networkError);
    }
  }

  @override
  Future<bool> verifyAndUnlock(String projectId, String hashedKey) async {
    try {
      final uri = Uri.parse(baseUrl);
      final unlockSegment = Obf.unlock;
      final unlockUri = uri.replace(
        path: uri.path.endsWith('/')
            ? '${uri.path}$unlockSegment'
            : '${uri.path}/$unlockSegment',
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final signature = DevGuardFFI.generateSignature(projectId, timestamp);

      final response = await http.post(
        unlockUri,
        headers: _authHeaders(signature: signature, timestamp: timestamp),
        body: jsonEncode({
          Obf.projectId: projectId,
          Obf.providedKey: hashedKey,
        }),
      );

      if (response.statusCode == 200) {
        final serverSignature = response.headers[Obf.respSig];
        if (serverSignature == null ||
            !DevGuardFFI.verifyResponse(response.body, serverSignature)) {
          DevGuardLogger.error(
            Obf.unlockSigFailLog,
            context: Obf.ctxRestUnlockVerify,
          );
          return false;
        }
        return response.body == Obf.unlocked;
      }
      return false;
    } catch (e, st) {
      DevGuardLogger.error(e, stackTrace: st, context: Obf.ctxRestUnlock);
      return false;
    }
  }
}
