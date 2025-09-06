class Property {
  final String id;
  final String landlordId;
  final List<String> tenantIds;
  final Address address;
  final String status;
  final double rentAmount;
  final PropertyDetails details;
  final List<String> imageUrls;
  final double outstandingPayments; // Added field

  Property({
    required this.id,
    required this.landlordId,
    required this.tenantIds,
    required this.address,
    required this.status,
    required this.rentAmount,
    required this.details,
    this.imageUrls = const [],
    this.outstandingPayments = 0.0, // Default to zero
  });

  factory Property.fromMap(Map<String, dynamic> map) {
    // Defensive parsing with fallbacks to prevent runtime type errors from incomplete/legacy documents
    try {
      final rawAddress = map['address'] ?? const {};
      final rawDetails = map['details'] ?? const {};
      return Property(
        id: (map['_id'] ?? map['id'] ?? '').toString(),
        landlordId: (map['landlordId'] ?? '').toString(),
        address: Address.fromMap(Map<String, dynamic>.from(rawAddress)),
        status: (map['status'] ?? 'available').toString(),
        rentAmount: _asDouble(map['rentAmount']),
        details: PropertyDetails.fromMap(Map<String, dynamic>.from(rawDetails)),
        imageUrls: _stringList(map['imageUrls']),
        tenantIds: _stringList(map['tenantIds']),
        outstandingPayments: _asDouble(map['outstandingPayments']),
      );
    } catch (e, st) {
      // Log malformed document for diagnostics
      print('[Property.fromMap][ERROR] $e');
      print(st);
      print('[Property.fromMap][RAW] ${map.toString()}');
      // Provide a safe fallback instance to keep UI resilient
      return Property(
        id: (map['_id'] ?? map['id'] ?? '').toString(),
        landlordId: (map['landlordId'] ?? '').toString(),
        address: Address(street: '', city: '', postalCode: '', country: ''),
        status: 'unknown',
        rentAmount: 0,
        details: PropertyDetails(size: 0, rooms: 0, amenities: const []),
        imageUrls: const [],
        tenantIds: const [],
        outstandingPayments: 0,
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'landlordId': landlordId,
      'tenantIds': tenantIds,
      'address': address.toMap(),
      'status': status,
      'rentAmount': rentAmount,
      'details': details.toMap(),
      'imageUrls': imageUrls,
      'outstandingPayments': outstandingPayments,
    };
  }
}

class Address {
  final String street;
  final String city;
  final String postalCode;
  final String country;

  Address({
    required this.street,
    required this.city,
    required this.postalCode,
    required this.country,
  });

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      street: (map['street'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      postalCode: (map['postalCode'] ?? '').toString(),
      country: (map['country'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'postalCode': postalCode,
      'country': country,
    };
  }
}

class PropertyDetails {
  final double size;
  final int rooms;
  final List<String> amenities;

  PropertyDetails({
    required this.size,
    required this.rooms,
    required this.amenities,
  });

  factory PropertyDetails.fromMap(Map<String, dynamic> map) {
    return PropertyDetails(
      size: _asDouble(map['size']),
      rooms: _asInt(map['rooms']),
      amenities: _stringList(map['amenities']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'size': size,
      'rooms': rooms,
      'amenities': amenities,
    };
  }
}

// Helper parsing functions (private)
double _asDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

int _asInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

List<String> _stringList(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return const [];
}
