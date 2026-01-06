import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:immosync/core/localization/app_translations.dart';
import 'package:immosync/core/providers/locale_provider.dart';
import 'package:immosync/core/widgets/glass_nav_bar.dart';
import 'package:immosync/core/widgets/user_avatar.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/settings/providers/settings_provider.dart';
import 'package:immosync/core/theme/app_typography.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const _bgTop = Color(0xFF0A1128);
  static const _bgBottom = Colors.black;
  static const _card = Color(0xFF1C1C1E);
  static const _primaryBlue = Color(0xFF3B82F6);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _twoFactorEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _paymentReminders = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    final name = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName.trim()
        : 'Fabian Boni';
    final email = (user?.email.trim().isNotEmpty ?? false)
        ? user!.email.trim()
        : 'fabian.boni@email.com';
    final avatarRef = user?.profileImageUrl ?? user?.profileImage;
    final currentLocale = ref.watch(localeProvider).locale;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const AppGlassNavBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [SettingsScreen._bgTop, SettingsScreen._bgBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        AppTranslations.of(context, 'nav.settings'),
                        style: AppTypography.pageTitle.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                BentoCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      UserAvatar(
                        imageRef: avatarRef,
                        name: name,
                        size: 44,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _SmallEditButton(
                        onPressed: () => context.push('/edit-profile'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionLabel(AppTranslations.of(context, 'settings.general')),
                const SizedBox(height: 10),
                LanguageSelectorCard(
                  locale: currentLocale,
                  onSelected: (locale) {
                    ref.read(localeProvider).setLocale(locale);
                    ref
                        .read(settingsProvider.notifier)
                        .updateLanguage(locale.languageCode);
                  },
                ),
                const SizedBox(height: 18),
                _SectionLabel(
                  AppTranslations.of(context, 'settings.preferences'),
                ),
                const SizedBox(height: 10),
                const BentoCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsValueRow(
                        title: 'Theme',
                        value: 'Dark Mode',
                      ),
                      _DividerLine(),
                      _SettingsValueRow(
                        title: 'Dashboard Layout',
                        value: 'Glass Modern',
                      ),
                      _DividerLine(),
                      _SettingsValueRow(
                        title: 'Currency',
                        value: 'CHF',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionLabel('Security'),
                const SizedBox(height: 10),
                BentoCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsNavRow(
                        icon: Icons.lock_outline_rounded,
                        title: 'Change Password',
                        onTap: () => context.push('/change-password'),
                      ),
                      const _DividerLine(),
                      _SettingsToggleRow(
                        icon: Icons.shield_outlined,
                        title: 'Two-Factor Authentication',
                        value: _twoFactorEnabled,
                        onChanged: (value) {
                          setState(() => _twoFactorEnabled = value);
                        },
                      ),
                      const _DividerLine(),
                      _SettingsNavRow(
                        icon: Icons.remove_red_eye_outlined,
                        title: 'Privacy Settings',
                        onTap: () => context.push('/privacy-settings'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionLabel('Notifications'),
                const SizedBox(height: 10),
                BentoCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsToggleRow(
                        icon: Icons.mail_outline_rounded,
                        title: 'Email Notifications',
                        value: _emailNotifications,
                        onChanged: (value) {
                          setState(() => _emailNotifications = value);
                        },
                      ),
                      const _DividerLine(),
                      _SettingsToggleRow(
                        icon: Icons.notifications_none_rounded,
                        title: 'Push Notifications',
                        value: _pushNotifications,
                        onChanged: (value) {
                          setState(() => _pushNotifications = value);
                        },
                      ),
                      const _DividerLine(),
                      _SettingsToggleRow(
                        icon: Icons.credit_card_rounded,
                        title: 'Payment Reminders',
                        value: _paymentReminders,
                        onChanged: (value) {
                          setState(() => _paymentReminders = value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionLabel('About'),
                const SizedBox(height: 10),
                BentoCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsNavRow(
                        icon: Icons.help_outline_rounded,
                        title: 'Help Center',
                        onTap: () => context.push('/help-center'),
                      ),
                      const _DividerLine(),
                      _SettingsNavRow(
                        icon: Icons.headset_mic_outlined,
                        title: 'Contact Support',
                        onTap: () => context.push('/contact-support'),
                      ),
                      const _DividerLine(),
                      _SettingsNavRow(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        onTap: () => context.push('/terms-of-service'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LanguageSelectorCard extends StatelessWidget {
  const LanguageSelectorCard({
    super.key,
    required this.locale,
    required this.onSelected,
  });

  final Locale locale;
  final ValueChanged<Locale> onSelected;

  @override
  Widget build(BuildContext context) {
    final languageLabel = AppTranslations.languageLabel(locale.languageCode);

    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: InkWell(
        onTap: () => _showLanguageSheet(context),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.language_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppTranslations.of(context, 'settings.language'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    languageLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final options = [
      ('en', '🇺🇸 English'),
      ('de', '🇩🇪 Deutsch'),
      ('fr', '🇫🇷 Français'),
      ('it', '🇮🇹 Italiano'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1115),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppTranslations.of(sheetContext, 'settings.chooseLanguage'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ...options.map(
                  (option) => _LanguageOptionTile(
                    label: option.$2,
                    selected: locale.languageCode == option.$1,
                    onTap: () {
                      onSelected(Locale(option.$1));
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primaryAccent = Color(0xFF3B82F6);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: selected ? Colors.white.withValues(alpha: 0.08) : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              selected ? primaryAccent : Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        trailing: AnimatedOpacity(
          opacity: selected ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(
            Icons.check_circle_rounded,
            color: primaryAccent,
          ),
        ),
      ),
    );
  }
}

class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: SettingsScreen._card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white60,
        fontWeight: FontWeight.w800,
        fontSize: 12,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _SmallEditButton extends StatelessWidget {
  const _SmallEditButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: -0.1,
        ),
      ),
      child: const Text('Edit'),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withValues(alpha: 0.06),
    );
  }
}

class _SettingsValueRow extends StatelessWidget {
  const _SettingsValueRow({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white54,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsNavRow extends StatelessWidget {
  const _SettingsNavRow({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white54,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: -0.1,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: SettingsScreen._primaryBlue,
          ),
        ],
      ),
    );
  }
}
