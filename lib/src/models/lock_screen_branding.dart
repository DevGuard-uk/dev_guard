class LockScreenBranding {
  final String? brandName;
  final String? logoUrl;
  final String primaryColor;
  final String? accentColor;
  final String? websiteUrl;
  final bool hidePoweredBy;

  static const defaultPrimary = '#d32f2f';
  static const defaultAccent = '#b71c1c';

  const LockScreenBranding({
    this.brandName,
    this.logoUrl,
    this.primaryColor = defaultPrimary,
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
      primaryColor: (json['primaryColor'] as String?) ?? defaultPrimary,
      accentColor: json['accentColor'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      hidePoweredBy: json['hidePoweredBy'] == true,
    );
  }

  static String? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final normalized = hex.startsWith('#') ? hex.substring(1) : hex;
    if (normalized.length != 6) return null;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return null;
    return normalized;
  }

  int get primaryColorValue =>
      int.tryParse(
        'FF${_parseHexColor(primaryColor) ?? 'D32F2F'}',
        radix: 16,
      ) ??
      0xFFD32F2F;

  int get accentColorValue {
    final accent =
        _parseHexColor(accentColor) ?? _parseHexColor(primaryColor) ?? 'B71C1C';
    return int.tryParse('FF$accent', radix: 16) ?? 0xFFB71C1C;
  }
}

/// Resolved footer + palette for lock screens (RN `resolveBrandingFooter` parity).
class LockScreenBrandingFooter {
  final bool hasCustom;
  final String label;
  final String brand;
  final String url;
  final bool hidePoweredBy;
  final int primaryColorValue;
  final int accentColorValue;

  const LockScreenBrandingFooter({
    required this.hasCustom,
    required this.label,
    required this.brand,
    required this.url,
    required this.hidePoweredBy,
    required this.primaryColorValue,
    required this.accentColorValue,
  });
}

LockScreenBrandingFooter resolveBrandingFooter(LockScreenBranding? branding) {
  final hasCustom =
      branding != null &&
      ((branding.brandName?.trim().isNotEmpty ?? false) ||
          (branding.logoUrl?.trim().isNotEmpty ?? false));
  return LockScreenBrandingFooter(
    hasCustom: hasCustom,
    label: hasCustom ? 'Powered by' : 'Secured by',
    brand: hasCustom
        ? (branding.brandName?.trim().isNotEmpty == true
              ? branding.brandName!.trim()
              : 'DevGuard')
        : 'DevGuard',
    url: hasCustom && (branding.websiteUrl?.trim().isNotEmpty ?? false)
        ? branding.websiteUrl!.trim()
        : 'https://devguard.uk',
    hidePoweredBy: branding?.hidePoweredBy == true,
    primaryColorValue: branding?.primaryColorValue ?? 0xFFD32F2F,
    accentColorValue: branding?.accentColorValue ?? 0xFFB71C1C,
  );
}
