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
  final String? propertyId; // newly added, optional
  final String? profileImage; // optional GridFS id or URL

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.birthDate,
    required this.role,
    required this.isAdmin,
    required this.isValidated,
    required this.address,
  this.propertyId,
  this.profileImage,
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

    // Safe parse helpers
    String _asString(dynamic v) => v?.toString() ?? '';
    bool _asBool(dynamic v, {bool def = false}) => v is bool ? v : def;
    DateTime _asDate(dynamic v) {
      if (v == null) return DateTime(1970, 1, 1);
      try { return DateTime.parse(v.toString()); } catch (_) { return DateTime(1970, 1, 1); }
    }

    return User(
        id: userId,
        email: _asString(map['email']),
        fullName: _asString(map['fullName']),
        birthDate: _asDate(map['birthDate']),
        role: _asString(map['role']),
        isAdmin: _asBool(map['isAdmin']),
        isValidated: _asBool(map['isValidated'], def: true),
        // Provide default address when not in response
        address: map['address'] != null
            ? Address.fromMap(map['address'])
            : Address(street: '', city: '', postalCode: '', country: ''),
        propertyId: map['propertyId'] != null
            ? (map['propertyId'] is Map && map['propertyId']['\$oid'] != null
                ? map['propertyId']['\$oid']
                : map['propertyId'].toString())
      : null,
    profileImage: map['profileImage'] != null
      ? map['profileImage'].toString()
      : null);
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
      if (propertyId != null) 'propertyId': propertyId,
  if (profileImage != null) 'profileImage': profileImage,
    };
  }
}
