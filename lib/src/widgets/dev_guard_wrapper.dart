import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../dev_guard_instance.dart';
import '../models/guard_response.dart';
import '../models/license_status.dart';
import '../services/license_key_service.dart';
import '../services/status_checker.dart';
import '../services/dev_guard_logger.dart';
import 'payment_wall.dart';
import 'pending_screen.dart';
import 'warning_banner.dart';
import 'diagnostic_overlay.dart';

class DevGuardWrapper extends StatefulWidget {
  final Widget child;
  final String projectId;
  final DevGuardInstance instance;
  final GuardResponse? initialResponse;
  final StatusChecker checker;
  final FailSafe failSafe;

  const DevGuardWrapper({
    super.key,
    required this.child,
    required this.projectId,
    required this.instance,
    required this.checker,
    this.initialResponse,
    this.failSafe = FailSafe.open,
  });

  @override
  State<DevGuardWrapper> createState() => _DevGuardWrapperState();
}

class _DevGuardWrapperState extends State<DevGuardWrapper>
    with WidgetsBindingObserver {
  late GuardResponse _response;
  StreamSubscription<GuardResponse?>? _statusSubscription;
  bool _showDiagnostics = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _response =
        widget.initialResponse ??
        GuardResponse(
          status: LicenseStatus.pending,
          message: 'Verifying license status...',
        );

    _statusSubscription = widget.instance.onStatusChanged.listen((response) {
      if (response != null && mounted) {
        _handleBetaFeatures(response);
        setState(() => _response = response);
      }
    });
  }

  Future<void> _handleBetaFeatures(GuardResponse response) async {
    if (response.status == LicenseStatus.warning &&
        response.betaFeatures['vibrateOnWarning'] == true) {
      HapticFeedback.vibrate();
    }

    final dynamic incomingWipeNonce = response.betaFeatures['wipeNonce'];
    if (incomingWipeNonce != null) {
      final int nonce = incomingWipeNonce is num
          ? incomingWipeNonce.toInt()
          : int.tryParse(incomingWipeNonce.toString()) ?? 0;
      if (nonce > 0) {
        await widget.instance.executeRemoteWipe(nonce: nonce);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.instance.setHeartbeatPaused(false);
      widget.instance.syncStatus(trigger: 'foreground');
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      widget.instance.setHeartbeatPaused(true);
      widget.instance.syncStatus(trigger: 'background');
    }
  }

  Future<bool> _handleUnlock(String key) async {
    final hashed = LicenseKeyService().hashKey(key);
    final success = await widget.checker.verifyAndUnlock(
      widget.projectId,
      hashed,
    );

    if (success) {
      await widget.instance.syncStatus();
    }
    return success;
  }

  bool get _isLocked =>
      _response.status == LicenseStatus.locked ||
      _response.status == LicenseStatus.expired;

  bool get _isPending => _response.status == LicenseStatus.pending;

  /// Hosts a full-screen security state (pending/locked/diagnostic) in its own
  /// self-contained [MaterialApp]. This never wraps the host app's widget tree —
  /// it replaces it — so the host's theme, localization, and routing are intact
  /// during normal operation.
  Widget _securityApp(Widget home, {MaterialColor? primarySwatch}) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: primarySwatch ?? Colors.blue,
      ),
      home: home,
    );
  }

  @override
  Widget build(BuildContext context) {
    DevGuardLogger.debug(
      'DevGuard: Wrapper Build. Status: ${_response.status}',
    );

    if (_isPending) {
      return _securityApp(PendingScreen(message: _response.message));
    }

    if (_isLocked) {
      return _securityApp(
        PaymentWall(
          title: _response.title != null && _response.title!.isNotEmpty
              ? _response.title
              : (_response.status == LicenseStatus.locked
                    ? 'Access Restricted'
                    : 'License Expired'),
          message: _response.message.isNotEmpty
              ? _response.message
              : (_response.status == LicenseStatus.locked
                    ? 'This application has been remotely locked by the developer.'
                    : 'The license for this application has expired.'),
          contactEmail: _response.contactEmail,
          contactPhone: _response.contactPhone,
          contactWhatsapp: _response.contactWhatsapp,
          allowUnlock: _response.allowUnlock,
          branding: _response.branding,
          onUnlock: _handleUnlock,
        ),
      );
    }

    // Active / warning: overlay on the host app (which provides its own
    // MaterialApp). No nested MaterialApp wraps the host child.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,

          if (_response.status == LicenseStatus.warning)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: WarningBanner(
                title: _response.title,
                message: _response.message,
              ),
            ),

          if (_response.betaFeatures['showDiagnosticLogs'] == true)
            Positioned(
              bottom: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Material(
                    type: MaterialType.transparency,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.amber.withValues(alpha: 0.8),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _showDiagnostics = true);
                      },
                      child: const Icon(Icons.bug_report, color: Colors.black87),
                    ),
                  ),
                ),
              ),
            ),

          if (_showDiagnostics)
            Positioned.fill(
              child: _securityApp(
                DiagnosticOverlay(
                  projectId: widget.projectId,
                  response: _response,
                  onClose: () => setState(() => _showDiagnostics = false),
                ),
                primarySwatch: Colors.amber,
              ),
            ),
        ],
      ),
    );
  }
}
