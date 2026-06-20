// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() {
  const mask = [0xF1, 0x3A, 0xC7, 0x82, 0x5E, 0xD9, 0x44, 0xAB];
  String enc(String s) {
    final b = utf8.encode(s);
    final out = List.generate(
      b.length,
      (i) => b[i] ^ mask[i % mask.length],
    );
    return '[${out.join(', ')}]';
  }

  const strings = {
    'symX9': 'dg_x9',
    'symV2': 'dg_v2',
    'symS3': 'dg_s3',
    'symG4': 'dg_g4',
    'symH5': 'dg_h5',
    'symX6': 'dg_x6',
    'symD7': 'dg_d7',
    'symR8': 'dg_r8',
    'symE1': 'dg_e1',
    'nativeLib': 'libdevguard_core.so',
    'contentType': 'Content-Type',
    'appJson': 'application/json',
    'hdrSig': 'X-DevGuard-Signature',
    'hdrTs': 'X-DevGuard-Timestamp',
    'hdrTunnel': 'X-DevGuard-Tunnel',
    'hdrApiKey': 'X-DevGuard-API-Key',
    'respSig': 'x-devguard-response-signature',
    'tunnelV1': 'v1-gzip',
    'projectId': 'projectId',
    'deviceId': 'deviceId',
    'version': 'version',
    'isPhysicalDevice': 'isPhysicalDevice',
    'location': 'location',
    'payloadField': 'p',
    'unlock': 'unlock',
    'providedKey': 'providedKey',
    'unlocked': 'Unlocked',
    'defaultApiUrl': 'https://api.devguard.uk/devguard',
    'betaFeatures': 'betaFeatures',
    'bypassSignature': 'bypassSignature',
    'cacheKey': 'dev_guard_cache',
    'wipeNonceKey': 'dev_guard_last_wipe_nonce',
    'tokenKey': 'dev_guard_device_registration_token',
    'fingerprintKey': 'dev_guard_device_fingerprint',
    'usageLogsKey': 'dev_guard_usage_logs',
    'secureDefault': 'secure_default',
    'saltDefault': 'salt',
    'infoBoxName': 'dev_guard_info_logs',
    'vaultKeySalt': 'dg_vault_key_v1',
    'vaultIvSalt': 'dg_vault_iv_v1',
    'errExt': 'dgerr',
    'logTag': '[DevGuard]',
    'enclaveActivated': 'DevGuard: Secure Enclave Protocol Activated.',
    'compromisedLog': 'DevGuard Security Alert: Compromised device detected.',
    'missingSigLog': 'DevGuard Security Alert: Missing server response signature.',
    'invalidSigBypassLog':
        'DevGuard Security Warning: Invalid server response signature, but bypassSignature is ACTIVE.',
    'invalidSigLog':
        'DevGuard Security Alert: Invalid server response signature! Possible tampering detected.',
    'unlockSigFailLog':
        'DevGuard Security Alert: Unlock response signature verification failed!',
    'responseSigLockLog':
        'DevGuard Security Alert: Response signature mismatch — locking app.',
    'emulatorTitle': 'Emulator Detected',
    'emulatorMessage':
        'This application cannot run on emulators or simulators for security reasons.',
    'securityTitle': 'Security Alert',
    'compromisedMessage':
        'This application cannot run on jailbroken or rooted devices for security reasons.',
    'sigMismatchMessage':
        'This application cannot verify the server response. Access has been restricted for your protection.',
    'serverTamperMessage':
        'Server response verification failed. Possible tampering detected.',
    'ctxRestSigVerify': 'RestSignatureVerify',
    'ctxRestUnlockVerify': 'RestUnlockVerify',
    'ctxRestFetchStatus': 'RestFetchStatus',
    'ctxRestUnlock': 'RestUnlock',
    'ctxSecureEnclaveInit': 'SecureEnclaveInit',
    'ctxCriticalInit': 'CriticalInit',
    'ctxCacheLoad': 'CacheLoad',
    'ctxMetadataInit': 'MetadataInit',
    'ctxBackgroundInit': 'BackgroundInit',
    'ctxSyncStatus': 'syncStatus',
    'ctxSyncSig': 'syncStatus_signature',
    'brandDefault': 'DevGuard',
    'brandWebsite': 'https://devguard.uk',
    'accessRestricted': 'ACCESS RESTRICTED',
    'invalidUnlockKey': 'Invalid unlock key. Please try again.',
    'enterUnlockKey': 'Enter Unlock Key',
    'licenseKeyHint': 'Enter License Key',
    'cancelLabel': 'Cancel',
    'unlockLabel': 'Unlock',
    'poweredBy': 'Powered by',
    'securedBy': 'Secured by',
    'whatsappSupport': 'WhatsApp Support',
    'emailSupport': 'Email Support',
    'callSupport': 'Call Support',
    'mailtoPrefix': 'mailto:',
    'telPrefix': 'tel:',
    'waMeBase': 'https://wa.me/',
  };

  final buffer = StringBuffer('''
import 'dart:convert';

String _d(List<int> encoded) {
  const mask = [0xF1, 0x3A, 0xC7, 0x82, 0x5E, 0xD9, 0x44, 0xAB];
  return utf8.decode([
    for (var i = 0; i < encoded.length; i++)
      encoded[i] ^ mask[i % mask.length],
  ]);
}

/// Obfuscated protocol, storage, and native symbol literals.
abstract final class Obf {
''');

  for (final e in strings.entries) {
    buffer.writeln('  static String get ${e.key} => _d(${enc(e.value)});');
  }

  buffer.writeln('''
}

/// Native policy gate result codes (dg_e1).
abstract final class PolicyLock {
  static const int allow = 0;
  static const int emulator = 1;
  static const int compromised = 2;
}
''');

  File('lib/src/internal/_obf.dart').writeAsStringSync(buffer.toString());
  print('Wrote lib/src/internal/_obf.dart');
}
