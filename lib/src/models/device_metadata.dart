class DeviceMetadata {
  final String deviceId;
  final String? deviceName;
  final String? model;
  final String? brand;
  final String? os;
  final String? appVersion;
  final bool isPhysicalDevice;
  final String? username;
  final String? email;
  final String? phone;
  final Map<String, dynamic>? customData;

  // Advanced Telemetry
  final String? battery;
  final String? batteryCharging;
  final String? batteryThermal;
  final String? ram;
  final String? storage;
  final String? networkType;
  final List<Map<String, dynamic>>? usageLogs;
  final List<Map<String, dynamic>>? vaultErrors;
  final List<Map<String, dynamic>>? vaultInfo;
  final String? deviceToken;
  final String? fingerprint;
  final String? location;
  final String? sdkRuntime;
  final String? sdkVersion;
  final String? hostPlatform;
  final String? hostPlatformVersion;

  const DeviceMetadata({
    required this.deviceId,
    this.deviceName,
    this.model,
    this.brand,
    this.os,
    this.appVersion,
    this.isPhysicalDevice = true,
    this.username,
    this.email,
    this.phone,
    this.customData,
    this.battery,
    this.batteryCharging,
    this.batteryThermal,
    this.ram,
    this.storage,
    this.networkType,
    this.usageLogs,
    this.vaultErrors,
    this.vaultInfo,
    this.deviceToken,
    this.fingerprint,
    this.location,
    this.sdkRuntime,
    this.sdkVersion,
    this.hostPlatform,
    this.hostPlatformVersion,
  });

  Map<String, dynamic> toQueryParameters() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'model': model,
      if (brand != null) 'brand': brand,
      'os': os,
      'version': appVersion,
      'isPhysicalDevice': isPhysicalDevice,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (customData != null) 'customData': customData,
      if (battery != null) 'battery': battery,
      if (batteryCharging != null) 'batteryCharging': batteryCharging,
      if (batteryThermal != null) 'batteryThermal': batteryThermal,
      if (ram != null) 'ram': ram,
      if (storage != null) 'storage': storage,
      if (networkType != null) 'networkType': networkType,
      if (usageLogs != null) 'usageLogs': usageLogs,
      if (vaultErrors != null) 'vaultErrors': vaultErrors,
      if (vaultInfo != null) 'vaultInfo': vaultInfo,
      if (deviceToken != null) 'deviceToken': deviceToken,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (location != null) 'location': location,
      if (sdkRuntime != null) 'sdkRuntime': sdkRuntime,
      if (sdkVersion != null) 'sdkVersion': sdkVersion,
      if (hostPlatform != null) 'hostPlatform': hostPlatform,
      if (hostPlatformVersion != null) 'hostPlatformVersion': hostPlatformVersion,
    };
  }
}
