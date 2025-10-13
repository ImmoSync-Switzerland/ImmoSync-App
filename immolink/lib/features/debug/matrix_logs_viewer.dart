import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../chat/infrastructure/mobile_matrix_client.dart';

/// Debug page to view Matrix logs in real-time
/// This is useful for testing on physical devices where you can't see console logs
class MatrixLogsViewer extends StatefulWidget {
  const MatrixLogsViewer({Key? key}) : super(key: key);

  @override
  State<MatrixLogsViewer> createState() => _MatrixLogsViewerState();
}

class _MatrixLogsViewerState extends State<MatrixLogsViewer> {
  final ScrollController _scrollController = ScrollController();
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
    
    // Listen to new log entries
    MobileMatrixLogger.logStream.listen((logEntry) {
      if (mounted) {
        setState(() {
          _logs.add(logEntry);
        });
        
        // Auto-scroll to bottom
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
    });
  }

  void _loadLogs() {
    _logs = MobileMatrixLogger.getLogs();
  }

  void _clearLogs() {
    setState(() {
      MobileMatrixLogger.clearLogs();
      _logs.clear();
    });
  }

  void _copyLogsToClipboard() {
    final logsText = _logs.join('\n');
    Clipboard.setData(ClipboardData(text: logsText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard')),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matrix Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogsToClipboard,
            tooltip: 'Copy logs to clipboard',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearLogs,
            tooltip: 'Clear logs',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadLogs();
              });
            },
            tooltip: 'Refresh logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Matrix Client Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Ready: ${MobileMatrixClient.instance.isReady}'),
                Text('Current User: ${MobileMatrixClient.instance.currentUserId ?? 'Not logged in'}'),
                Text('Total Logs: ${_logs.length}'),
              ],
            ),
          ),
          
          // Logs list
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs yet.\nMatrix operations will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      final isError = log.toLowerCase().contains('error') || 
                                    log.toLowerCase().contains('failed');
                      final isSuccess = log.toLowerCase().contains('success') || 
                                      log.toLowerCase().contains('initialized');
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isError 
                              ? Colors.red.withOpacity(0.1)
                              : isSuccess 
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isError 
                                ? Colors.red.withOpacity(0.3)
                                : isSuccess 
                                    ? Colors.green.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: SelectableText(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: isError 
                                ? Colors.red.shade700
                                : isSuccess 
                                    ? Colors.green.shade700
                                    : Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      
      // Test buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  await MobileMatrixClient.instance.init(
                    'https://matrix.immosync.ch', 
                    '/tmp'
                  );
                } catch (e) {
                  MobileMatrixLogger.log('[Test] Init failed: $e');
                }
              },
              child: const Text('Test Init'),
            ),
            ElevatedButton(
              onPressed: () {
                MobileMatrixLogger.log('[Test] Test log entry at ${DateTime.now()}');
              },
              child: const Text('Add Test Log'),
            ),
          ],
        ),
      ),
    );
  }
}