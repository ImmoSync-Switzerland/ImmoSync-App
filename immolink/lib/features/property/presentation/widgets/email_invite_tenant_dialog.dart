import 'dart:ui';

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

    // Most of the app uses a dark glass/bento visual style.
    // Ensure this dialog matches that look even if the effective theme is light.
    final palette = colors.isDark ? colors : DynamicAppColors(isDark: true);

    final media = MediaQuery.of(context);
    final keyboardInset = media.viewInsets.bottom;
    final maxHeight = media.size.height * 0.82;

    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: palette.shadowColorMedium,
                blurRadius: 24,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.overlayBackground,
                  border: Border.all(
                    color: palette.overlayWhite.withValues(alpha: 0.14),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: maxHeight,
                    minWidth: media.size.width * 0.90,
                  ),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding:
                        EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardInset),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(l10n, palette),
                          const SizedBox(height: 20),
                          _buildEmailField(l10n, palette),
                          const SizedBox(height: 14),
                          _buildMessageField(l10n, palette),
                          const SizedBox(height: 20),
                          _buildActionButtons(l10n, palette),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
                l10n.inviteTenant,
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
          l10n.howToInviteTenantAnswer,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            height: 1.25,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildEmailField(AppLocalizations l10n, DynamicAppColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.email,
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
          textInputAction: TextInputAction.next,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'mieter@beispiel.de',
            hintStyle: TextStyle(color: colors.textPlaceholder),
            prefixIcon: Icon(Icons.email, color: colors.primaryAccent),
            filled: true,
            fillColor: colors.overlayWhite.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: colors.overlayWhite.withValues(alpha: 0.14)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: colors.overlayWhite.withValues(alpha: 0.14)),
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
              return l10n.pleaseEnterYourEmail;
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return l10n.pleaseEnterValidEmail;
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
          l10n.message,
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
          textInputAction: TextInputAction.newline,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: l10n.typeMessage,
            hintStyle: TextStyle(color: colors.textPlaceholder),
            prefixIcon: Icon(Icons.message, color: colors.primaryAccent),
            filled: true,
            fillColor: colors.overlayWhite.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: colors.overlayWhite.withValues(alpha: 0.14)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: colors.overlayWhite.withValues(alpha: 0.14)),
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
              side: BorderSide(
                  color: colors.overlayWhite.withValues(alpha: 0.14)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                color: colors.textPrimary,
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
              foregroundColor: colors.textOnAccent,
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
                    l10n.inviteTenant,
                    style: const TextStyle(
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
        final colors = ref.read(dynamicColorsProvider);
        final palette = colors.isDark ? colors : DynamicAppColors(isDark: true);
        final l10n = AppLocalizations.of(context)!;

        // Invalidate providers to refresh the UI
        ref.invalidate(userInvitationsProvider);

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.invitationSentSuccessfully),
            backgroundColor: palette.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        final colors = ref.read(dynamicColorsProvider);
        final palette = colors.isDark ? colors : DynamicAppColors(isDark: true);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToSendInvitation}: $error'),
            backgroundColor: palette.error,
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
