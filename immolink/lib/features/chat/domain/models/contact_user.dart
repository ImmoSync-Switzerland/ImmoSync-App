class ContactUser {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String phone;
  final List<String> properties;
  final String? status; // For tenant status: 'active' or 'available'
  final String? profileImage; // Optional GridFS id or full URL

  ContactUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.phone,
    required this.properties,
    this.status,
    this.profileImage,
  });

  factory ContactUser.fromMap(Map<String, dynamic> map) {
    return ContactUser(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
      fullName: map['fullName'] ?? map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      phone: map['phone'] ?? '',
      properties:
          map['properties'] != null ? List<String>.from(map['properties']) : [],
      status: map['status'],
      profileImage: map['profileImage']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'phone': phone,
      'properties': properties,
      'status': status,
      if (profileImage != null) 'profileImage': profileImage,
    };
  }

  @override
  String toString() {
    return 'ContactUser(id: $id, fullName: $fullName, email: $email, role: $role, status: $status)';
  }
}
