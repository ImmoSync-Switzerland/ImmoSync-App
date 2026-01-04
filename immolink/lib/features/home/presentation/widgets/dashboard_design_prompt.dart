import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/settings/providers/settings_provider.dart';
import 'package:immosync/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> maybeShowDashboardDesignPrompt(
  BuildContext context,
  WidgetRef ref,
) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return;

  final prefs = await SharedPreferences.getInstance();
  final key = 'dashboardDesignPreferenceShown_${user.id}';
  if (prefs.getBool(key) ?? false) {
    return;
  }

  if (!context.mounted) return;
  final currentDesign = ref.read(settingsProvider).dashboardDesign;
  final String? selection = await showModalBottomSheet<String>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _DesignPreferenceSheet(
      initialDesign: currentDesign,
    ),
  );

  if (selection == null) {
    return;
  }

  await ref.read(settingsProvider.notifier).updateDashboardDesign(selection);
  await prefs.setBool(key, true);

  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  final designLabel = selection == 'glass'
      ? l10n.dashboardDesignGlass
      : l10n.dashboardDesignClassic;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10n.dashboardDesignChangedTo(designLabel)),
    ),
  );
}

class _DesignPreferenceSheet extends StatefulWidget {
  const _DesignPreferenceSheet({
    required this.initialDesign,
  });

  final String initialDesign;

  @override
  State<_DesignPreferenceSheet> createState() => _DesignPreferenceSheetState();
}

class _DesignPreferenceSheetState extends State<_DesignPreferenceSheet> {
  late String _selection;

  @override
  void initState() {
    super.initState();
    _selection = widget.initialDesign;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.dashboardDesign,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.dashboardDesignPromptDescription,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.75),
                      ),
                ),
                const SizedBox(height: 24),
                _DesignOptionCard(
                  label: l10n.dashboardDesignGlass,
                  description: l10n.dashboardDesignGlassDescription,
                  icon: Icons.blur_on_rounded,
                  isSelected: _selection == 'glass',
                  onTap: () => setState(() => _selection = 'glass'),
                ),
                const SizedBox(height: 16),
                _DesignOptionCard(
                  label: l10n.dashboardDesignClassic,
                  description: l10n.dashboardDesignClassicDescription,
                  icon: Icons.view_module_rounded,
                  isSelected: _selection == 'classic',
                  onTap: () => setState(() => _selection = 'classic'),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_selection),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(l10n.confirm),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesignOptionCard extends StatelessWidget {
  const _DesignOptionCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.dividerColor.withValues(alpha: 0.4);
    final Color titleColor = theme.colorScheme.onSurface;
    final Color descriptionColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.7);
    final FontWeight titleWeight =
        isSelected ? FontWeight.w700 : FontWeight.w600;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.4),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: titleWeight,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: descriptionColor,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
