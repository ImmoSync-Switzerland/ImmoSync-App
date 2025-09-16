import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../chat/presentation/providers/invitation_provider.dart';
import '../../../chat/domain/models/invitation.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';

class InvitationCard extends ConsumerWidget {
  final Invitation invitation;
  final bool isLandlord;

  const InvitationCard({
    required this.invitation,
    required this.isLandlord,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(dynamicColorsProvider);
    final statusColor = _getStatusColor(invitation.status);
    final isExpired = invitation.expiresAt != null &&
        DateTime.now().isAfter(invitation.expiresAt!);

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceCards,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: colors.shadowColor.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.mail_outline,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLandlord ? 'Invitation Sent' : 'Property Invitation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLandlord
                            ? 'To ${invitation.tenantName ?? "Unknown Tenant"} • ${invitation.propertyAddress ?? "Property"}'
                            : 'From ${invitation.landlordName ?? "Landlord"}',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusText(invitation.status).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Property details
            if (invitation.propertyAddress != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primaryBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.home_outlined,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invitation.propertyAddress!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                              letterSpacing: -0.1,
                            ),
                          ),
                          if (invitation.propertyRent != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Rent: \$${invitation.propertyRent!.toStringAsFixed(0)}/${AppLocalizations.of(context)!.monthlyInterval}',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Message
            if (invitation.message.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primaryBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.borderLight,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: colors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Message',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      invitation.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textPrimary,
                        letterSpacing: -0.1,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Date and actions
            Row(
              children: [
                Expanded(
                  child: Text(
                    _getDateText(),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (!isLandlord &&
                    invitation.status == 'pending' &&
                    !isExpired) ...[
                  _buildActionButton(
                    'Decline',
                    const Color(0xFFEF4444),
                    () => _respondToInvitation(context, ref, 'declined'),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    'Accept',
                    const Color(0xFF10B981),
                    () => _respondToInvitation(context, ref, 'accepted'),
                  ),
                ],
              ],
            ),

            // Expiration warning
            if (isExpired) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_outlined,
                      color: const Color(0xFFF59E0B),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'This invitation has expired',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFF59E0B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return const Color(0xFF10B981); // Green
      case 'declined':
        return const Color(0xFFEF4444); // Red
      case 'pending':
      default:
        return const Color(0xFFF59E0B); // Orange
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Accepted';
      case 'declined':
        return 'Declined';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  String _getDateText() {
    if (invitation.acceptedAt != null) {
      return 'Accepted ${_formatDate(invitation.acceptedAt!)}';
    } else if (invitation.declinedAt != null) {
      return 'Declined ${_formatDate(invitation.declinedAt!)}';
    } else {
      return 'Received ${_formatDate(invitation.createdAt)}';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _respondToInvitation(
      BuildContext context, WidgetRef ref, String response) async {
    try {
      final notifier = ref.read(invitationNotifierProvider.notifier);

      if (response == 'accepted') {
        await notifier.acceptInvitation(invitation.id);
      } else if (response == 'declined') {
        await notifier.declineInvitation(invitation.id);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response == 'accepted'
                  ? AppLocalizations.of(context)!.invitationAcceptedSuccessfully
                  : AppLocalizations.of(context)!.invitationDeclined,
            ),
            backgroundColor: response == 'accepted'
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.failedToRespondInvitation}: $error'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}
