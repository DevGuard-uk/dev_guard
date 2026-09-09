import 'package:dev_guard/dev_guard.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const projectId = String.fromEnvironment(
    'DEVGUARD_PROJECT_ID',
    defaultValue: 'your_project_id',
  );
  const secret = String.fromEnvironment('DEVGUARD_SECRET', defaultValue: '');
  const statusUrl = String.fromEnvironment('DEVGUARD_STATUS_URL', defaultValue: '');

  await DevGuard.init(
    projectId: projectId,
    secret: secret.isEmpty ? null : secret,
    statusUrl: statusUrl.isEmpty ? null : statusUrl,
    failSafe: FailSafe.open,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DevGuard.wrap(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                const Text(
                  'DevGuard Example',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                StreamBuilder<GuardResponse?>(
                  stream: DevGuard.onStatusChanged,
                  initialData: DevGuard.currentResponse,
                  builder: (context, snapshot) {
                    final response = snapshot.data;
                    final extra = response?.extraData ?? {};

                    if (extra['showBetaBadge'] == true) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Text(
                          'BETA ACCESS ENABLED',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 1.1,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 16),
                StreamBuilder(
                  stream: DevGuard.onStatusChanged,
                  builder: (context, snapshot) {
                    final status = DevGuard.currentResponse?.status;
                    return Text('Status: ${status?.name ?? 'pending'}');
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await DevGuard.setDeviceUser(
                      username: 'example_user',
                      email: 'user@example.com',
                      phone: '+1234567890',
                      customData: {'plan': 'premium'},
                    );
                    await DevGuard.setUserLog(
                      screen: 'example-home',
                      widget: 'SetUserButton',
                      className: 'MyApp',
                      action: 'tap',
                    );
                    await DevGuard.setUserLog(
                      screen: 'example-home',
                      action: 'view',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User registered for portal tracking.')),
                      );
                    }
                  },
                  child: const Text('Set User'),
                ),
              ],
            ),
          ),
            );
          },
        ),
      ),
    );
  }
}
