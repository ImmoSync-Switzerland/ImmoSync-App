import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/presentation/pages/glass_dashboard_shared.dart';
import '../../domain/models/document_model.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../l10n/app_localizations.dart';

class DocumentCard extends ConsumerWidget {
  const DocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.onDownload,
    this.onDelete,
    this.showActions = true,
    this.glassMode = false,
  });

  final DocumentModel document;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool glassMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    final category = DocumentCategory.values.firstWhere(
      (c) => c.id == document.category,
      orElse: () => DocumentCategory.other,
    );

    final borderRadius = BorderRadius.circular(glassMode ? 24 : 12);
    final Color primaryText = glassMode ? Colors.white : colors.textPrimary;
    final Color secondaryText =
        glassMode ? Colors.white.withValues(alpha: 0.82) : colors.textSecondary;
    final Color accentColor = glassMode ? Colors.white : colors.primaryAccent;
    final Color iconBackground = glassMode
        ? Colors.white.withValues(alpha: 0.16)
        : colors.primaryAccent.withValues(alpha: 0.1);
    final Color chipForeground =
        glassMode ? Colors.white : colors.primaryAccent;
    final Color chipBackground = glassMode
        ? Colors.white.withValues(alpha: 0.14)
        : colors.primaryAccent.withValues(alpha: 0.1);

    final List<Widget> statusChips = [];
    if (document.isExpiringSoon) {
      statusChips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: glassMode ? 0.22 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.expiringSoon,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: glassMode ? Colors.white : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      );
    }
    if (document.isExpired) {
      statusChips.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: glassMode ? 0.22 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            l10n.expired,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: glassMode ? Colors.white : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      );
    }

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(glassMode ? 16 : 8),
          ),
          child: Icon(
            category.icon,
            color: accentColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                category.displayName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: chipForeground,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        if (showActions) ...[
          ...statusChips,
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'download':
                  onDownload?.call();
                  break;
                case 'delete':
                  onDelete?.call();
                  break;
              }
            },
            color: glassMode ? Colors.black.withValues(alpha: 0.75) : null,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20, color: chipForeground),
                    const SizedBox(width: 8),
                    Text(
                      l10n.download,
                      style: TextStyle(color: glassMode ? Colors.white : null),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete,
                        size: 20,
                        color: glassMode ? Colors.red.shade200 : Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      l10n.delete,
                      style: TextStyle(color: glassMode ? Colors.white : null),
                    ),
                  ],
                ),
              ),
            ],
            icon: Icon(
              Icons.more_vert,
              color: glassMode ? Colors.white : colors.textSecondary,
            ),
          ),
        ],
      ],
    );

    final description = document.description.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              document.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: secondaryText,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          )
        : const SizedBox.shrink();

    final metadata = Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildMetaItem(
            icon: _getFileTypeIcon(),
            label: document.formattedFileSize,
            color: secondaryText,
            context: context,
          ),
          _buildMetaItem(
            icon: Icons.access_time,
            label: _formatDate(context, document.uploadDate),
            color: secondaryText,
            context: context,
          ),
          if (document.expiryDate != null)
            _buildMetaItem(
              icon: Icons.event,
              label: l10n.expiresOn(
                _formatDate(context, document.expiryDate!),
              ),
              color: document.isExpired
                  ? (glassMode ? Colors.white : Colors.red)
                  : document.isExpiringSoon
                      ? (glassMode ? Colors.white : Colors.orange)
                      : secondaryText,
              context: context,
            ),
        ],
      ),
    );

    final assignments = (document.assignedTenantIds.isNotEmpty ||
            document.propertyIds.isNotEmpty)
        ? Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (document.assignedTenantIds.isNotEmpty)
                  _buildAssignmentChip(
                    icon: Icons.person,
                    label: l10n.tenantsCount(document.assignedTenantIds.length),
                    foreground: chipForeground,
                    background: chipBackground,
                  ),
                if (document.propertyIds.isNotEmpty)
                  _buildAssignmentChip(
                    icon: Icons.home,
                    label: l10n.propertiesCount(document.propertyIds.length),
                    foreground: glassMode ? Colors.white : colors.luxuryGold,
                    background: glassMode
                        ? Colors.white.withValues(alpha: 0.14)
                        : colors.luxuryGold.withValues(alpha: 0.1),
                  ),
              ],
            ),
          )
        : const SizedBox.shrink();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        description,
        metadata,
        assignments,
      ],
    );

    if (glassMode) {
      return Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: GlassContainer(
            padding: const EdgeInsets.all(20),
            child: content,
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      ),
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String label,
    required Color color,
    required BuildContext context,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildAssignmentChip({
    required IconData icon,
    required String label,
    required Color foreground,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileTypeIcon() {
    switch (document.mimeType) {
      case 'application/pdf':
        return Icons.picture_as_pdf;
      case 'application/msword':
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return Icons.description;
      case 'text/plain':
        return Icons.text_snippet;
      case 'image/png':
      case 'image/jpeg':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return l10n.today;
    } else if (difference.inDays == 1) {
      return l10n.yesterday;
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return l10n.weeksAgo(weeks);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
