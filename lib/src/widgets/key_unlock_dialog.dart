import 'package:flutter/material.dart';

class KeyUnlockDialog extends StatefulWidget {
  final Future<bool> Function(String) onUnlock;

  const KeyUnlockDialog({
    super.key,
    required this.onUnlock,
  });

  @override
  State<KeyUnlockDialog> createState() => _KeyUnlockDialogState();
}

class _KeyUnlockDialogState extends State<KeyUnlockDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter License Key'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'If you have received an unlock key, please enter it below to restore access.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'XXXX-XXXX-XXXX-XXXX',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            enabled: !_isLoading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () async {
            final nav = Navigator.of(context);
            setState(() {
              _isLoading = true;
              _error = null;
            });
            final success = await widget.onUnlock(_controller.text.trim());
            if (!mounted) return;
            if (success) {
              nav.pop();
            } else {
              setState(() {
                _isLoading = false;
                _error = 'Invalid unlock key. Please try again.';
              });
            }
          },
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Unlock'),
        ),
      ],
    );
  }
}
