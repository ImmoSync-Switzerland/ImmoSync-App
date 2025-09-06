class ContactUser {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String phone;
  final List<String> properties;
  final String? status; // For tenant status: 'active' or 'available'

  ContactUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.phone,
    required this.properties,
    this.status,
  });

  factory ContactUser.fromMap(Map<String, dynamic> map) {
    return ContactUser(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      phone: map['phone'] ?? '',
      properties:
          map['properties'] != null ? List<String>.from(map['properties']) : [],
      status: map['status'],
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
    };
  }

  @override
  String toString() {
    return 'ContactUser(id: $id, fullName: $fullName, email: $email, role: $role, status: $status)';
  }
}
