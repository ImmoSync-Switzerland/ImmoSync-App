import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../home/presentation/pages/glass_dashboard_shared.dart';
import '../../../chat/domain/models/invitation.dart';
import '../../../chat/presentation/providers/invitation_provider.dart';

class InvitationCard extends ConsumerWidget {
  const InvitationCard({
    required this.invitation,
    required this.isLandlord,
    required this.glassMode,
    super.key,
  });

  final Invitation invitation;
  final bool isLandlord;
  final bool glassMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = ref.watch(dynamicColorsProvider);
    final statusColor = _getStatusColor(invitation.status);
    final bool isExpired = invitation.expiresAt != null &&
        DateTime.now().isAfter(invitation.expiresAt!);

    final Color primaryText = glassMode ? Colors.white : colors.textPrimary;
    final Color secondaryText =
        glassMode ? Colors.white.withValues(alpha: 0.78) : colors.textSecondary;
    final Color borderColor =
        glassMode ? Colors.white.withValues(alpha: 0.28) : colors.borderLight;
    final Color cardBackground =
        glassMode ? Colors.black.withValues(alpha: 0.32) : colors.surfaceCards;
    final Color highlightBackground = glassMode
        ? Colors.black.withValues(alpha: 0.22)
        : colors.primaryBackground;

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: glassMode ? 0.28 : 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: glassMode
                      ? Colors.white.withValues(alpha: 0.32)
                      : statusColor.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                Icons.mail_outline,
                color: glassMode ? Colors.white : statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLandlord ? l10n.invitationSent : l10n.propertyInvitation,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLandlord
                        ? l10n.toTenant(
                            invitation.tenantName ?? l10n.unknownTenant,
                            invitation.propertyAddress ?? l10n.properties,
                          )
                        : l10n.fromLandlord(
                            invitation.landlordName ?? l10n.landlord,
                          ),
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryText,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: glassMode ? 0.28 : 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: glassMode
                      ? Colors.white.withValues(alpha: 0.35)
                      : statusColor.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                _getStatusText(invitation.status, l10n).toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: glassMode ? Colors.white : statusColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (invitation.propertyAddress != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: highlightBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.home_outlined,
                  color: glassMode ? Colors.white : colors.textSecondary,
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
                          color: primaryText,
                          letterSpacing: -0.1,
                        ),
                      ),
                      if (invitation.propertyRent != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.rent}: \$${invitation.propertyRent!.toStringAsFixed(0)}/${l10n.monthlyInterval}',
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryText,
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
        if (invitation.message.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: highlightBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: glassMode ? Colors.white : colors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.messageLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: glassMode
                            ? Colors.white.withValues(alpha: 0.85)
                            : colors.textSecondary,
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
                    color: primaryText,
                    letterSpacing: -0.1,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                _getDateText(l10n),
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!isLandlord &&
                invitation.status == 'pending' &&
                !isExpired) ...[
              _buildActionButton(
                l10n.decline,
                const Color(0xFFEF4444),
                () => _respondToInvitation(context, ref, 'declined'),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                l10n.accept,
                const Color(0xFF10B981),
                () => _respondToInvitation(context, ref, 'accepted'),
              ),
            ],
          ],
        ),
        if (isExpired) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: glassMode ? 0.25 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: glassMode
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.red.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: glassMode ? Colors.white : Colors.red.shade600,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.invitationExpired,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: glassMode ? Colors.white : Colors.red.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    if (glassMode) {
      return GlassContainer(
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.all(20),
          child: content,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
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
      padding: const EdgeInsets.all(20),
      child: content,
    );
  }

  Widget _buildActionButton(
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    final Color textColor = glassMode ? Colors.white : color;
    final Color background = glassMode
        ? color.withValues(alpha: 0.32)
        : color.withValues(alpha: 0.1);
    final Color border = glassMode
        ? Colors.white.withValues(alpha: 0.35)
        : color.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
            letterSpacing: -0.1,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return const Color(0xFF10B981);
      case 'declined':
        return const Color(0xFFEF4444);
      case 'pending':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _getStatusText(String status, AppLocalizations l10n) {
    switch (status) {
      case 'accepted':
        return l10n.invitationAccepted;
      case 'declined':
        return l10n.invitationDeclined;
      case 'pending':
      default:
        return l10n.invitationPending;
    }
  }

  String _getDateText(AppLocalizations l10n) {
    if (invitation.acceptedAt != null) {
      return l10n.acceptedOn(_formatDate(invitation.acceptedAt!, l10n));
    } else if (invitation.declinedAt != null) {
      return l10n.declinedOn(_formatDate(invitation.declinedAt!, l10n));
    } else {
      return l10n.receivedOn(_formatDate(invitation.createdAt, l10n));
    }
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return l10n.minutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _respondToInvitation(
    BuildContext context,
    WidgetRef ref,
    String response,
  ) async {
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
            content: Text(
              '${AppLocalizations.of(context)!.failedToRespondInvitation}: $error',
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}
