import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/presentation/providers/invitation_provider.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/token_manager.dart';

class EmailInviteTenantDialog extends ConsumerStatefulWidget {
  final String propertyId;

  const EmailInviteTenantDialog({required this.propertyId, super.key});

  @override
  ConsumerState<EmailInviteTenantDialog> createState() =>
      _EmailInviteTenantDialogState();
}

class _EmailInviteTenantDialogState
    extends ConsumerState<EmailInviteTenantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: colors.surfaceCards,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(l10n, colors),
              const SizedBox(height: 24),
              _buildEmailField(l10n, colors),
              const SizedBox(height: 16),
              _buildMessageField(l10n, colors),
              const SizedBox(height: 24),
              _buildActionButtons(l10n, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, DynamicAppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.email_outlined,
              color: colors.primaryAccent,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Mieter per E-Mail einladen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close, color: colors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Laden Sie einen Mieter über seine E-Mail-Adresse ein. Er erhält eine Benachrichtigung und kann die Einladung in der App akzeptieren.',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(AppLocalizations l10n, DynamicAppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'E-Mail-Adresse des Mieters',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'mieter@beispiel.de',
            hintStyle: TextStyle(color: colors.textSecondary),
            prefixIcon: Icon(Icons.email, color: colors.primaryAccent),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colors.error),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Bitte geben Sie eine E-Mail-Adresse ein';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Bitte geben Sie eine gültige E-Mail-Adresse ein';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMessageField(AppLocalizations l10n, DynamicAppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Persönliche Nachricht (optional)',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _messageController,
          maxLines: 3,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Fügen Sie eine persönliche Nachricht hinzu...',
            hintStyle: TextStyle(color: colors.textSecondary),
            prefixIcon: Icon(Icons.message, color: colors.primaryAccent),
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
        ),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n, DynamicAppColors colors) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colors.borderLight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Abbrechen',
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
            onPressed: _isLoading ? null : _sendInvitation,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Einladung senden',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendInvitation() async {
    print('[EmailInviteTenantDialog] _sendInvitation called');

    if (!_formKey.currentState!.validate()) {
      print('[EmailInviteTenantDialog] Form validation failed');
      return;
    }

    print('[EmailInviteTenantDialog] Form validation passed');

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      print('[EmailInviteTenantDialog] Current user: ${currentUser?.id}');

      if (currentUser == null) {
        throw Exception('Benutzer nicht angemeldet');
      }

      // Create invitation data
      final invitationData = {
        'propertyId': widget.propertyId,
        'landlordId': currentUser.id,
        'tenantEmail': _emailController.text.trim(),
        'message': _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : 'Sie wurden eingeladen, diese Immobilie zu mieten.',
        'invitationType': 'email', // Mark as email invitation
      };

      print(
          '[EmailInviteTenantDialog] Calling _sendEmailInvitation with data: $invitationData');

      // Send email invitation through backend
      final success = await _sendEmailInvitation(invitationData);

      if (success && mounted) {
        // Invalidate providers to refresh the UI
        ref.invalidate(userInvitationsProvider);

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Einladung erfolgreich gesendet!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Senden der Einladung: $error'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _sendEmailInvitation(Map<String, dynamic> invitationData) async {
    try {
      print(
          '[EmailInviteTenantDialog] Sending email invitation: $invitationData');

      // CRITICAL: Get auth token from TokenManager
      final tokenManager = TokenManager();
      final headers = await tokenManager.getHeaders();
      headers['Content-Type'] = 'application/json';

      print('[EmailInviteTenantDialog] Headers prepared with token');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/invitations/email-invite'),
        headers: headers,
        body: json.encode(invitationData),
      );

      print(
          '[EmailInviteTenantDialog] Response status: ${response.statusCode}');
      print('[EmailInviteTenantDialog] Response body: ${response.body}');

      if (response.statusCode == 201) {
        print('[EmailInviteTenantDialog] Invitation sent successfully');
        return true;
      } else if (response.statusCode == 404) {
        print('[EmailInviteTenantDialog] User not found (404)');
        // Handle the case where user doesn't exist
        final errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ??
            'Benutzer mit dieser E-Mail-Adresse existiert nicht im System');
      } else {
        throw Exception('Fehler beim Senden der Einladung');
      }
    } catch (error) {
      throw Exception('Fehler beim Senden der Einladung: $error');
    }
  }
}
