import 'package:immosync/features/property/domain/models/property.dart';

class User {
  final String id;
  final String email;
  final String fullName;
  final DateTime birthDate;
  final String role;
  final bool isAdmin;
  final bool isValidated;
  final Address address;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.birthDate,
    required this.role,
    required this.isAdmin,
    required this.isValidated,
    required this.address,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    // Handle MongoDB _id conversion properly
    String userId = '';
    if (map['_id'] != null) {
      // Handle different ID formats from MongoDB
      final idValue = map['_id'];
      if (idValue is String) {
        userId = idValue;
      } else if (idValue is Map && idValue['\$oid'] != null) {
        userId = idValue['\$oid'];
      } else {
        userId = idValue.toString();
      }
    } else if (map['id'] != null) {
      userId = map['id'].toString();
    }
    
    return User(
        id: userId,
        email: map['email'],
        fullName: map['fullName'],
        birthDate: DateTime.parse(map['birthDate']),
        role: map['role'],
        isAdmin: map['isAdmin'],
        isValidated: map['isValidated'],
        // Provide default address when not in response
        address: map['address'] != null
            ? Address.fromMap(map['address'])
            : Address(street: '', city: '', postalCode: '', country: ''));
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id, // MongoDB format
      'email': email,
      'fullName': fullName,
      'birthDate': birthDate.toIso8601String(),
      'role': role,
      'isAdmin': isAdmin,
      'isValidated': isValidated,
      'address': address.toMap(),
    };
  }
}

