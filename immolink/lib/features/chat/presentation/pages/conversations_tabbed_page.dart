import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/conversations_provider.dart';
import '../providers/invitation_provider.dart';
import '../../domain/models/conversation.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/widgets/common_bottom_nav.dart';
import '../widgets/invitation_card.dart';

class ConversationsTabbedPage extends ConsumerStatefulWidget {
  const ConversationsTabbedPage({super.key});

  @override
  ConsumerState<ConversationsTabbedPage> createState() => _ConversationsTabbedPageState();
}

class _ConversationsTabbedPageState extends ConsumerState<ConversationsTabbedPage> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Set navigation index to Messages (2) when this page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routeAwareNavigationProvider.notifier).setIndex(2);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: false,
        title: Text(
          l10n.messages,
          style: TextStyle(
            color: const Color(0xFF0F172A),
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: const Color(0xFF64748B)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.contacts_outlined, color: const Color(0xFF3B82F6), size: 22),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push('/address-book');
              },
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF3B82F6),
          indicatorWeight: 3,
          labelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
          tabs: [
            Tab(text: l10n.messages),
            Tab(text: 'Invitations'), // TODO: Add to l10n
          ],
        ),
      ),
      bottomNavigationBar: const CommonBottomNav(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMessagesTab(),
                _buildInvitationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: TextStyle(
            color: const Color(0xFF64748B),
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
          ),
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_outlined, 
              color: const Color(0xFF64748B),
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        style: TextStyle(
          color: const Color(0xFF0F172A),
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildMessagesTab() {
    final conversationsAsync = ref.watch(conversationsProvider);
    
    return conversationsAsync.when(
      data: (conversations) {
        final filteredConversations = _filterConversations(conversations);
        if (filteredConversations.isEmpty) {
          return _buildEmptyState('No conversations yet', 'Start chatting with your tenants or landlord');
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filteredConversations.length,
          itemBuilder: (context, index) {
            final conversation = filteredConversations[index];
            final currentUser = ref.watch(currentUserProvider);
            final otherUserId = conversation.getOtherParticipantId(currentUser?.id ?? '');
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildConversationTile(
                context,
                conversation,
                otherUserId ?? '',
                currentUser?.id ?? '',
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            strokeWidth: 2.5,
          ),
        ),
      ),
      error: (error, stack) => _buildErrorState(),
    );
  }

  Widget _buildInvitationsTab() {
    final currentUser = ref.watch(currentUserProvider);
    final invitationsAsync = ref.watch(userInvitationsProvider);
    
    return invitationsAsync.when(
      data: (invitations) {
        // Filter invitations based on user role
        final filteredInvitations = invitations.where((invitation) {
          if (currentUser?.role == 'landlord') {
            return invitation.landlordId == currentUser!.id;
          } else {
            return invitation.tenantId == currentUser!.id;
          }
        }).toList();

        if (filteredInvitations.isEmpty) {
          return _buildEmptyState(
            currentUser?.role == 'landlord' 
              ? 'No invitations sent' 
              : 'No invitations received',
            currentUser?.role == 'landlord'
              ? 'Send invitations to potential tenants'
              : 'Wait for landlord invitations',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filteredInvitations.length,
          itemBuilder: (context, index) {
            final invitation = filteredInvitations[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InvitationCard(
                invitation: invitation,
                isLandlord: currentUser?.role == 'landlord',
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
            strokeWidth: 2.5,
          ),
        ),
      ),
      error: (error, stack) => _buildErrorState(),
    );
  }

  Widget _buildConversationTile(
    BuildContext context, 
    Conversation conversation, 
    String otherUserId, 
    String currentUserId
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(
          '/chat/${conversation.id}?otherUser=${Uri.encodeComponent(conversation.otherParticipantName ?? 'Unknown User')}&otherUserId=$otherUserId',
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.person_outline,
                color: const Color(0xFF3B82F6),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.otherParticipantName ?? 'Unknown User',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _getTimeAgo(conversation.lastMessageTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    conversation.lastMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      letterSpacing: -0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: const Color(0xFFEF4444)),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  List<Conversation> _filterConversations(List<Conversation> conversations) {
    if (_searchQuery.isEmpty) return conversations;
    
    return conversations.where((conversation) {
      final searchInName = conversation.otherParticipantName?.toLowerCase().contains(_searchQuery) ?? false;
      final searchInMessage = conversation.lastMessage.toLowerCase().contains(_searchQuery);
      return searchInName || searchInMessage;
    }).toList();
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
