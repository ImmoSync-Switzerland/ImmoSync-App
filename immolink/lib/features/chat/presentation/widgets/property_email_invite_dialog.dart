import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../property/presentation/providers/property_providers.dart';
import '../../../property/domain/models/property.dart';
import '../providers/invitation_provider.dart';
import '../../../../core/constants/api_constants.dart';

class PropertyEmailInviteDialog extends ConsumerStatefulWidget {
  final String landlordId;

  const PropertyEmailInviteDialog({
    super.key,
    required this.landlordId,
  });

  @override
  ConsumerState<PropertyEmailInviteDialog> createState() => _PropertyEmailInviteDialogState();
}

class _PropertyEmailInviteDialogState extends ConsumerState<PropertyEmailInviteDialog> {
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedPropertyId;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendInvitation() async {
    if (_emailController.text.trim().isEmpty || _selectedPropertyId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create invitation data for email invitation
      final invitationData = {
        'propertyId': _selectedPropertyId!,
        'landlordId': widget.landlordId,
        'tenantEmail': _emailController.text.trim(),
        'message': _messageController.text.trim().isNotEmpty 
            ? _messageController.text.trim() 
            : 'Sie wurden eingeladen, diese Immobilie zu mieten.',
        'invitationType': 'email', // Mark as email invitation
      };

      // Send email invitation through backend
      final success = await _sendEmailInvitation(invitationData);

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invitation sent successfully'),
            backgroundColor: ref.read(dynamicColorsProvider).success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send invitation: $e'),
            backgroundColor: ref.read(dynamicColorsProvider).error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _sendEmailInvitation(Map<String, dynamic> invitationData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/invitations/email-invite'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(invitationData),
      );

      if (response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 404) {
        // Handle the case where user doesn't exist
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ?? 'User with this email address does not exist in the system');
      } else {
        throw Exception('Failed to send invitation');
      }
    } catch (error) {
      throw Exception('Failed to send invitation: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    final propertiesAsync = ref.watch(landlordPropertiesProvider);

    return Dialog(
      backgroundColor: colors.surfaceCards,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mieter einladen',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: colors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Property Selection
            Text(
              'Immobilie auswählen',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            propertiesAsync.when(
              data: (properties) => Container(
                decoration: BoxDecoration(
                  color: colors.primaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPropertyId,
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Immobilie auswählen',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                    isExpanded: true,
                    items: properties.map((Property property) {
                      return DropdownMenuItem<String>(
                        value: property.id,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '${property.address.street}, ${property.address.city}',
                            style: TextStyle(color: colors.textPrimary),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedPropertyId = value;
                      });
                    },
                  ),
                ),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text(
                'Error loading properties: $error',
                style: TextStyle(color: colors.error),
              ),
            ),
            const SizedBox(height: 24),

            // Email Input
            Text(
              'E-Mail des Mieters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'mieter@beispiel.de',
                hintStyle: TextStyle(color: colors.textSecondary),
                filled: true,
                fillColor: colors.primaryBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.primaryAccent, width: 2),
                ),
              ),
              style: TextStyle(color: colors.textPrimary),
            ),
            const SizedBox(height: 24),

            // Message Input
            Text(
              'Persönliche Nachricht',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Persönliche Nachricht hinzufügen (optional)',
                hintStyle: TextStyle(color: colors.textSecondary),
                filled: true,
                fillColor: colors.primaryBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.primaryAccent, width: 2),
                ),
              ),
              style: TextStyle(color: colors.textPrimary),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colors.borderLight),
                      ),
                    ),
                    child: Text(
                      l10n.cancel,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading || 
                        _emailController.text.trim().isEmpty || 
                        _selectedPropertyId == null
                        ? null
                        : _sendInvitation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(colors.surfaceCards),
                            ),
                          )
                        : Text(
                            'Einladung senden',
                            style: TextStyle(
                              color: colors.surfaceCards,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
