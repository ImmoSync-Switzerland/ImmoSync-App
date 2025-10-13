import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../chat/infrastructure/http_chat_service.dart';

/// Simple test page to test HTTP chat functionality
class HttpChatTestPage extends ConsumerStatefulWidget {
  const HttpChatTestPage({super.key});

  @override
  ConsumerState<HttpChatTestPage> createState() => _HttpChatTestPageState();
}

class _HttpChatTestPageState extends ConsumerState<HttpChatTestPage> {
  final TextEditingController _messageController = TextEditingController();
  final HttpChatService _chatService = HttpChatService();
  final List<String> _logs = [];
  bool _isLoading = false;

  // Test IDs (replace with actual values)
  final String _conversationId = "67558b2368e19654c0e2b2b1"; // Replace with real conversation ID
  final String _senderId = "675225e1e7ce2c8141900399"; // Replace with real sender ID
  final String _receiverId = "675447c4592a86ba6e6e5971"; // Replace with real receiver ID

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now()}: $message');
    });
  }

  Future<void> _testSendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) {
      _addLog('❌ Message cannot be empty');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('📤 Sending message: "$content"');
      final messageId = await _chatService.sendMessage(
        conversationId: _conversationId,
        senderId: _senderId,
        receiverId: _receiverId,
        content: content,
      );

      _addLog('✅ Message sent successfully! ID: $messageId');
      _messageController.clear();
    } catch (e) {
      _addLog('❌ Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('📥 Getting messages...');
      final messages = await _chatService.getMessagesForConversation(_conversationId);
      _addLog('✅ Found ${messages.length} messages');
      
      for (final message in messages.take(3)) {
        _addLog('📜 ${message.senderId}: ${message.content}');
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('📋 Getting conversations...');
      final conversations = await _chatService.getConversationsForUser(_senderId);
      _addLog('✅ Found ${conversations.length} conversations');
      
      for (final conv in conversations.take(3)) {
        _addLog('💬 ${conv.id}: ${conv.lastMessage}');
      }
    } catch (e) {
      _addLog('❌ Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTTP Chat Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Test Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Test Configuration:', style: Theme.of(context).textTheme.titleMedium),
                    Text('Conversation ID: $_conversationId'),
                    Text('Sender ID: $_senderId'),
                    Text('Receiver ID: $_receiverId'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testGetConversations,
                    child: const Text('Get Conversations'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testGetMessages,
                    child: const Text('Get Messages'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Send Message
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a test message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testSendMessage,
                  child: _isLoading 
                    ? const SizedBox(
                        width: 16, 
                        height: 16, 
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Clear Logs Button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _logs.clear();
                });
              },
              child: const Text('Clear Logs'),
            ),
            
            const SizedBox(height: 16),
            
            // Logs
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _logs.isEmpty ? 'No logs yet. Try the buttons above!' : _logs.join('\n'),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}