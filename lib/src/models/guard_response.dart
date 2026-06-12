import 'license_status.dart';

class GuardResponse {
  final LicenseStatus status;
  final String? title;
  final String message;
  final String contactEmail;
  final String contactPhone;
  final String contactWhatsapp;
  final bool allowUnlock;
  final Map<String, dynamic> betaFeatures;
  final Map<String, dynamic> extraData;

  // Advanced Controls
  final Map<String, dynamic>? lifecycleSync;
  final String? remoteCommand;
  final String? deviceToken;
  final bool deviceTracking;
  final int currentGeneration;
  final String? diagnosticPasscodeHash;

  /// Legacy heartbeat interval in minutes (used when [lifecycleSync] is absent).
  final int pingInterval;

  /// Sync throttle policy from the admin portal.
  final String syncPolicy;

  /// When true, emulators/simulators are blocked client-side.
  final bool blockEmulators;

  const GuardResponse({
    required this.status,
    this.title,
    this.message = '',
    this.contactEmail = '',
    this.contactPhone = '',
    this.contactWhatsapp = '',
    this.allowUnlock = false,
    this.betaFeatures = const {},
    this.extraData = const {},
    this.lifecycleSync,
    this.remoteCommand,
    this.deviceToken,
    this.deviceTracking = false,
    this.currentGeneration = 1,
    this.diagnosticPasscodeHash,
    this.pingInterval = 5,
    this.syncPolicy = 'immediate',
    this.blockEmulators = false,
  });

  factory GuardResponse.fromJson(Map<String, dynamic> json) {
    return GuardResponse(
      status: _parseStatus(json['status']),
      title: json['title'],
      message: json['message'] ?? '',
      contactEmail: json['contactEmail'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      contactWhatsapp: json['contactWhatsapp'] ?? '',
      allowUnlock: json['allowUnlock'] ?? false,
      betaFeatures: json['betaFeatures'] is Map
          ? Map<String, dynamic>.from(json['betaFeatures'])
          : {},
      extraData: json['extraData'] is Map
          ? Map<String, dynamic>.from(json['extraData'])
          : {},
      lifecycleSync: json['lifecycleSync'] != null
          ? Map<String, dynamic>.from(json['lifecycleSync'])
          : null,
      remoteCommand: json['remoteCommand'],
      deviceToken: json['deviceToken'],
      deviceTracking: json['deviceTracking'] ?? false,
      currentGeneration: json['currentGeneration'] ?? 1,
      diagnosticPasscodeHash: json['diagnosticPasscodeHash'],
      pingInterval: _parsePingInterval(json['pingInterval']),
      syncPolicy: (json['syncPolicy'] as String?) ?? 'immediate',
      blockEmulators: json['blockEmulators'] == true,
    );
  }

  static int _parsePingInterval(dynamic value) {
    if (value is int) return value > 0 ? value : 5;
    if (value is num) return value.toInt() > 0 ? value.toInt() : 5;
    return 5;
  }

  static LicenseStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return LicenseStatus.pending;
      case 'warning':
        return LicenseStatus.warning;
      case 'locked':
        return LicenseStatus.locked;
      case 'expired':
        return LicenseStatus.expired;
      case 'active':
      default:
        return LicenseStatus.active;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'title': title,
      'message': message,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'contactWhatsapp': contactWhatsapp,
      'allowUnlock': allowUnlock,
      'betaFeatures': betaFeatures,
      'extraData': extraData,
      'lifecycleSync': lifecycleSync,
      'remoteCommand': remoteCommand,
      'deviceToken': deviceToken,
      'deviceTracking': deviceTracking,
      'currentGeneration': currentGeneration,
      'diagnosticPasscodeHash': diagnosticPasscodeHash,
      'pingInterval': pingInterval,
      'syncPolicy': syncPolicy,
      'blockEmulators': blockEmulators,
    };
  }

  GuardResponse copyWith({
    LicenseStatus? status,
    String? title,
    String? message,
    Map<String, dynamic>? betaFeatures,
    Map<String, dynamic>? lifecycleSync,
    String? remoteCommand,
    String? deviceToken,
    int? pingInterval,
    String? syncPolicy,
    bool? blockEmulators,
  }) {
    return GuardResponse(
      status: status ?? this.status,
      title: title ?? this.title,
      message: message ?? this.message,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      contactWhatsapp: contactWhatsapp,
      allowUnlock: allowUnlock,
      betaFeatures: betaFeatures ?? this.betaFeatures,
      extraData: extraData,
      lifecycleSync: lifecycleSync ?? this.lifecycleSync,
      remoteCommand: remoteCommand ?? this.remoteCommand,
      deviceToken: deviceToken ?? this.deviceToken,
      deviceTracking: deviceTracking,
      currentGeneration: currentGeneration,
      diagnosticPasscodeHash: diagnosticPasscodeHash,
      pingInterval: pingInterval ?? this.pingInterval,
      syncPolicy: syncPolicy ?? this.syncPolicy,
      blockEmulators: blockEmulators ?? this.blockEmulators,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GuardResponse &&
        other.status == status &&
        other.title == title &&
        other.message == message &&
        other.contactEmail == contactEmail &&
        other.contactPhone == contactPhone &&
        other.contactWhatsapp == contactWhatsapp &&
        other.allowUnlock == allowUnlock &&
        _mapEquals(other.betaFeatures, betaFeatures) &&
        _mapEquals(other.extraData, extraData) &&
        _mapEquals(other.lifecycleSync ?? const {}, lifecycleSync ?? const {}) &&
        other.remoteCommand == remoteCommand &&
        other.deviceToken == deviceToken &&
        other.deviceTracking == deviceTracking &&
        other.currentGeneration == currentGeneration &&
        other.diagnosticPasscodeHash == diagnosticPasscodeHash &&
        other.pingInterval == pingInterval &&
        other.syncPolicy == syncPolicy &&
        other.blockEmulators == blockEmulators;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      title,
      message,
      contactEmail,
      contactPhone,
      contactWhatsapp,
      allowUnlock,
      betaFeatures.length,
      extraData.length,
      lifecycleSync?.length ?? 0,
      remoteCommand,
      deviceToken,
      deviceTracking,
      currentGeneration,
      diagnosticPasscodeHash,
      pingInterval,
      syncPolicy,
      blockEmulators,
    );
  }

  bool _mapEquals(Map a, Map b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}
