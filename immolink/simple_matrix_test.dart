import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:path_provider/path_provider.dart';
import 'dart:async';

void main() {
  runApp(const MatrixTestApp());
}

class MatrixTestApp extends StatelessWidget {
  const MatrixTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matrix Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MatrixTestPage(),
    );
  }
}

class MatrixTestPage extends StatefulWidget {
  const MatrixTestPage({Key? key}) : super(key: key);

  @override
  State<MatrixTestPage> createState() => _MatrixTestPageState();
}

class _MatrixTestPageState extends State<MatrixTestPage> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  matrix.Client? _client;

  final TextEditingController _homeserverController =
      TextEditingController(text: 'https://matrix.immosync.ch');
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matrix Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Input fields
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _homeserverController,
                  decoration: const InputDecoration(
                    labelText: 'Homeserver URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testMatrix,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Test Matrix'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => setState(() => _logs.clear()),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Logs
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      _logs[index],
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now()}: $message');
    });

    // Auto scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _testMatrix() async {
    setState(() => _isLoading = true);

    try {
      _addLog('🚀 Starting Matrix test...');

      // Create client
      _addLog('📱 Creating Matrix client...');
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = '${appDir.path}/matrix_test.db';

      _client = matrix.Client(
        'MatrixTestApp',
        database: await matrix.MatrixSdkDatabase.init(dbPath),
      );

      _addLog('✅ Matrix client created');

      // Check homeserver
      _addLog('🌐 Checking homeserver...');
      await _client!.checkHomeserver(Uri.parse(_homeserverController.text));
      _addLog('✅ Homeserver check successful');

      // Login
      _addLog('🔑 Attempting login...');
      await _client!.login(
        matrix.LoginType.mLoginPassword,
        identifier: matrix.AuthenticationUserIdentifier(
          user: _usernameController.text,
        ),
        password: _passwordController.text,
      );

      _addLog('✅ Login successful!');
      _addLog('👤 User ID: ${_client!.userID}');

      // Wait for sync
      _addLog('🔄 Waiting for sync...');
      await _client!.roomsLoading;
      _addLog('✅ Sync completed');
      _addLog('🏠 Rooms available: ${_client!.rooms.length}');

      _addLog('🎉 Matrix test completed successfully!');
    } catch (e) {
      _addLog('❌ Error: $e');
    }

    setState(() => _isLoading = false);
  }
}
