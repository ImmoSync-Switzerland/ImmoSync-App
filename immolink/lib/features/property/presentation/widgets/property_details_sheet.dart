import 'package:flutter/material.dart';
import 'package:immosync/features/property/domain/models/property.dart';

class PropertyDetailsSheet extends StatelessWidget {
  final Property property;

  const PropertyDetailsSheet({
    required this.property,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Property Details',
            style: Theme.of(context)
                .textTheme
                .titleLarge, // Updated from headline6
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Size', '${property.details.size}m²'),
          _buildDetailRow('Rooms', property.details.rooms.toString()),
          _buildDetailRow('Status', property.status),
          const SizedBox(height: 16),
          Text(
            'Amenities',
            style: Theme.of(context)
                .textTheme
                .titleMedium, // Updated from subtitle1
          ),
          Wrap(
            spacing: 8,
            children: property.details.amenities
                .map((amenity) => Chip(label: Text(amenity)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
