import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:immosync/core/theme/app_typography.dart';

import 'package:immosync/core/widgets/glass_nav_bar.dart';
import 'package:immosync/core/widgets/user_avatar.dart';
import 'package:immosync/features/auth/presentation/providers/auth_provider.dart';
import 'package:immosync/features/chat/domain/models/conversation.dart';
import 'package:immosync/features/chat/domain/models/invitation.dart';
import 'package:immosync/features/chat/presentation/providers/chat_preview_provider.dart';
import 'package:immosync/features/chat/presentation/providers/conversations_provider.dart';
import 'package:immosync/features/chat/presentation/providers/invitation_provider.dart';

const _segmentMessages = 'messages';
const _segmentInvitations = 'invitations';

const _titleMessages = 'Messages';
const _titleInvitations = 'Invitations';
const _searchHint = 'Search conversations';
const _labelAllMessages = 'All Messages';
const _labelInvitations = 'Invitations';
const _labelApplicationFor = 'Application for';
const _labelAccept = 'Accept';
const _labelDecline = 'Decline';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  String _tab = _segmentMessages;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final conversationsAsync = ref.watch(conversationsProvider);
    final invitationsAsync = ref.watch(userInvitationsProvider);
    final previews = ref.watch(chatPreviewProvider);
    final invitationAction = ref.watch(invitationNotifierProvider);

    final isMessages = _tab == _segmentMessages;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const AppGlassNavBar(),
      body: Stack(
        children: [
          const _MessagesBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Header(),
                  const SizedBox(height: 14),
                  _SearchBar(controller: _searchController),
                  const SizedBox(height: 16),
                  _TabSwitcher(
                    activeTab: _tab,
                    onChanged: (value) => setState(() => _tab = value),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      child: isMessages
                          ? _MessagesList(
                              conversationsAsync: conversationsAsync,
                              previews: previews,
                              currentUserId: currentUser?.id,
                              searchQuery: _searchQuery,
                              onTapConversation: (
                                conversation,
                                displayName,
                                otherUserId,
                                avatarUrl,
                              ) {
                                final encodedName =
                                    Uri.encodeComponent(displayName);
                                final encodedAvatar = avatarUrl != null
                                    ? Uri.encodeComponent(avatarUrl)
                                    : null;
                                final otherUserParam = otherUserId != null
                                    ? '&otherUserId=$otherUserId'
                                    : '';
                                final avatarParam = encodedAvatar != null
                                    ? '&otherAvatar=$encodedAvatar'
                                    : '';
                                if (!mounted) return;
                                context.push(
                                  '/chat/${conversation.id}?otherUser=$encodedName$otherUserParam$avatarParam',
                                );
                              },
                            )
                          : _InvitationsList(
                              invitationsAsync: invitationsAsync,
                              actionState: invitationAction,
                              currentUserId: currentUser?.id,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          _titleMessages,
          style: AppTypography.pageTitle.copyWith(color: Colors.white),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            _titleInvitations,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
        ),
      ],
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({required this.activeTab, required this.onChanged});

  final String activeTab;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1629),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _TabButton(
            label: _labelAllMessages,
            value: _segmentMessages,
            groupValue: activeTab,
            onSelected: onChanged,
          ),
          _TabButton(
            label: _labelInvitations,
            value: _segmentInvitations,
            groupValue: activeTab,
            onSelected: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final isActive = value == groupValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            border: Border.all(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.04),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF7C9CFF).withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: isActive ? 1 : 0.8),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({this.controller});

  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        gradient: const LinearGradient(
          colors: [Color(0xFF11182B), Color(0xFF0D1320)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: TextField(
        controller: controller,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: _searchHint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.64)),
          prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 20),
          filled: false,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.14), width: 1.2),
          ),
        ),
      ),
    );
  }
}

class _MessagesList extends ConsumerWidget {
  const _MessagesList({
    required this.conversationsAsync,
    required this.previews,
    required this.currentUserId,
    required this.searchQuery,
    required this.onTapConversation,
  });

