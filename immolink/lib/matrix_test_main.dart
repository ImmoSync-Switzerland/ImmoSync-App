import 'package:flutter/material.dart';
import 'features/debug/matrix_logs_viewer.dart';
import 'features/debug/matrix_test_standalone.dart';

void main() {
  runApp(const MatrixTestApp());
}

class MatrixTestApp extends StatelessWidget {
  const MatrixTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matrix Test App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MatrixTestHomePage(),
    );
  }
}

class MatrixTestHomePage extends StatelessWidget {
  const MatrixTestHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matrix Debug & Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Matrix Testing Tools',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use these tools to debug and test Matrix functionality directly.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Matrix Logs Viewer
            Card(
              child: ListTile(
                leading: const Icon(Icons.bug_report, color: Colors.blue),
                title: const Text('Matrix Debug Logs'),
                subtitle: const Text('View real-time Matrix client logs and diagnostics'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MatrixLogsViewer(),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Matrix Test Tool
            Card(
              child: ListTile(
                leading: const Icon(Icons.chat_bubble_outline, color: Colors.green),
                title: const Text('Matrix Test Tool'),
                subtitle: const Text('Test Matrix messaging functionality step-by-step'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MatrixTestStandalone(),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 20),
            
            Card(
              color: Colors.amber.withValues(alpha: 0.1),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Start with "Matrix Debug Logs" to monitor activity\n'
                      '2. Use "Matrix Test Tool" to test step-by-step\n'
                      '3. Check logs for detailed error messages\n'
                      '4. Test Matrix login, room creation, and messaging',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}