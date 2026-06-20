class LockScreenBranding {
  final String? brandName;
  final String? logoUrl;
  final String primaryColor;
  final String? accentColor;
  final String? websiteUrl;
  final bool hidePoweredBy;

  const LockScreenBranding({
    this.brandName,
    this.logoUrl,
    this.primaryColor = '#2563eb',
    this.accentColor,
    this.websiteUrl,
    this.hidePoweredBy = false,
  });

  factory LockScreenBranding.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const LockScreenBranding();
    }
    return LockScreenBranding(
      brandName: json['brandName'] as String?,
      logoUrl: json['logoUrl'] as String?,
      primaryColor: (json['primaryColor'] as String?) ?? '#2563eb',
      accentColor: json['accentColor'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      hidePoweredBy: json['hidePoweredBy'] == true,
    );
  }

  static int? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final normalized = hex.startsWith('#') ? hex.substring(1) : hex;
    if (normalized.length != 6) return null;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return null;
    return 0xFF000000 | value;
  }

  int get primaryColorValue => _parseHexColor(primaryColor) ?? 0xFF2563EB;

  int get accentColorValue =>
      _parseHexColor(accentColor) ?? _parseHexColor(primaryColor) ?? 0xFF1D4ED8;
}
