class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.timestamp,
    required this.read,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        type: json['type'] as String? ?? 'general',
        data: (json['data'] as Map?)?.cast<String, dynamic>() ?? {},
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
        read: json['read'] as bool? ?? false,
      );
}
