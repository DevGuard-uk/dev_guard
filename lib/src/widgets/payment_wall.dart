import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../internal/_obf.dart';
import '../models/lock_screen_branding.dart';
import 'contact_button.dart';

class PaymentWall extends StatefulWidget {
  final String? title;
  final String message;
  final String contactEmail;
  final String contactPhone;
  final String contactWhatsapp;
  final bool allowUnlock;
  final LockScreenBranding? branding;
  final Future<bool> Function(String) onUnlock;

  const PaymentWall({
    super.key,
    this.title,
    required this.message,
    required this.contactEmail,
    required this.contactPhone,
    this.contactWhatsapp = '',
    required this.allowUnlock,
    this.branding,
    required this.onUnlock,
  });

  @override
  State<PaymentWall> createState() => _PaymentWallState();
}

class _PaymentWallState extends State<PaymentWall> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  bool _showUnlockField = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleUnlock() async {
    final key = _controller.text.trim();
    if (key.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await widget.onUnlock(key);

    if (mounted) {
      if (!success) {
        setState(() {
          _isLoading = false;
          _error = Obf.invalidUnlockKey;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = widget.branding;
    final primary = Color(branding?.primaryColorValue ?? 0xFFD32F2F);
    final accent = Color(branding?.accentColorValue ?? 0xFFB71C1C);
    final hasCustomBranding =
        branding != null &&
        (branding.brandName?.isNotEmpty == true ||
            branding.logoUrl?.isNotEmpty == true);
    final footerBrand = hasCustomBranding
        ? (branding.brandName?.trim().isNotEmpty == true
              ? branding.brandName!.trim()
              : Obf.brandDefault)
        : Obf.brandDefault;
    final footerUrl =
        hasCustomBranding && branding.websiteUrl?.isNotEmpty == true
        ? branding.websiteUrl!
        : Obf.brandWebsite;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Background Mesh/Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary.withValues(alpha: 0.85),
                      Colors.black,
                      Colors.black,
                      accent.withValues(alpha: 0.5),
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // Blur Circles
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.15),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 40,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Glassmorphic Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 450),
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icon
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: primary.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: branding?.logoUrl?.isNotEmpty == true
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            branding!.logoUrl!,
                                            width: 64,
                                            height: 64,
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (_, object, stackTrace) =>
                                                    const Icon(
                                                      Icons.lock_person_rounded,
                                                      size: 64,
                                                      color: Colors.white,
                                                    ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.lock_person_rounded,
                                          size: 64,
                                          color: Colors.white,
                                        ),
                                ),
                                const SizedBox(height: 32),

                                // Title
                                Text(
                                  (widget.title?.toUpperCase() ??
                                      Obf.accessRestricted),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Divider
                                Container(
                                  height: 2,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: primary,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Message
                                Text(
                                  widget.message,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 40),

                                if (!_showUnlockField) ...[
                                  // Contact Buttons
                                  if (widget.contactWhatsapp.isNotEmpty) ...[
                                    ContactButton(
                                      label: Obf.whatsappSupport,
                                      icon: Icons.chat_bubble_outline_rounded,
                                      url:
                                          '${Obf.waMeBase}${widget.contactWhatsapp.replaceAll(RegExp(r'[^0-9]'), '')}',
                                      color: const Color(0xFF25D366),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  if (widget.contactEmail.isNotEmpty) ...[
                                    ContactButton(
                                      label: Obf.emailSupport,
                                      icon: Icons.alternate_email_rounded,
                                      url: '${Obf.mailtoPrefix}${widget.contactEmail}',
                                      color: primary,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  if (widget.contactPhone.isNotEmpty) ...[
                                    ContactButton(
                                      label: Obf.callSupport,
                                      icon: Icons.phone_rounded,
                                      url:
                                          '${Obf.telPrefix}${widget.contactPhone.replaceAll(RegExp(r'[^\d+]'), '')}',
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  if (widget.allowUnlock) ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () => setState(
                                        () => _showUnlockField = true,
                                      ),
                                      child: Text(
                                        Obf.enterUnlockKey,
                                        style: TextStyle(
                                          color: Colors.amber.shade300,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ] else ...[
                                  // Unlock Field
                                  Column(
                                    children: [
                                      if (_error != null) ...[
                                        Text(
                                          _error!,
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 13,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      TextField(
                                        controller: _controller,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        autofocus: true,
                                        decoration: InputDecoration(
                                          hintText: Obf.licenseKeyHint,
                                          hintStyle: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white.withValues(
                                            alpha: 0.05,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 16,
                                              ),
                                        ),
                                        onSubmitted: (_) => _handleUnlock(),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextButton(
                                              onPressed: _isLoading
                                                  ? null
                                                  : () => setState(
                                                      () => _showUnlockField =
                                                          false,
                                                    ),
                                              child: Text(
                                                Obf.cancelLabel,
                                                style: const TextStyle(
                                                  color: Colors.white38,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            flex: 2,
                                            child: ElevatedButton(
                                              onPressed: _isLoading
                                                  ? null
                                                  : _handleUnlock,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.black,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),
                                              ),
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: Colors.black,
                                                          ),
                                                    )
                                                  : Text(
                                                      Obf.unlockLabel,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (!(branding?.hidePoweredBy == true)) ...[
                        const SizedBox(height: 48),
                        InkWell(
                          onTap: () async {
                            final url = Uri.parse(footerUrl);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          child: Column(
                            children: [
                              Text(
                                hasCustomBranding ? Obf.poweredBy : Obf.securedBy,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 11,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                footerBrand.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
