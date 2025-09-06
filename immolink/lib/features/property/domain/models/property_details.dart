class PropertyDetails {
  final double size;
  final int rooms;
  final List<String> amenities;
  final String propertyId; // Added propertyId field

  PropertyDetails({
    required this.size,
    required this.rooms,
    required this.amenities,
    required this.propertyId,
  });

  Map<String, dynamic> toMap() {
    return {
      'size': size,
      'rooms': rooms,
      'amenities': amenities,
      'propertyId': propertyId,
    };
  }

  factory PropertyDetails.fromMap(Map<String, dynamic> map) {
    return PropertyDetails(
      size: map['size'].toDouble(),
      rooms: map['rooms'],
      amenities: List<String>.from(map['amenities']),
      propertyId: map['propertyId'],
    );
  }
}
