import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/chat/presentation/providers/messages_provider.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';

/// Debug page for testing chat functionality
///
/// This page allows developers to:
/// - Test Matrix initialization
/// - Send test messages
/// - Verify backend storage
/// - Check timeline subscription
/// - Monitor sync status
class ChatDebugPage extends ConsumerStatefulWidget {
  const ChatDebugPage({super.key});

  @override
  ConsumerState<ChatDebugPage> createState() => _ChatDebugPageState();
}

class _ChatDebugPageState extends ConsumerState<ChatDebugPage> {
  final _conversationIdController =
      TextEditingController(text: 'test-conversation');
  final _messageController =
      TextEditingController(text: 'Test message from debug tool');
  final _receiverIdController = TextEditingController(text: 'receiver-test-id');

  final List<String> _logs = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _conversationIdController.dispose();
    _messageController.dispose();
    _receiverIdController.dispose();
    super.dispose();
  }

  void _log(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toIso8601String()}] $message');
    });
    debugPrint('[ChatDebug] $message');
  }

  Future<void> _testMatrixInit() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });
    _log('Starting Matrix initialization test...');

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        _log('ERROR: No current user found');
        setState(() => _isLoading = false);
        return;
      }

      _log('Current user ID: ${currentUser.id}');

      final chatService = ref.read(chatServiceProvider);
      _log('Calling ensureMatrixReady...');

      await chatService.ensureMatrixReady(userId: currentUser.id);
      _log('✅ Matrix initialization successful');
    } catch (e, stack) {
      _log('❌ Matrix initialization failed: $e');
      _log('Stack: ${stack.toString().split('\n').take(3).join('\n')}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testSendMessage() async {
    setState(() {
      _isLoading = true;
    });
    _log('Starting message send test...');

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        _log('ERROR: No current user found');
        setState(() => _isLoading = false);
        return;
      }

      final conversationId = _conversationIdController.text;
      final content = _messageController.text;
      final receiverId = _receiverIdController.text;

      _log('Conversation ID: $conversationId');
      _log('Sender ID: ${currentUser.id}');
      _log('Receiver ID: $receiverId');
      _log('Content: $content');

      final chatService = ref.read(chatServiceProvider);

      _log('Sending via Matrix...');
      final matrixEventId = await chatService.sendMessage(
        conversationId: conversationId,
        senderId: currentUser.id,
        receiverId: receiverId,
        content: content,
      );

      _log('✅ Message sent successfully');
      _log('Matrix Event ID: $matrixEventId');
    } catch (e, stack) {
      _log('❌ Message send failed: $e');
      _log('Stack: ${stack.toString().split('\n').take(3).join('\n')}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testFetchMessages() async {
    setState(() {
      _isLoading = true;
    });
    _log('Starting message fetch test...');

    try {
      final conversationId = _conversationIdController.text;
      _log('Fetching messages for: $conversationId');

      final chatService = ref.read(chatServiceProvider);
      final messages = await chatService.getMessages(conversationId);

      _log('✅ Fetched ${messages.length} messages');
      for (var i = 0; i < messages.length && i < 5; i++) {
        final msg = messages[i];
        _log(
            '  Message ${i + 1}: ${msg.content.substring(0, msg.content.length.clamp(0, 50))}...');
      }
    } catch (e, stack) {
      _log('❌ Message fetch failed: $e');
      _log('Stack: ${stack.toString().split('\n').take(3).join('\n')}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testRoomMapping() async {
    setState(() {
      _isLoading = true;
    });
    _log('Starting room mapping test...');

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        _log('ERROR: No current user found');
        setState(() => _isLoading = false);
        return;
      }

      final conversationId = _conversationIdController.text;
      final receiverId = _receiverIdController.text;

      _log('Getting Matrix room ID...');
      final chatService = ref.read(chatServiceProvider);
      final roomId = await chatService.getMatrixRoomIdForConversation(
        conversationId: conversationId,
        currentUserId: currentUser.id,
        otherUserId: receiverId,
      );

      if (roomId != null) {
        _log('✅ Room ID found: $roomId');
      } else {
        _log('⚠️ No room mapping found');
      }
    } catch (e, stack) {
      _log('❌ Room mapping test failed: $e');
      _log('Stack: ${stack.toString().split('\n').take(3).join('\n')}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testTimelineSubscription() async {
    setState(() {
      _isLoading = true;
    });
    _log('Starting timeline subscription test...');

    try {
      final conversationId = _conversationIdController.text;
      _log('Subscribing to timeline for: $conversationId');

      final messagesAsync =
          ref.read(conversationMessagesProvider(conversationId));

      messagesAsync.when(
        data: (messages) {
          _log('✅ Timeline active with ${messages.length} messages');
        },
        loading: () {
          _log('⏳ Timeline loading...');
        },
        error: (error, stack) {
          _log('❌ Timeline error: $error');
        },
      );
    } catch (e, stack) {
      _log('❌ Timeline subscription failed: $e');
      _log('Stack: ${stack.toString().split('\n').take(3).join('\n')}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Debug Tools'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // Input fields
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _conversationIdController,
                  decoration: const InputDecoration(
                    labelText: 'Conversation ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _receiverIdController,
                  decoration: const InputDecoration(
                    labelText: 'Receiver User ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Test Message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),

          // Test buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _testMatrixInit,
                icon: const Icon(Icons.power_settings_new),
                label: const Text('Test Matrix Init'),
              ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _testSendMessage,
                icon: const Icon(Icons.send),
                label: const Text('Send Test Message'),
              ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _testFetchMessages,
                icon: const Icon(Icons.download),
                label: const Text('Fetch Messages'),
              ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _testRoomMapping,
                icon: const Icon(Icons.room),
                label: const Text('Test Room Mapping'),
              ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _testTimelineSubscription,
                icon: const Icon(Icons.timeline),
                label: const Text('Test Timeline'),
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => _logs.clear()),
                icon: const Icon(Icons.clear),
                label: const Text('Clear Logs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
            ],
          ),

          const Divider(height: 32),

          // Log output
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        'Run tests to see logs here...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final color = log.contains('✅')
                            ? Colors.green
                            : log.contains('❌')
                                ? Colors.red
                                : log.contains('⚠️')
                                    ? Colors.orange
                                    : Colors.white;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            log,
                            style: TextStyle(
                              color: color,
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
