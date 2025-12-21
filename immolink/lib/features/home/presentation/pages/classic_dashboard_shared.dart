import 'package:flutter/material.dart';

/// Shared widgets for the revamped classic dashboard design used
/// by landlord and tenant roles.
class ClassicGreetingCard extends StatelessWidget {
  const ClassicGreetingCard({
    required this.name,
    required this.headline,
    required this.buttonLabel,
    required this.onTap,
    super.key,
  });

  final String name;
  final String headline;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.handshake_rounded,
              color: Color(0xFF4A67FF),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        buttonLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF377BFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Color(0xFF377BFF),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ClassicSearchField extends StatelessWidget {
  const ClassicSearchField({
    required this.hint,
    super.key,
  });

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: InputDecoration(
          icon: const Icon(Icons.search_rounded, color: Color(0xFF7D8FAB)),
          border: InputBorder.none,
          hintText: hint,
        ),
      ),
    );
  }
}

class ClassicGradientCard extends StatelessWidget {
  const ClassicGradientCard({
    required this.colors,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
    super.key,
  });

  final List<Color> colors;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adjustedColors = colors.map((color) {
      final hsl = HSLColor.fromColor(color);
      final num clampedLightness = (hsl.lightness * 0.7).clamp(0.0, 0.7);
      return hsl.withLightness(clampedLightness.toDouble()).toColor();
    }).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: adjustedColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: adjustedColors.last.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class ClassicMetricChip extends StatelessWidget {
  const ClassicMetricChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final Color background = Colors.white.withValues(alpha: 0.18);
    final Color borderColor = Colors.white.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ],
      ),
    );
  }
}

class ClassicQuickActionButton extends StatelessWidget {
  const ClassicQuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClassicListTile extends StatelessWidget {
  const ClassicListTile({
    required this.leadingIcon,
    required this.leadingColor,
    required this.title,
    required this.subtitle,
    this.trailingBadgeLabel,
    this.trailingBadgeColor,
    this.trailingSecondaryText,
    required this.onTap,
    super.key,
  });

  final IconData leadingIcon;
  final Color leadingColor;
  final String title;
  final String subtitle;
  final String? trailingBadgeLabel;
  final Color? trailingBadgeColor;
  final String? trailingSecondaryText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(leadingIcon, color: leadingColor),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (trailingBadgeLabel != null && trailingBadgeColor != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: trailingBadgeColor!.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trailingBadgeLabel!,
                  style: TextStyle(
                    color: trailingBadgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (trailingSecondaryText != null) ...[
              const SizedBox(height: 6),
              Text(
                trailingSecondaryText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ClassicActionTextButton extends StatelessWidget {
  const ClassicActionTextButton({
    required this.label,
    required this.onTap,
    super.key,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
