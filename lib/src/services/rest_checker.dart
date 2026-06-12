import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../ffi/devguard_ffi.dart';
import '../models/device_metadata.dart';
import '../models/guard_response.dart';
import '../models/status_fetch_result.dart';
import 'dev_guard_logger.dart';
import 'status_checker.dart';

class RestChecker implements StatusChecker {
  final String baseUrl;

  /// The developer Master Secret, sent as the `X-DevGuard-API-Key` header
  /// so the server can authenticate requests against the account.
  final String? secret;

  RestChecker({required this.baseUrl, this.secret});

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
        'projectId': projectId,
        'deviceId': metadata?.deviceId,
        'version': metadata?.appVersion,
        'isPhysicalDevice': metadata?.isPhysicalDevice,
        'location': metadata?.location,
        'p': encodedPayload,
      };

      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-DevGuard-Signature': signature,
              'X-DevGuard-Timestamp': timestamp.toString(),
              'X-DevGuard-Tunnel': 'v1-gzip',
              'X-DevGuard-API-Key': secret ?? '',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 50));

      if (response.statusCode == 200) {
        final serverSignature =
            response.headers['x-devguard-response-signature'];

        if (serverSignature == null) {
          DevGuardLogger.warning(
            'DevGuard Security Alert: Missing server response signature.',
          );
          return const StatusFetchResult(
            failure: StatusFetchFailure.signatureMismatch,
          );
        }

        if (!DevGuardFFI.verifyResponse(response.body, serverSignature)) {
          final data = jsonDecode(response.body);
          if (data is Map &&
              data['betaFeatures'] is Map &&
              data['betaFeatures']['bypassSignature'] == true) {
            DevGuardLogger.warning(
              'DevGuard Security Warning: Invalid server response signature, but bypassSignature is ACTIVE.',
            );
          } else {
            DevGuardLogger.error(
              'DevGuard Security Alert: Invalid server response signature! Possible tampering detected.',
              context: 'RestSignatureVerify',
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
      DevGuardLogger.error(e, stackTrace: st, context: 'RestFetchStatus');
      return const StatusFetchResult(failure: StatusFetchFailure.networkError);
    }
  }

  @override
  Future<bool> verifyAndUnlock(String projectId, String hashedKey) async {
    try {
      final uri = Uri.parse(baseUrl);
      final unlockUri = uri.replace(
        path: uri.path.endsWith('/')
            ? '${uri.path}unlock'
            : '${uri.path}/unlock',
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final signature = DevGuardFFI.generateSignature(projectId, timestamp);

      final response = await http.post(
        unlockUri,
        headers: {
          'Content-Type': 'application/json',
          'X-DevGuard-Signature': signature,
          'X-DevGuard-Timestamp': timestamp.toString(),
          'X-DevGuard-API-Key': secret ?? '',
        },
        body: jsonEncode({'projectId': projectId, 'providedKey': hashedKey}),
      );

      if (response.statusCode == 200) {
        final serverSignature =
            response.headers['x-devguard-response-signature'];
        if (serverSignature == null ||
            !DevGuardFFI.verifyResponse(response.body, serverSignature)) {
          DevGuardLogger.error(
            'DevGuard Security Alert: Unlock response signature verification failed!',
            context: 'RestUnlockVerify',
          );
          return false;
        }
        return response.body == 'Unlocked';
      }
      return false;
    } catch (e, st) {
      DevGuardLogger.error(e, stackTrace: st, context: 'RestUnlock');
      return false;
    }
  }
}
