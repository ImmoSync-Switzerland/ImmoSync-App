import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/document_model.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../../../l10n/app_localizations.dart';

class DocumentCard extends ConsumerWidget {
  final DocumentModel document;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;
  final bool showActions;

  const DocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.onDownload,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(dynamicColorsProvider);
    final l10n = AppLocalizations.of(context)!;
    final category = DocumentCategory.values.firstWhere(
      (c) => c.id == document.category,
      orElse: () => DocumentCategory.other,
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and actions
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primaryAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      category.icon,
                      color: colors.primaryAccent,
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
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          category.displayName,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.primaryAccent,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (showActions) ...[
                    if (document.isExpiringSoon)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.expiringSoon,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    if (document.isExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.expired,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
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
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'download',
                          child: Row(
                            children: [
                              Icon(Icons.download,
                                  size: 20, color: colors.primaryAccent),
                              const SizedBox(width: 8),
                              Text(l10n.download),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete,
                                  size: 20, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(l10n.delete),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(
                        Icons.more_vert,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),

              if (document.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  document.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // File info and metadata
              Row(
                children: [
                  Icon(
                    _getFileTypeIcon(),
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    document.formattedFileSize,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(context, document.uploadDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
                  if (document.expiryDate != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.event,
                      size: 16,
                      color: document.isExpired
                          ? Colors.red
                          : document.isExpiringSoon
                              ? Colors.orange
                              : colors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.expiresOn(
                          _formatDate(context, document.expiryDate!)),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: document.isExpired
                                ? Colors.red
                                : document.isExpiringSoon
                                    ? Colors.orange
                                    : colors.textSecondary,
                          ),
                    ),
                  ],
                ],
              ),

              // Assignment info
              if (document.assignedTenantIds.isNotEmpty ||
                  document.propertyIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (document.assignedTenantIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.primaryAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person,
                              size: 12,
                              color: colors.primaryAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.tenantsCount(
                                  document.assignedTenantIds.length),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colors.primaryAccent,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    if (document.propertyIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.luxuryGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.home,
                              size: 12,
                              color: colors.luxuryGold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.propertiesCount(document.propertyIds.length),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colors.luxuryGold,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