  final AsyncValue<List<Conversation>> conversationsAsync;
  final Map<String, String> previews;
  final String? currentUserId;
  final String searchQuery;
  final void Function(
    Conversation conversation,
    String displayName,
    String? otherUserId,
    String? avatarUrl,
  ) onTapConversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return conversationsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Failed to load conversations',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ),
      ),
      data: (conversations) {
        final filtered =
            _filterConversations(conversations, searchQuery, currentUserId);
        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                'No conversations yet',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final conversation = filtered[index];
            final displayName =
                _resolveDisplayName(conversation, currentUserId);
            final otherUserId =
                _resolveOtherUserId(conversation, currentUserId);
            final avatarRef = conversation.getOtherParticipantAvatarRef();
            final lastMessage =
                previews[conversation.id]?.trim().isNotEmpty == true
                    ? previews[conversation.id]!
                    : conversation.lastMessage;

            if (currentUserId != null && otherUserId != null) {
              ref.read(chatPreviewProvider.notifier).ensureWatching(
                    conversationId: conversation.id,
                    currentUserId: currentUserId!,
                    otherUserId: otherUserId,
                    fallbackPreview: conversation.lastMessage,
                  );
            }

            return Padding(
              padding: EdgeInsets.only(
                  bottom: index == filtered.length - 1 ? 0 : 12),
              child: _ConversationCard(
                title: displayName,
                message: lastMessage.isNotEmpty
                    ? lastMessage
                    : 'Start the conversation',
                timeLabel: _formatRelativeTime(conversation.lastMessageTime),
                unreadCount: 0,
                isOnline: false,
                avatarRef: avatarRef,
                displayName: displayName,
                onTap: () => onTapConversation(
                    conversation, displayName, otherUserId, avatarRef),
              ),
            );
          },
        );
      },
    );
  }
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.unreadCount,
    required this.isOnline,
    required this.avatarRef,
    required this.displayName,
    required this.onTap,
  });

  final String title;
  final String message;
  final String timeLabel;
  final int unreadCount;
  final bool isOnline;
  final String? avatarRef;
  final String displayName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: _bentoCardDecoration(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _Avatar(
                imageRef: avatarRef,
                displayName: displayName,
                isOnline: isOnline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.74),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF60A5FA),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvitationsList extends ConsumerWidget {
  const _InvitationsList({
    required this.invitationsAsync,
    required this.actionState,
    required this.currentUserId,
  });

  final AsyncValue<List<Invitation>> invitationsAsync;
  final AsyncValue<void> actionState;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return invitationsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Failed to load invitations',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ),
      ),
      data: (invitations) {
        if (invitations.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                'No invitations',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: invitations.length,
          itemBuilder: (context, index) {
            final invitation = invitations[index];
            final isSender =
                currentUserId != null && invitation.landlordId == currentUserId;
            final canRespond = !isSender && invitation.isPending;
            final statusLabel = invitation.status.isNotEmpty
                ? invitation.status[0].toUpperCase() +
                    invitation.status.substring(1)
                : 'Pending';
            return Padding(
              padding: EdgeInsets.only(
                  bottom: index == invitations.length - 1 ? 0 : 12),
              child: _InvitationCard(
                invitation: invitation,
                isBusy: actionState is AsyncLoading,
                canRespond: canRespond,
                statusLabel: statusLabel,
                directionLabel: isSender ? 'Sent to' : 'From',
                onAccept: canRespond
                    ? () async {
                        await ref
                            .read(invitationNotifierProvider.notifier)
                            .acceptInvitation(invitation.id);
                        ref.invalidate(userInvitationsProvider);
                      }
                    : null,
                onDecline: canRespond
                    ? () async {
                        await ref
                            .read(invitationNotifierProvider.notifier)
                            .declineInvitation(invitation.id);
                        ref.invalidate(userInvitationsProvider);
                      }
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.isBusy,
    required this.canRespond,
    required this.statusLabel,
    required this.directionLabel,
    required this.onAccept,
    required this.onDecline,
  });

  final Invitation invitation;
  final bool isBusy;
  final bool canRespond;
  final String statusLabel;
  final String directionLabel;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _bentoCardDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          _InvitationAvatar(
            propertyName: invitation.propertyAddress ?? invitation.propertyId,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_labelApplicationFor ${invitation.propertyAddress ?? invitation.propertyId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$directionLabel ${invitation.tenantName ?? invitation.tenantEmail ?? 'Applicant'} - $statusLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRelativeTime(invitation.createdAt),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (canRespond) ...[
                _PillButton(
                  label: _labelAccept,
                  background: const Color(0xFF6DD3FF),
                  foreground: const Color(0xFF0A0E1A),
                  onTap: isBusy ? null : onAccept,
                ),
                const SizedBox(height: 8),
                _PillButton(
                  label: _labelDecline,
                  background: Colors.white.withValues(alpha: 0.08),
                  foreground: Colors.white,
                  onTap: isBusy ? null : onDecline,
                ),
              ] else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

List<Conversation> _filterConversations(
  List<Conversation> conversations,
  String query,
  String? currentUserId,
) {
  if (query.isEmpty) return conversations;
  final lower = query.toLowerCase();
  return conversations.where((conversation) {
    final nameMatches = (_resolveDisplayName(conversation, currentUserId))
        .toLowerCase()
        .contains(lower);
    final messageMatches =
        conversation.lastMessage.toLowerCase().contains(lower);
    return nameMatches || messageMatches;
  }).toList();
}

String _resolveDisplayName(Conversation conversation, String? currentUserId) {
  if (conversation.otherParticipantName != null &&
      conversation.otherParticipantName!.isNotEmpty) {
    return conversation.otherParticipantName!;
  }
  if (currentUserId != null && currentUserId == conversation.landlordId) {
    return conversation.tenantName?.isNotEmpty == true
        ? conversation.tenantName!
        : conversation.otherParticipantEmail ?? 'Tenant';
  }
  if (currentUserId != null && currentUserId == conversation.tenantId) {
    return conversation.landlordName?.isNotEmpty == true
        ? conversation.landlordName!
        : conversation.otherParticipantEmail ?? 'Landlord';
  }
  return conversation.otherParticipantName ??
      conversation.landlordName ??
      conversation.tenantName ??
      conversation.otherParticipantEmail ??
      'Conversation';
}

String? _resolveOtherUserId(Conversation conversation, String? currentUserId) {
  if (conversation.otherParticipantId != null &&
      conversation.otherParticipantId!.isNotEmpty) {
    return conversation.otherParticipantId;
  }
  if (currentUserId != null && currentUserId == conversation.landlordId) {
    return conversation.tenantId.isNotEmpty
        ? conversation.tenantId
        : conversation.otherParticipantId;
  }
  if (currentUserId != null && currentUserId == conversation.tenantId) {
    return conversation.landlordId.isNotEmpty
        ? conversation.landlordId
        : conversation.otherParticipantId;
  }
  return conversation.otherParticipantId;
}

String _formatRelativeTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inDays >= 7) {
    final month = _twoDigits(time.month);
    final day = _twoDigits(time.day);
    return '$day.$month';
  }
  if (diff.inDays >= 1) return '${diff.inDays}d ago';
  if (diff.inHours >= 1) return '${diff.inHours}h ago';
  if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
  return 'Now';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

Decoration _bentoCardDecoration() {
  return BoxDecoration(
    color: const Color(0xFF1C1C1E),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 18,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: const Color(0xFF60A5FA).withValues(alpha: 0.08),
        blurRadius: 28,
        offset: const Offset(0, 16),
      ),
    ],
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar(
      {required this.imageRef,
      required this.displayName,
      required this.isOnline});

  final String? imageRef;
  final String displayName;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        UserAvatar(
          imageRef: imageRef,
          name: displayName,
          size: 48,
          fallbackToCurrentUser: false,
        ),
        if (isOnline)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF4ADE80),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0A1128), width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _InvitationAvatar extends StatelessWidget {
  const _InvitationAvatar({required this.propertyName});

  final String propertyName;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFF93C5FD),
      child: Text(
        propertyName.isNotEmpty ? propertyName[0] : '?',
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onTap == null ? 0.6 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessagesBackground extends StatelessWidget {
  const _MessagesBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A1128),
                Colors.black,
              ],
            ),
          ),
        ),
        const _GlowBlob(
          color: Color(0xFF4F46E5),
          size: 340,
          alignment: Alignment(-0.8, -0.6),
          opacity: 0.22,
        ),
        const _GlowBlob(
          color: Color(0xFF0EA5E9),
          size: 300,
          alignment: Alignment(0.85, -0.15),
          opacity: 0.16,
        ),
        const _GlowBlob(
          color: Color(0xFFF97316),
          size: 420,
          alignment: Alignment(-0.4, 0.85),
          opacity: 0.12,
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: const SizedBox(),
          ),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.color,
    required this.size,
    required this.alignment,
    this.opacity = 0.16,
  });

  final Color color;
  final double size;
  final Alignment alignment;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0.02),
              Colors.transparent,
            ],
            stops: const [0, 0.45, 1],
          ),
        ),
      ),
    );
  }
}
