import 'package:flutter/material.dart';
import '../chat/infrastructure/mobile_matrix_client.dart';

/// Standalone Matrix test page for debugging messaging issues
/// This bypasses the main chat system to test Matrix directly
class MatrixTestStandalone extends StatefulWidget {
  const MatrixTestStandalone({Key? key}) : super(key: key);

  @override
  State<MatrixTestStandalone> createState() => _MatrixTestStandaloneState();
}

class _MatrixTestStandaloneState extends State<MatrixTestStandalone> {
  final TextEditingController _homeserverController = TextEditingController(text: 'https://matrix.immosync.ch');
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();
  final TextEditingController _otherUserController = TextEditingController();
  
  bool _isLoading = false;
  String _status = 'Ready to test Matrix';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matrix Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            
            // Connection Settings
            Text('Connection Settings', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            TextField(
              controller: _homeserverController,
              decoration: const InputDecoration(
                labelText: 'Homeserver URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            
            // Connection Buttons
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testInit,
                  child: const Text('1. Init Client'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testLogin,
                  child: const Text('2. Login'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testDiagnostics,
                  child: const Text('3. Diagnostics'),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Room Operations
            Text('Room Operations', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            TextField(
              controller: _otherUserController,
              decoration: const InputDecoration(
                labelText: 'Other User MXID (e.g., @user:matrix.immosync.ch)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _roomIdController,
              decoration: const InputDecoration(
                labelText: 'Room ID (leave empty to create new)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testCreateRoom,
                  child: const Text('Create Room'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testListRooms,
                  child: const Text('List Rooms'),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Messaging
            Text('Messaging', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message to send',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testSendMessage,
              child: const Text('Send Message'),
            ),
            
            const SizedBox(height: 20),
            
            // Loading indicator
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  void _updateStatus(String status) {
    setState(() {
      _status = status;
    });
    MobileMatrixLogger.log('[Test] $status');
  }

  Future<void> _testInit() async {
    setState(() => _isLoading = true);
    try {
      _updateStatus('Initializing Matrix client...');
      await MobileMatrixClient.instance.init(
        _homeserverController.text.trim(),
        '/tmp'
      );
      _updateStatus('✅ Matrix client initialized successfully');
    } catch (e) {
      _updateStatus('❌ Init failed: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _testLogin() async {
    setState(() => _isLoading = true);
    try {
      _updateStatus('Logging in...');
      final result = await MobileMatrixClient.instance.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );
      _updateStatus('✅ Login successful: ${result['userId']}');
    } catch (e) {
      _updateStatus('❌ Login failed: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _testDiagnostics() async {
    setState(() => _isLoading = true);
    try {
      _updateStatus('Running diagnostics...');
      final diagnostics = MobileMatrixClient.instance.getDiagnostics();
      _updateStatus('✅ Diagnostics: ${diagnostics.toString()}');
    } catch (e) {
      _updateStatus('❌ Diagnostics failed: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _testCreateRoom() async {
    setState(() => _isLoading = true);
    try {
      final otherUser = _otherUserController.text.trim();
      if (otherUser.isEmpty) {
        _updateStatus('❌ Please enter other user MXID');
        setState(() => _isLoading = false);
        return;
      }
      
      _updateStatus('Creating room with $otherUser...');
      final roomId = await MobileMatrixClient.instance.createRoom(otherUser);
      _roomIdController.text = roomId;
      _updateStatus('✅ Room created: $roomId');
    } catch (e) {
      _updateStatus('❌ Room creation failed: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _testListRooms() async {
    setState(() => _isLoading = true);
    try {
      _updateStatus('Getting room diagnostics...');
      final diagnostics = MobileMatrixClient.instance.getDiagnostics();
      final roomCount = diagnostics['roomCount'] ?? 0;
      _updateStatus('✅ Found $roomCount rooms');
    } catch (e) {
      _updateStatus('❌ Room list failed: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _testSendMessage() async {
    setState(() => _isLoading = true);
    try {
      final roomId = _roomIdController.text.trim();
      final message = _messageController.text.trim();
      
      if (roomId.isEmpty || message.isEmpty) {
        _updateStatus('❌ Please enter room ID and message');
        setState(() => _isLoading = false);
        return;
      }
      
      _updateStatus('Sending message...');
      final eventId = await MobileMatrixClient.instance.sendMessage(roomId, message);
      _updateStatus('✅ Message sent: $eventId');
      _messageController.clear();
    } catch (e) {
      _updateStatus('❌ Send message failed: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _homeserverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _messageController.dispose();
    _roomIdController.dispose();
    _otherUserController.dispose();
    super.dispose();
  }
}