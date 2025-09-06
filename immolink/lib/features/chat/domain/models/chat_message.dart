class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String messageType; // 'text','image','file','other'
  final Map<String, dynamic>? metadata;
  final String? conversationId;
  final bool
      isEncrypted; // indicates message content/attachment encrypted end-to-end
  final Map<String, dynamic>?
      e2ee; // raw encrypted bundle (ciphertext, iv, tag) for history decryption

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.deliveredAt,
    this.readAt,
    this.messageType = 'text',
    this.metadata,
    this.conversationId,
    this.isEncrypted = false,
    this.e2ee,
  });
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      receiverId: map['receiverId']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: map['isRead'] == true,
      deliveredAt: map['deliveredAt'] != null
          ? DateTime.tryParse(map['deliveredAt'].toString())
          : null,
      readAt: map['readAt'] != null
          ? DateTime.tryParse(map['readAt'].toString())
          : null,
      messageType: map['messageType']?.toString() ??
          (map['metadata'] != null && map['metadata']['fileType'] == 'image'
              ? 'image'
              : 'text'),
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
      conversationId: map['conversationId']?.toString(),
      isEncrypted: map['isEncrypted'] == true || (map['e2ee'] != null),
      e2ee: map['e2ee'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(map['e2ee'])
          : null,
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
      'messageType': messageType,
      if (metadata != null) 'metadata': metadata,
      if (deliveredAt != null) 'deliveredAt': deliveredAt!.toIso8601String(),
      if (readAt != null) 'readAt': readAt!.toIso8601String(),
      if (conversationId != null) 'conversationId': conversationId,
      'isEncrypted': isEncrypted,
      if (e2ee != null) 'e2ee': e2ee,
    };
  }
}
