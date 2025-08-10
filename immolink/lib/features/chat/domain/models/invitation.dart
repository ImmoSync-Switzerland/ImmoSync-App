class Invitation {
  final String id;
  final String propertyId;
  final String landlordId;
  final String tenantId;
  final String message;
  final String status; // pending, accepted, declined
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;
  final String? propertyAddress;
  final double? propertyRent;
  final String? landlordName;
  final String? landlordEmail;
  final String? tenantName;
  final String? tenantEmail;

  Invitation({
    required this.id,
    required this.propertyId,
    required this.landlordId,
    required this.tenantId,
    required this.message,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.acceptedAt,
    this.declinedAt,
    this.propertyAddress,
    this.propertyRent,
    this.landlordName,
    this.landlordEmail,
    this.tenantName,
    this.tenantEmail,
  });

  factory Invitation.fromMap(Map<String, dynamic> map) {
    return Invitation(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
      propertyId: map['propertyId'] ?? '',
      landlordId: map['landlordId'] ?? '',
      tenantId: map['tenantId'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null 
          ? DateTime.parse(map['expiresAt'])
          : null,
      acceptedAt: map['acceptedAt'] != null 
          ? DateTime.parse(map['acceptedAt'])
          : null,
      declinedAt: map['declinedAt'] != null 
          ? DateTime.parse(map['declinedAt'])
          : null,
      propertyAddress: map['propertyAddress'],
      propertyRent: map['propertyRent']?.toDouble(),
      landlordName: map['landlordName'],
      landlordEmail: map['landlordEmail'],
      tenantName: map['tenantName'],
      tenantEmail: map['tenantEmail'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'landlordId': landlordId,
      'tenantId': tenantId,
      'message': message,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'declinedAt': declinedAt?.toIso8601String(),
      'propertyAddress': propertyAddress,
      'propertyRent': propertyRent,
      'landlordName': landlordName,
      'landlordEmail': landlordEmail,
      'tenantName': tenantName,
      'tenantEmail': tenantEmail,
    };
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  @override
  String toString() {
    return 'Invitation(id: $id, propertyAddress: $propertyAddress, status: $status)';
  }
}
