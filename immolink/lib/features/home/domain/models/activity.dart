class Activity {
  final String id;
  final String title;
  final String description;
  final String type; // 'payment', 'maintenance', 'message', 'property'
  final DateTime timestamp;
  final String? relatedId; // ID of related entity (property, payment, etc.)
  final Map<String, dynamic>? metadata;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
    this.relatedId,
    this.metadata,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      relatedId: json['relatedId'],
      metadata: json['metadata'],
    );
  }

  // Alias for compatibility
  factory Activity.fromMap(Map<String, dynamic> map) => Activity.fromJson(map);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'relatedId': relatedId,
      'metadata': metadata,
    };
  }

  // Alias for compatibility
  Map<String, dynamic> toMap() => toJson();

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
