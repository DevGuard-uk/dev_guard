import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:ffi/ffi.dart';
import '../internal/_obf.dart';

typedef _GenerateSignatureC = Void Function(
  Pointer<Utf8> projectId,
  Int64 timestamp,
  Pointer<Utf8> output,
);
typedef _GenerateSignatureDart = void Function(
  Pointer<Utf8> projectId,
  int timestamp,
  Pointer<Utf8> output,
);

typedef _VerifyResponseC = Int32 Function(
  Pointer<Utf8> responseBody,
  Pointer<Utf8> signature,
);
typedef _VerifyResponseDart = int Function(
  Pointer<Utf8> responseBody,
  Pointer<Utf8> signature,
);

typedef _SecureTokenC = Void Function(Pointer<Utf8> input, Pointer<Utf8> output);
typedef _SecureTokenDart = void Function(Pointer<Utf8> input, Pointer<Utf8> output);

typedef _HashSha256C = Void Function(Pointer<Utf8> input, Pointer<Utf8> output);
typedef _HashSha256Dart = void Function(Pointer<Utf8> input, Pointer<Utf8> output);

typedef _XorTransformC = Void Function(
  Pointer<Utf8> input,
  IntPtr inputLen,
  Pointer<Utf8> key,
  IntPtr keyLen,
  Pointer<Utf8> output,
);
typedef _XorTransformDart = void Function(
  Pointer<Utf8> input,
  int inputLen,
  Pointer<Utf8> key,
  int keyLen,
  Pointer<Utf8> output,
);

typedef _DeriveLogKeyC = Void Function(
  Pointer<Utf8> passcode,
  Pointer<Utf8> salt,
  Pointer<Utf8> output,
);
typedef _DeriveLogKeyDart = void Function(
  Pointer<Utf8> passcode,
  Pointer<Utf8> salt,
  Pointer<Utf8> output,
);

typedef _GetTotalRamMbC = Int32 Function();
typedef _GetTotalRamMbDart = int Function();

typedef _EvaluatePolicyC = Int32 Function(Int32 blockEmulators, Int32 isPhysical, Int32 isCompromised);
typedef _EvaluatePolicyDart = int Function(int blockEmulators, int isPhysical, int isCompromised);

class DevGuardFFI {
  static DynamicLibrary? _lib;
  static _GenerateSignatureDart? _generateSignatureFunc;
  static _VerifyResponseDart? _verifyResponseFunc;
  static _SecureTokenDart? _secureSaveTokenFunc;
  static _SecureTokenDart? _secureGetTokenFunc;
  static _HashSha256Dart? _hashSha256Func;
  static _XorTransformDart? _xorTransformFunc;
  static _DeriveLogKeyDart? _deriveLogKeyFunc;
  static _GetTotalRamMbDart? _getTotalRamMbFunc;
  static _EvaluatePolicyDart? _evaluatePolicyFunc;

  static bool _initialized = false;
  static bool _nativeAvailable = false;

  /// Whether the compiled native black-box library is loaded.
  static bool get isNativeAvailable => _nativeAvailable;

  /// Supported mobile platforms for full security (HMAC signing).
  static bool get isSupportedPlatform =>
      Platform.isAndroid || Platform.isIOS;

  static void init() {
    if (_initialized) return;

    if (!isSupportedPlatform) {
      _initialized = true;
      _nativeAvailable = false;
      return;
    }

    try {
      if (Platform.isAndroid) {
        _lib = DynamicLibrary.open(Obf.nativeLib);
      } else if (Platform.isIOS || Platform.isMacOS) {
        _lib = DynamicLibrary.process();
      }

      _generateSignatureFunc = _lib!.lookupFunction<_GenerateSignatureC, _GenerateSignatureDart>(
        Obf.symX9,
      );
      _verifyResponseFunc = _lib!.lookupFunction<_VerifyResponseC, _VerifyResponseDart>(
        Obf.symV2,
      );
      _secureSaveTokenFunc = _lib!.lookupFunction<_SecureTokenC, _SecureTokenDart>(
        Obf.symS3,
      );
      _secureGetTokenFunc = _lib!.lookupFunction<_SecureTokenC, _SecureTokenDart>(
        Obf.symG4,
      );
      _hashSha256Func = _lib!.lookupFunction<_HashSha256C, _HashSha256Dart>(
        Obf.symH5,
      );
      _xorTransformFunc = _lib!.lookupFunction<_XorTransformC, _XorTransformDart>(
        Obf.symX6,
      );
      _deriveLogKeyFunc = _lib!.lookupFunction<_DeriveLogKeyC, _DeriveLogKeyDart>(
        Obf.symD7,
      );
      _getTotalRamMbFunc = _lib!.lookupFunction<_GetTotalRamMbC, _GetTotalRamMbDart>(
        Obf.symR8,
      );
      _evaluatePolicyFunc = _lib!.lookupFunction<_EvaluatePolicyC, _EvaluatePolicyDart>(
        Obf.symE1,
      );
      _nativeAvailable = true;
    } catch (_) {
      _nativeAvailable = false;
    }

    _initialized = true;
  }

  static String generateSignature(String projectId, int timestamp) {
    if (!_initialized) init();
    if (!_nativeAvailable) {
      throw UnsupportedError(
        'DevGuard native security is only available on Android and iOS. '
        'Run on a mobile device or emulator for full protection.',
      );
    }

    final ptrProjectId = projectId.toNativeUtf8();
    final ptrOutput = calloc<Int8>(65).cast<Utf8>();

    try {
      _generateSignatureFunc!(ptrProjectId, timestamp, ptrOutput);
      return ptrOutput.toDartString();
    } finally {
      calloc.free(ptrProjectId);
      calloc.free(ptrOutput);
    }
  }

