class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  this.deliveredAt,
  this.readAt,
  });
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      timestamp: map['timestamp'] != null 
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
  deliveredAt: map['deliveredAt'] != null ? DateTime.tryParse(map['deliveredAt']) : null,
  readAt: map['readAt'] != null ? DateTime.tryParse(map['readAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
  if (deliveredAt != null) 'deliveredAt': deliveredAt!.toIso8601String(),
  if (readAt != null) 'readAt': readAt!.toIso8601String(),
    };
  }
}

