import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mongo_image.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class UserAvatar extends ConsumerWidget {
  final String? imageRef; // Can be absolute URL (preferred) or legacy GridFS id
  final String? name;
  final double size;
  final Color? bgColor;
  final Color? textColor;
  final BoxFit fit;
  // When true (default), if imageRef is null we'll fall back to current user's profile image.
  // Set to false when you explicitly want initials instead (e.g., showing another user's avatar in ChatPage).
  final bool fallbackToCurrentUser;

  const UserAvatar({
    super.key,
    this.imageRef,
    this.name,
    this.size = 40,
    this.bgColor,
    this.textColor,
    this.fit = BoxFit.cover,
    this.fallbackToCurrentUser = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentUserProvider);
    final effectiveName = name ?? current?.fullName ?? '';
    // Prefer canonical absolute URL if present on current user
    final currentUrl = current?.profileImageUrl;
    final currentRef = current?.profileImage;
    final effectiveRef =
        imageRef ?? (fallbackToCurrentUser ? (currentUrl ?? currentRef) : null);
    final bg = bgColor ?? Colors.grey.shade200;
    final tc = textColor ?? Colors.grey.shade700;

    Widget child;
  // All image sources (including URLs) are loaded via MongoImage to attach auth headers

    if (effectiveRef != null && effectiveRef.isNotEmpty) {
      child = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.transparent, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: MongoImage(
            imageId: effectiveRef,
            width: size,
            height: size,
            fit: fit,
            errorWidget: _initialsCircle(effectiveName, bg, tc),
          ),
        ),
      );
    } else {
      final initial =
          effectiveName.isNotEmpty ? effectiveName[0].toUpperCase() : 'U';
      child = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(initial,
            style: TextStyle(
                fontSize: size * 0.42, fontWeight: FontWeight.w700, color: tc)),
      );
    }
    return SizedBox(width: size, height: size, child: child);
  }

  Widget _initialsCircle(String name, Color bg, Color tc) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Text(initial,
          style: TextStyle(
              fontSize: size * 0.42, fontWeight: FontWeight.w700, color: tc)),
    );
  }
}
