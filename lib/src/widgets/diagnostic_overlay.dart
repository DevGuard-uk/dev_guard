import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ffi/devguard_ffi.dart';
import '../models/guard_response.dart';
import '../services/usage_logger.dart';
import '../services/dev_guard_logger.dart';
import 'package:flutter_vault_logger/flutter_vault_logger.dart';

class DiagnosticOverlay extends StatefulWidget {
  final String projectId;
  final GuardResponse response;
  final VoidCallback onClose;

  const DiagnosticOverlay({
    super.key,
    required this.projectId,
    required this.response,
    required this.onClose,
  });

  @override
  State<DiagnosticOverlay> createState() => _DiagnosticOverlayState();
}

class _DiagnosticOverlayState extends State<DiagnosticOverlay> {
  bool _isAuthorized = false;
  final TextEditingController _passcodeController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAuthorization();
  }

  @override
  void didUpdateWidget(DiagnosticOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.response.diagnosticPasscodeHash !=
        widget.response.diagnosticPasscodeHash) {
      _checkAuthorization();
    }
  }

  void _checkAuthorization() {
    DevGuardLogger.debug(
      'DevGuard: Checking Diagnostic Authorization. Hash: ${widget.response.diagnosticPasscodeHash}',
    );

    // 1. Check if public
    if (widget.response.diagnosticPasscodeHash == null ||
        widget.response.diagnosticPasscodeHash!.isEmpty) {
      _isAuthorized = false;
      return;
    }

    // 2. Check if already authorized in this session
    final sessionPasscode = UsageLogger.getSessionPasscode();
    if (sessionPasscode != null) {
      final sessionHash = DevGuardFFI.hashSha256Hex(sessionPasscode);
      if (sessionHash == widget.response.diagnosticPasscodeHash) {
        _isAuthorized = true;
        DevGuardLogger.enableConsoleLogs();
        return;
      }
    }

    _isAuthorized = false;
  }

  @override
  Widget build(BuildContext context) {
    // We use Material to provide theme and text styles since this might be outside the app's MaterialApp
    return Material(
      color: Colors.black.withValues(alpha: 0.8),
      child: Stack(
        children: [
          GestureDetector(
            onTap: widget.onClose,
            child: Container(color: Colors.transparent),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHandle(),
                      Flexible(
                        child: _isAuthorized
                            ? _buildContent()
                            : _buildPasscodeLock(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildPasscodeLock() {
    final bool isPasscodeSet = widget.response.diagnosticPasscodeHash != null &&
        widget.response.diagnosticPasscodeHash!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isPasscodeSet
                  ? Colors.amber.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPasscodeSet
                  ? Icons.lock_person_rounded
                  : Icons.warning_amber_rounded,
              size: 48,
              color: isPasscodeSet ? Colors.amber : Colors.red,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            isPasscodeSet
                ? 'Admin Approval Required'
                : 'Passcode Not Configured',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isPasscodeSet
                ? 'To view system logs, please enter the diagnostic passcode. If this device is not whitelisted, the bug icon will not appear.'
                : 'Please configure a Diagnostic Passcode in the DevGuard Admin Panel to enable this feature.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          if (isPasscodeSet) ...[
            TextField(
              controller: _passcodeController,
              obscureText: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 16,
              ),
              decoration: InputDecoration(
                hintText: '••••',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                if (val.length >= 4) {
                  _verifyPasscode();
                }
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Device ID: ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                FutureBuilder<String?>(
                  future: _getDeviceId(),
                  builder: (context, snapshot) {
                    return SelectableText(
                      snapshot.data ?? 'Loading...',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _getDeviceId() async {
    // We import this indirectly or use a simple hack to get it
    // For now, let's just use the projectId or a better way if available
    return widget.projectId;
  }

  void _verifyPasscode() {
    final inputHash = DevGuardFFI.hashSha256Hex(_passcodeController.text);
    if (inputHash == widget.response.diagnosticPasscodeHash) {
      UsageLogger.setSessionPasscode(_passcodeController.text);
      HapticFeedback.mediumImpact();
      DevGuardLogger.enableConsoleLogs();
      DevGuardLogger.info('DevGuard: Diagnostic Overlay authorized.');
      setState(() {
        _isAuthorized = true;
        _error = null;
      });
    } else {
      if (_passcodeController.text.length >= 6) {
        HapticFeedback.vibrate();
        DevGuardLogger.warning(
          'DevGuard: Failed diagnostic authorization attempt.',
        );
        setState(() {
          _error = 'Invalid Passcode';
        });
      }
    }
  }

  Widget _buildContent() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.all(20), child: _buildHeader()),
          const TabBar(
            tabs: [
              Tab(text: 'Usage'),
              Tab(text: 'Vault'),
            ],
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white38,
          ),
          Expanded(
            child: TabBarView(children: [_buildUsageTab(), _buildVaultTab()]),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionTitle('Project Info'),
        _buildInfoCard({
          'Project ID': widget.projectId,
          'Status': widget.response.status.name.toUpperCase(),
          'Ping Interval': widget.response.lifecycleSync != null ? '${widget.response.lifecycleSync!['fallbackIntervalHours']}h' : 'N/A',
          'Sync Policy': widget.response.lifecycleSync != null ? 'Lifecycle Sync' : 'Legacy',
          'Reg. Generation': 'GEN ${widget.response.currentGeneration}',
        }),
        const SizedBox(height: 24),
        _buildSectionTitle('Beta Features'),
        _buildBetaFeatures(),
        const SizedBox(height: 24),
        _buildSectionTitle('Recent Usage Logs'),
        _buildUsageLogs(),
        const SizedBox(height: 32),
        _buildCloseButton(),
      ],
    );
  }

  Widget _buildVaultTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildVaultActions(),
        const SizedBox(height: 24),
        _buildSectionTitle('Encrypted Error Vault (Last 1000)'),
        _buildVaultLogs(DevGuardLogger.getErrorLogs(), isError: true),
        const SizedBox(height: 24),
        _buildSectionTitle('Info Vault'),
        _buildVaultLogs(DevGuardLogger.getInfoLogs(), isError: false),
        const SizedBox(height: 32),
        _buildCloseButton(),
      ],
    );
  }

  Widget _buildVaultActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                final path = await DevGuardLogger.exportErrors();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logs exported to: $path')),
                  );
                }
              } catch (e) {
                DevGuardLogger.error(e, context: 'ExportLogs');
              }
            },
            icon: const Icon(Icons.file_download),
            label: const Text('Export'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.withValues(alpha: 0.2),
              foregroundColor: Colors.blue,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              await DevGuardLogger.clearAll();
              if (mounted) setState(() {});
            },
            icon: const Icon(Icons.delete_sweep),
            label: const Text('Clear'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha: 0.2),
              foregroundColor: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVaultLogs(List<CrashLogModel> logs, {required bool isError}) {
    if (logs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No vault logs.',
            style: TextStyle(color: Colors.white24),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logs.length > 50 ? 50 : logs.length,
        separatorBuilder: (_, _) =>
            const Divider(color: Colors.white10, height: 1),
        itemBuilder: (context, index) {
          final log = logs[index];
          return ListTile(
            dense: true,
            leading: Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              size: 16,
              color: isError ? Colors.redAccent : Colors.blueAccent,
            ),
            title: Text(
              log.error,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            subtitle: Text(
              '${log.timestamp} | ${log.context ?? ""}',
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCloseButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: widget.onClose,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: const BorderSide(color: Colors.white10),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Close Diagnostics'),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DevGuard Diagnostics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Authorized Developer Session',
              style: TextStyle(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () => HapticFeedback.lightImpact(),
          icon: const Icon(Icons.refresh, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoCard(Map<String, String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: items.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  e.key,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  e.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBetaFeatures() {
    if (widget.response.betaFeatures.isEmpty) {
      return const Text(
        'No beta features enabled.',
        style: TextStyle(color: Colors.white24),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.response.betaFeatures.entries.map((e) {
        final enabled = e.value == true;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: enabled
                ? Colors.blue.withValues(alpha: 0.2)
                : Colors.white10,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: enabled
                  ? Colors.blue.withValues(alpha: 0.4)
                  : Colors.white10,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                enabled ? Icons.check_circle : Icons.cancel,
                size: 14,
                color: enabled ? Colors.blue : Colors.white24,
              ),
              const SizedBox(width: 6),
              Text(
                e.key,
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.white38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUsageLogs() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: UsageLogger.getLogs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data!.reversed.toList();
        if (logs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'No logs recorded yet.',
                style: TextStyle(color: Colors.white24),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length > 20 ? 20 : logs.length,
            separatorBuilder: (_, _) =>
                const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, index) {
              final log = logs[index];
              final timestamp = DateTime.parse(log['timestamp']);
              final timeStr =
                  '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

              return ListTile(
                dense: true,
                title: Text(
                  log['type'] ?? 'unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  log['data']?.toString() ?? 'No extra data',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  timeStr,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
