import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:immosync/core/widgets/glass_nav_bar.dart';
import 'package:immosync/core/widgets/user_avatar.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
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
                        'Settings',
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
                const _SectionLabel('Preferences'),
                const SizedBox(height: 10),
                const BentoCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsValueRow(
                        title: 'Language',
                        value: 'English',
                      ),
                      _DividerLine(),
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
