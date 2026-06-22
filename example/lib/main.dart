import 'package:dev_guard/dev_guard.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DevGuard.init(
    projectId: 'your_project_id',
    secret: 'YOUR_MASTER_SECRET',
    failSafe: FailSafe.open,
  );

  runApp(const DevGuardExampleApp());
}

class DevGuardExampleApp extends StatelessWidget {
  const DevGuardExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevGuard Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C47FF)),
        useMaterial3: true,
      ),
      home: DevGuardWrapper(
        child: const DevGuardWelcomeScreen(),
      ),
    );
  }
}

class DevGuardWelcomeScreen extends StatelessWidget {
  const DevGuardWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined, size: 72, color: Color(0xFF6C47FF)),
                const SizedBox(height: 24),
                const Text(
                  'DevGuard Secure',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Replace your_project_id and YOUR_MASTER_SECRET in main.dart with credentials from devguard.uk',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
