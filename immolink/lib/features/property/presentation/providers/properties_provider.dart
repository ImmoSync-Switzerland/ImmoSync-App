import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/property/presentation/providers/property_providers.dart';
import '../../domain/models/property.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final landlordPropertiesProvider = StreamProvider<List<Property>>((ref) {
  final propertyService = ref.watch(propertyServiceProvider);
  final user = ref.watch(currentUserProvider); // User object directly
  if (user == null) return Stream.value([]);
  print('Fetching properties for user ID: ${user.id.toString()}');
  return propertyService.getLandlordProperties(user.id.toString());
});
