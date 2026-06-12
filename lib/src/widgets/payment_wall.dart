import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'contact_button.dart';

class PaymentWall extends StatefulWidget {
  final String? title;
  final String message;
  final String contactEmail;
  final String contactPhone;
  final String contactWhatsapp;
  final bool allowUnlock;
  final Future<bool> Function(String) onUnlock;

  const PaymentWall({
    super.key,
    this.title,
    required this.message,
    required this.contactEmail,
    required this.contactPhone,
    this.contactWhatsapp = '',
    required this.allowUnlock,
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
          _error = 'Invalid unlock key. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    Colors.red.shade900,
                    Colors.black,
                    Colors.black,
                    Colors.red.shade800.withValues(alpha: 0.5),
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
                color: Colors.red.withValues(alpha: 0.15),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
                                  color: Colors.red.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                                ),
                                child: const Icon(
                                  Icons.lock_person_rounded,
                                  size: 64,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              // Title
                              Text(
                                (widget.title?.toUpperCase() ?? "ACCESS RESTRICTED"),
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
                                  color: Colors.red.shade700,
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
                                    label: 'WhatsApp Support',
                                    icon: Icons.chat_bubble_outline_rounded,
                                    url: 'https://wa.me/${widget.contactWhatsapp.replaceAll(RegExp(r'[^0-9]'), '')}',
                                    color: const Color(0xFF25D366),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (widget.contactEmail.isNotEmpty) ...[
                                  ContactButton(
                                    label: 'Email Support',
                                    icon: Icons.alternate_email_rounded,
                                    url: 'mailto:${widget.contactEmail}',
                                    color: Colors.red.shade800,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (widget.contactPhone.isNotEmpty) ...[
                                  ContactButton(
                                    label: 'Call Support',
                                    icon: Icons.phone_rounded,
                                    url: 'tel:${widget.contactPhone.replaceAll(RegExp(r'[^\d+]'), '')}',
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (widget.allowUnlock) ...[
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => setState(() => _showUnlockField = true),
                                    child: Text(
                                      '🔑 Enter Unlock Key',
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
                                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    TextField(
                                      controller: _controller,
                                      style: const TextStyle(color: Colors.white),
                                      autofocus: true,
                                      decoration: InputDecoration(
                                        hintText: 'Enter License Key',
                                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                                        filled: true,
                                        fillColor: Colors.white.withValues(alpha: 0.05),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      ),
                                      onSubmitted: (_) => _handleUnlock(),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextButton(
                                            onPressed: _isLoading ? null : () => setState(() => _showUnlockField = false),
                                            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          flex: 2,
                                          child: ElevatedButton(
                                            onPressed: _isLoading ? null : _handleUnlock,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: Colors.black,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                            ),
                                            child: _isLoading
                                                ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                                  )
                                                : const Text('Unlock', style: TextStyle(fontWeight: FontWeight.bold)),
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

                    const SizedBox(height: 48),

                    // Powered By
                    InkWell(
                      onTap: () async {
                        final url = Uri.parse('https://antssolution.com/');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Column(
                        children: [
                          Text(
                            'Powered by',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ANTS SOLUTION',
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
