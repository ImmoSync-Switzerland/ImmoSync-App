import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../domain/models/invitation.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../property/presentation/providers/property_providers.dart';
import '../../../../core/constants/api_constants.dart';

// Service provider for invitation operations
final invitationServiceProvider = Provider<InvitationService>((ref) {
  return InvitationService();
});

class InvitationService {
  static String _apiUrl = ApiConstants.baseUrl;

  Future<List<Invitation>> getUserInvitations(String userId) async {
    final response = await http.get(
      Uri.parse('$_apiUrl/invitations/user/$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Invitation.fromMap(json)).toList();
    }
    throw Exception('Failed to fetch invitations');
  }

  Future<dynamic> acceptInvitation(String invitationId) async {
    final httpResponse = await http.put(
      Uri.parse('$_apiUrl/invitations/$invitationId/accept'),
      headers: {'Content-Type': 'application/json'},
    );

    if (httpResponse.statusCode != 200) {
      throw Exception('Failed to accept invitation');
    }

    // Return parsed body so caller can update local state immediately
    try {
      return json.decode(httpResponse.body);
    } catch (_) {
      return null;
    }
  }

  Future<void> declineInvitation(String invitationId) async {
    final httpResponse = await http.put(
      Uri.parse('$_apiUrl/invitations/$invitationId/decline'),
      headers: {'Content-Type': 'application/json'},
    );

    if (httpResponse.statusCode != 200) {
      throw Exception('Failed to decline invitation');
    }
  }

  Future<void> respondToInvitation(String invitationId, String response) async {
    if (response == 'accept') {
      await acceptInvitation(invitationId);
    } else if (response == 'decline') {
      await declineInvitation(invitationId);
    } else {
      throw Exception('Invalid response: $response');
    }
  }

  Future<void> sendInvitation({
    required String propertyId,
    required String landlordId,
    required String tenantId,
    String? message,
  }) async {
    final response = await http.post(
      Uri.parse('$_apiUrl/invitations'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'propertyId': propertyId,
        'landlordId': landlordId,
        'tenantId': tenantId,
        'message': message ?? 'You have been invited to rent this property',
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send invitation');
    }
  }
}

// Provider for current user's invitations
final userInvitationsProvider = FutureProvider<List<Invitation>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) {
    return [];
  }

  final invitationService = ref.watch(invitationServiceProvider);
  return invitationService.getUserInvitations(currentUser.id);
});

// Provider for pending invitations only
final pendingInvitationsProvider =
    Provider<AsyncValue<List<Invitation>>>((ref) {
  final invitationsAsync = ref.watch(userInvitationsProvider);

  return invitationsAsync.when(
    data: (invitations) => AsyncValue.data(
      invitations.where((invitation) => invitation.isPending).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// State notifier for invitation actions
class InvitationNotifier extends StateNotifier<AsyncValue<void>> {
  final InvitationService _invitationService;
  final Ref _ref;

  InvitationNotifier(this._invitationService, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> acceptInvitation(String invitationId) async {
    state = const AsyncValue.loading();

    try {
      final result = await _invitationService.acceptInvitation(invitationId);
      state = const AsyncValue.data(null);
      // If backend returned property & tenantUser, update current user propertyId immediately
      if (result is Map && result['tenantUser'] != null) {
        final tenantUser = result['tenantUser'];
        final property = result['property'];
        final propertyId = property != null
            ? property['_id']?.toString()
            : tenantUser['propertyId']?.toString();
        if (propertyId != null) {
          try {
            _ref.read(currentUserProvider.notifier).setPropertyId(propertyId);
          } catch (_) {}
        }
      }

      // Immediate refresh (ref.refresh starts fetch now vs invalidate defers)
      final _ = _ref.refresh(userInvitationsProvider);
      final __ = _ref.refresh(tenantPropertiesProvider);
      final ___ = _ref.refresh(propertiesProvider);
      final ____ = _ref.refresh(landlordPropertiesProvider);
      // Trigger manual property refresh tick for any stream listeners
      try {
        _ref.read(propertyRefreshTriggerProvider.notifier).state++;
      } catch (_) {}
      // Schedule a second refresh after slight delay to catch eventual consistency
      Future.delayed(const Duration(milliseconds: 400), () {
        try {
          final _____ = _ref.refresh(tenantPropertiesProvider);
          _ref.read(propertyRefreshTriggerProvider.notifier).state++;
        } catch (_) {}
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> declineInvitation(String invitationId) async {
    state = const AsyncValue.loading();

    try {
      await _invitationService.declineInvitation(invitationId);
      state = const AsyncValue.data(null);

      // Refresh invitations after declining
      _ref.invalidate(userInvitationsProvider);
      // Refresh tenant properties in case anything changed
      _ref.invalidate(tenantPropertiesProvider);
      // Also refresh all properties to ensure UI consistency
      _ref.invalidate(propertiesProvider);
      // Refresh landlord properties as well
      _ref.invalidate(landlordPropertiesProvider);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> respondToInvitation(String invitationId, String response) async {
    if (response == 'accept') {
      await acceptInvitation(invitationId);
    } else if (response == 'decline') {
      await declineInvitation(invitationId);
    }
  }

  Future<void> sendInvitation({
    required String propertyId,
    required String landlordId,
    required String tenantId,
    String? message,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _invitationService.sendInvitation(
        propertyId: propertyId,
        landlordId: landlordId,
        tenantId: tenantId,
        message: message,
      );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final invitationNotifierProvider =
    StateNotifierProvider<InvitationNotifier, AsyncValue<void>>((ref) {
  return InvitationNotifier(ref.watch(invitationServiceProvider), ref);
});
