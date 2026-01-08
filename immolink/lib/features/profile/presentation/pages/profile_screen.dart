import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/core/theme/app_typography.dart';
import 'package:immosync/core/widgets/glass_nav_bar.dart';
import 'package:immosync/core/widgets/user_avatar.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/l10n/app_localizations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _bgTop = Color(0xFF0A1128);
  static const _bgBottom = Colors.black;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context)!;

    final name = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName.trim()
        : 'Fabian Boni';
    final roleRaw = user?.role.trim() ?? '';
    final role = roleRaw.isNotEmpty
        ? (roleRaw[0].toUpperCase() + roleRaw.substring(1))
        : 'Landlord';

    final avatarRef = user?.profileImageUrl ?? user?.profileImage;

    final email = user?.email.trim() ?? '';
    final phone = (user?.phone ?? '').toString().trim();
    final address = _formatAddress(user);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const AppGlassNavBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
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
                    Text(
                      l10n.profile,
                      style: AppTypography.pageTitle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                _HeaderProfileCard(
                  name: name,
                  role: role,
                  isVerified: user?.isValidated ?? true,
                  avatarRef: avatarRef,
                  onEdit: () => context.push('/edit-profile'),
                ),
                const SizedBox(height: 14),
                BentoCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.mail_outline_rounded,
                        label: l10n.email,
                        value: email.isNotEmpty ? email : '—',
                        allowEllipsis: true,
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: l10n.phone,
                        value: phone.isNotEmpty ? phone : '—',
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: l10n.address,
                        value: address.isNotEmpty ? address : '—',
                        allowEllipsis: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                BentoCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsRow(
                        icon: Icons.lock_outline_rounded,
                        title: l10n.changePassword,
                        onTap: () => context.push('/change-password'),
                      ),
                      _DividerLine(),
                      _SettingsRow(
                        icon: Icons.settings_outlined,
                        title: l10n.appSettings,
                        onTap: () => context.push('/settings'),
                      ),
                      _DividerLine(),
                      _SettingsRow(
                        icon: Icons.notifications_none_rounded,
                        title: l10n.notifications,
                        onTap: () => context.push('/notifications'),
                      ),
                      _DividerLine(),
                      _SettingsRow(
                        icon: Icons.help_outline_rounded,
                        title: l10n.helpCenter,
                        onTap: () => context.push('/help-center'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    l10n.logout,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatAddress(user) {
    final address = user?.address;
    if (address == null) return '';

    final parts = <String>[];
    if ((address.street ?? '').toString().trim().isNotEmpty) {
      parts.add(address.street.toString().trim());
    }

    final cityLine = [
      (address.postalCode ?? '').toString().trim(),
      (address.city ?? '').toString().trim(),
    ].where((e) => e.isNotEmpty).join(' ');
    if (cityLine.isNotEmpty) parts.add(cityLine);

    final country = (address.country ?? '').toString().trim();
    if (country.isNotEmpty) parts.add(country);

    return parts.join(', ');
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
        color: const Color(0xFF1C1C1E),
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

class _HeaderProfileCard extends StatelessWidget {
  const _HeaderProfileCard({
    required this.name,
    required this.role,
    required this.isVerified,
    required this.avatarRef,
    required this.onEdit,
  });

  final String name;
  final String role;
  final bool isVerified;
  final String? avatarRef;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  UserAvatar(
                    imageRef: avatarRef,
                    name: name,
                    size: 72,
                  ),
                  if (isVerified)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
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
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _RolePill(text: role),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: -6,
            right: -6,
            child: IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, color: Colors.white70),
              tooltip: AppLocalizations.of(context)!.editProfile,
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          height: 1,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.allowEllipsis = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool allowEllipsis;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: allowEllipsis ? TextOverflow.ellipsis : TextOverflow.clip,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
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

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withValues(alpha: 0.06),
    );
  }
}
