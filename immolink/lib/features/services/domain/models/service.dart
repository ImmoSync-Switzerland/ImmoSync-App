class Service {
  final String id;
  final String name;
  final String description;
  final String category;
  final String availability;
  final String landlordId;
  final double price;
  final String contactInfo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.availability,
    required this.landlordId,
    required this.price,
    required this.contactInfo,
    this.createdAt,
    this.updatedAt,
  });

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['_id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      availability: map['availability'] ?? 'available',
      landlordId: map['landlordId'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      contactInfo: map['contactInfo'] ?? '',
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt:
          map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'category': category,
      'availability': availability,
      'landlordId': landlordId,
      'price': price,
      'contactInfo': contactInfo,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Service copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? availability,
    String? landlordId,
    double? price,
    String? contactInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      availability: availability ?? this.availability,
      landlordId: landlordId ?? this.landlordId,
      price: price ?? this.price,
      contactInfo: contactInfo ?? this.contactInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
