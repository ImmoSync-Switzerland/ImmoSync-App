class SupportRequest {
  final String id;
  final String subject;
  final String message;
  final String category;
  final String priority;
  final String status;
  final List<SupportRequestNote> notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SupportRequest({
    required this.id,
    required this.subject,
    required this.message,
    required this.category,
    required this.priority,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportRequest.fromJson(Map<String, dynamic> json) => SupportRequest(
        id: json['id'] ?? json['_id'] ?? '',
        subject: json['subject'] ?? '',
        message: json['message'] ?? '',
        category: json['category'] ?? '',
        priority: json['priority'] ?? '',
        status: json['status'] ?? 'open',
        notes: (json['notes'] as List?)
                ?.map((n) => SupportRequestNote.fromJson(n as Map<String, dynamic>))
                .toList() ??
            const [],
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      );
}

class SupportRequestNote {
  final String body;
  final String? author; // user id
  final DateTime createdAt;
  SupportRequestNote({required this.body, required this.author, required this.createdAt});
  factory SupportRequestNote.fromJson(Map<String, dynamic> json) => SupportRequestNote(
        body: json['body'] ?? '',
        author: json['author']?.toString(),
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}