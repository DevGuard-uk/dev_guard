import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/dev_guard_logger.dart';

class ContactButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String url;
  final Color color;

  const ContactButton({
    super.key,
    required this.label,
    required this.icon,
    required this.url,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            try {
              String launchUrlString = url.trim();

              // Check if it's an email without mailto:
              if (launchUrlString.contains('@') &&
                  !launchUrlString.startsWith('mailto:')) {
                launchUrlString = 'mailto:$launchUrlString';
              }
              // Check if it's a phone number without tel:
              else if (!launchUrlString.contains(':') &&
                  RegExp(r'^[0-9+\-\s\(\)]+$').hasMatch(launchUrlString)) {
                launchUrlString =
                    'tel:${launchUrlString.replaceAll(RegExp(r'[\s\-\(\)]'), '')}';
              }
              // Check if it's a web URL without http/https
              else if (!launchUrlString.contains('://') &&
                  (launchUrlString.startsWith('www.') ||
                      launchUrlString.contains('.'))) {
                launchUrlString = 'https://$launchUrlString';
              }

              final uri = Uri.parse(launchUrlString);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                DevGuardLogger.warning('Could not launch $launchUrlString');
              }
            } catch (e, st) {
              DevGuardLogger.error(e, stackTrace: st, context: 'ContactButtonLaunch');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
