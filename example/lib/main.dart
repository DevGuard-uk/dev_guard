import 'package:dev_guard/dev_guard.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DevGuard.init(
    projectId: 'your_project_id',
    secret: 'YOUR_MASTER_SECRET',
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
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'DevGuard Example',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                StreamBuilder(
                  stream: DevGuard.onStatusChanged,
                  builder: (context, snapshot) {
                    final status = DevGuard.currentResponse?.status;
                    return Text('Status: ${status?.name ?? 'pending'}');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