  static bool verifyResponse(String responseBody, String signature) {
    if (!_initialized) init();
    if (!_nativeAvailable) return false;

    final ptrResponseBody = responseBody.toNativeUtf8();
    final ptrSignature = signature.toNativeUtf8();

    try {
      return _verifyResponseFunc!(ptrResponseBody, ptrSignature) == 1;
    } finally {
      calloc.free(ptrResponseBody);
      calloc.free(ptrSignature);
    }
  }

  static String secureSaveToken(String token) {
    if (!_initialized) init();
    if (!_nativeAvailable) return _dartTokenScramble(token);

    final ptrInput = token.toNativeUtf8();
    final ptrOutput = calloc<Int8>(token.length + 1).cast<Utf8>();

    try {
      _secureSaveTokenFunc!(ptrInput, ptrOutput);
      return ptrOutput.toDartString();
    } finally {
      calloc.free(ptrInput);
      calloc.free(ptrOutput);
    }
  }

  static String secureGetToken(String scrambled) {
    if (!_initialized) init();
    if (!_nativeAvailable) return _dartTokenScramble(scrambled);

    final ptrInput = scrambled.toNativeUtf8();
    final ptrOutput = calloc<Int8>(scrambled.length + 1).cast<Utf8>();

    try {
      _secureGetTokenFunc!(ptrInput, ptrOutput);
      return ptrOutput.toDartString();
    } finally {
      calloc.free(ptrInput);
      calloc.free(ptrOutput);
    }
  }

  static String hashSha256Hex(String input) {
    if (!_initialized) init();
    if (_nativeAvailable) {
      final ptrInput = input.toNativeUtf8();
      final ptrOutput = calloc<Int8>(65).cast<Utf8>();
      try {
        _hashSha256Func!(ptrInput, ptrOutput);
        return ptrOutput.toDartString();
      } finally {
        calloc.free(ptrInput);
        calloc.free(ptrOutput);
      }
    }
    return sha256.convert(utf8.encode(input)).toString();
  }

  static List<int> xorTransform(List<int> input, List<int> key) {
    if (key.isEmpty) return List<int>.from(input);

    if (_nativeAvailable) {
      final ptrInput = calloc<Uint8>(input.length);
      final ptrKey = calloc<Uint8>(key.length);
      final ptrOutput = calloc<Uint8>(input.length);
      try {
        for (var i = 0; i < input.length; i++) {
          ptrInput[i] = input[i];
        }
        for (var i = 0; i < key.length; i++) {
          ptrKey[i] = key[i];
        }
        _xorTransformFunc!(
          ptrInput.cast<Utf8>(),
          input.length,
          ptrKey.cast<Utf8>(),
          key.length,
          ptrOutput.cast<Utf8>(),
        );
        return List<int>.generate(input.length, (i) => ptrOutput[i]);
      } finally {
        calloc.free(ptrInput);
        calloc.free(ptrKey);
        calloc.free(ptrOutput);
      }
    }

    return List<int>.generate(
      input.length,
      (i) => input[i] ^ key[i % key.length],
    );
  }

  static String deriveLogKeyHex({String? passcode, String? salt}) {
    if (!_initialized) init();
    if (_nativeAvailable) {
      final ptrPasscode = (passcode ?? Obf.secureDefault).toNativeUtf8();
      final ptrSalt = (salt ?? Obf.saltDefault).toNativeUtf8();
      final ptrOutput = calloc<Int8>(65).cast<Utf8>();
      try {
        _deriveLogKeyFunc!(ptrPasscode, ptrSalt, ptrOutput);
        return ptrOutput.toDartString();
      } finally {
        calloc.free(ptrPasscode);
        calloc.free(ptrSalt);
        calloc.free(ptrOutput);
      }
    }
    final combined = '${passcode ?? Obf.secureDefault}_${salt ?? Obf.saltDefault}';
    return sha256.convert(utf8.encode(combined)).toString();
  }

  static int? getTotalRamMb() {
    if (!_initialized) init();
    if (!_nativeAvailable || _getTotalRamMbFunc == null) return null;
    final result = _getTotalRamMbFunc!();
    return result >= 0 ? result : null;
  }

  /// Returns [PolicyLock] code: allow, emulator, or compromised.
  static int evaluatePolicy({
    required bool blockEmulators,
    required bool isPhysicalDevice,
    required bool isCompromised,
  }) {
    if (!_initialized) init();
    final block = blockEmulators ? 1 : 0;
    final physical = isPhysicalDevice ? 1 : 0;
    final compromised = isCompromised ? 1 : 0;
    if (_nativeAvailable && _evaluatePolicyFunc != null) {
      return _evaluatePolicyFunc!(block, physical, compromised);
    }
    if (isCompromised) return PolicyLock.compromised;
    if (blockEmulators && !isPhysicalDevice) return PolicyLock.emulator;
    return PolicyLock.allow;
  }

  static String _dartTokenScramble(String input) {
    const mask = [0xF1, 0x3A, 0xC7, 0x82, 0x5E, 0xD9, 0x44, 0xAB];
    final bytes = utf8.encode(input);
    return utf8.decode(
      List<int>.generate(
        bytes.length,
        (i) => bytes[i] ^ mask[i % mask.length],
      ),
    );
  }
}
