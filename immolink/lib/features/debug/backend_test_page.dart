import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/chat/domain/services/chat_service.dart';
import 'package:immosync/core/config/db_config.dart';

/// Simple test page to verify backend connectivity
class BackendTestPage extends ConsumerStatefulWidget {
  const BackendTestPage({Key? key}) : super(key: key);

  @override
  ConsumerState<BackendTestPage> createState() => _BackendTestPageState();
}

class _BackendTestPageState extends ConsumerState<BackendTestPage> {
  final _log = <String>[];
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _log.add('[${DateTime.now().toIso8601String().substring(11, 19)}] $message');
    });
    print(message);
  }

  Future<void> _testBackendConnection() async {
    setState(() {
      _isLoading = true;
      _log.clear();
    });

    try {
      _addLog('=== Backend Connection Test ===');
      _addLog('API URL: ${DbConfig.apiUrl}');
      
      final chatService = ChatService();
      
      // Test 1: Fetch messages for a test conversation
      _addLog('\n--- Test 1: Fetch Messages ---');
      try {
        final messages = await chatService.getMessages('test-conversation-id');
        _addLog('✅ SUCCESS: Fetched ${messages.length} messages');
      } catch (e) {
        _addLog('❌ FAILED: $e');
      }
      
      // Test 2: Check configuration
      _addLog('\n--- Test 2: Configuration ---');
      _addLog('WS URL: ${DbConfig.wsUrl}');
      _addLog('DB Name: ${DbConfig.dbName}');
      
    } catch (e, stack) {
      _addLog('❌ Test failed: $e');
      _addLog('Stack: $stack');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Test'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _testBackendConnection,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Test Backend Connection'),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                itemCount: _log.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _log[index],
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
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
}
