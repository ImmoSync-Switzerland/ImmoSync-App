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
  final String? propertyId; // optional
  // Canonical absolute URL from server; optional and may be null
  final String? profileImageUrl;
  // Back-compat field used across UI; we will prefer profileImageUrl if present
  final String? profileImage; // optional GridFS id or URL
  final List<String> blockedUsers; // ids the current user has blocked

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
    this.profileImageUrl,
    this.profileImage,
    this.blockedUsers = const [],
  });

  factory User.fromMap(Map<String, dynamic> map) {
    // Normalize id
    String userId = '';
    if (map['_id'] != null) {
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

    // Helpers
    String _asString(dynamic v) => v?.toString() ?? '';
    bool _asBool(dynamic v, {bool def = false}) => v is bool ? v : def;
    DateTime _asDate(dynamic v) {
      if (v == null) return DateTime(1970, 1, 1);
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime(1970, 1, 1);
      }
    }

    // blockedUsers list
    final List<String> blocked = () {
      final raw = map['blockedUsers'];
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return <String>[];
    }();

    // Prefer canonical absolute URL if provided by the server
    // Normalize HTTP to HTTPS for security
    final String? canonicalUrl = map['profileImageUrl'] != null
        ? map['profileImageUrl'].toString().replaceFirst('http://', 'https://')
        : null;
    final String? legacyRef = map['profileImage'] != null
        ? map['profileImage'].toString().replaceFirst('http://', 'https://')
        : null;

    return User(
      id: userId,
      email: _asString(map['email']),
      fullName: _asString(map['fullName']),
      birthDate: _asDate(map['birthDate']),
      role: _asString(map['role']),
      isAdmin: _asBool(map['isAdmin']),
      isValidated: _asBool(map['isValidated'], def: true),
      address: map['address'] != null
          ? Address.fromMap(map['address'])
          : Address(street: '', city: '', postalCode: '', country: ''),
      propertyId: map['propertyId'] != null
          ? (map['propertyId'] is Map && map['propertyId']['\$oid'] != null
              ? map['propertyId']['\$oid']
              : map['propertyId'].toString())
          : null,
      profileImageUrl: canonicalUrl,
      // Back-compat: set profileImage to canonical URL if present, else legacy ref
      profileImage: canonicalUrl ?? legacyRef,
      blockedUsers: blocked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'email': email,
      'fullName': fullName,
      'birthDate': birthDate.toIso8601String(),
      'role': role,
      'isAdmin': isAdmin,
      'isValidated': isValidated,
      'address': address.toMap(),
      if (propertyId != null) 'propertyId': propertyId,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (profileImage != null) 'profileImage': profileImage,
      'blockedUsers': blockedUsers,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    DateTime? birthDate,
    String? role,
    bool? isAdmin,
    bool? isValidated,
    Address? address,
    String? propertyId,
    String? profileImageUrl,
    String? profileImage,
    List<String>? blockedUsers,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      role: role ?? this.role,
      isAdmin: isAdmin ?? this.isAdmin,
      isValidated: isValidated ?? this.isValidated,
      address: address ?? this.address,
      propertyId: propertyId ?? this.propertyId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      profileImage: profileImage ?? this.profileImage,
      blockedUsers: blockedUsers ?? this.blockedUsers,
    );
  }
}
