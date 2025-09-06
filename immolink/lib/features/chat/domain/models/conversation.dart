class Conversation {
  final String id;
  final String propertyId;
  final String landlordId;
  final String tenantId;
  final String propertyAddress;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String? landlordName;
  final String? tenantName;
  final String? relatedInvitationId;
  final String? otherParticipantId;
  final String? otherParticipantName;
  final String? otherParticipantEmail;
  final String? otherParticipantRole;
  final String? otherParticipantAvatar; // GridFS id or URL
  final List<String>? participants;
  final String? matrixRoomId;

  Conversation({
    required this.id,
    required this.propertyId,
    required this.landlordId,
    required this.tenantId,
    required this.propertyAddress,
    required this.lastMessage,
    required this.lastMessageTime,
    this.landlordName,
    this.tenantName,
    this.relatedInvitationId,
    this.otherParticipantId,
    this.otherParticipantName,
    this.otherParticipantEmail,
    this.otherParticipantRole,
  this.otherParticipantAvatar,
    this.participants,
  this.matrixRoomId,
  });
  factory Conversation.fromMap(Map<String, dynamic> map) {
    String? _asId(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      if (v is Map) {
        if (v['\$oid'] != null) return v['\$oid'].toString();
        if (v['oid'] != null) return v['oid'].toString();
        if (v['_id'] != null) return v['_id'].toString();
        if (v['id'] != null) return v['id'].toString();
      }
      // Fallback: toString, but avoid meaningless [object Object]
      final s = v.toString();
      return s == 'Instance of \"_Map\"' || s == '[object Object]' ? null : s;
    }
    return Conversation(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
      propertyId: map['propertyId'] ?? '',
      landlordId: map['landlordId'] ?? '',
      tenantId: map['tenantId'] ?? '',
      propertyAddress: map['propertyAddress'] ?? 'Unknown Property',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.parse(map['lastMessageTime'])
          : DateTime.now(),
      landlordName: map['landlordName'],
      tenantName: map['tenantName'],
      relatedInvitationId: map['relatedInvitationId'],
      otherParticipantId: map['otherParticipantId'],
      otherParticipantName: map['otherParticipantName'],
      otherParticipantEmail: map['otherParticipantEmail'],
      otherParticipantRole: map['otherParticipantRole'],
      otherParticipantAvatar: _asId(
        map['otherParticipantAvatar'] ?? map['otherParticipantImage'] ?? map['profileImage']
      ),
      participants: map['participants'] != null
          ? List<String>.from(map['participants'])
          : null,
  matrixRoomId: map['matrixRoomId'] ?? map['matrix_room_id'] ?? map['roomId'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'landlordId': landlordId,
      'tenantId': tenantId,
      'propertyAddress': propertyAddress,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'landlordName': landlordName,
      'tenantName': tenantName,
      'relatedInvitationId': relatedInvitationId,
      'otherParticipantId': otherParticipantId,
      'otherParticipantName': otherParticipantName,
      'otherParticipantEmail': otherParticipantEmail,
      'otherParticipantRole': otherParticipantRole,
  'otherParticipantAvatar': otherParticipantAvatar,
      'participants': participants,
  'matrixRoomId': matrixRoomId,
    };
  }

  // Helper method to get the display name for the other participant
  String getOtherParticipantDisplayName(String currentUserId,
      {bool isLandlord = false}) {
    // First try the new API format (otherParticipantName)
    if (otherParticipantName != null && otherParticipantName!.isNotEmpty) {
      return otherParticipantName!;
    }

    // Fallback to old format (landlordName/tenantName)
    if (isLandlord) {
      return tenantName ?? 'Tenant';
    } else {
      return landlordName ?? 'Landlord';
    }
  }

  // Helper method to get the other participant's ID
  String? getOtherParticipantId(String currentUserId) {
    // First try the new API format
    if (otherParticipantId != null) {
      return otherParticipantId;
    }

    // Fallback to participants array
    if (participants != null && participants!.length >= 2) {
      return participants!.firstWhere(
        (id) => id != currentUserId,
        orElse: () => participants!.first,
      );
    }

    // Final fallback to landlord/tenant IDs
    return currentUserId == landlordId ? tenantId : landlordId;
  }

  @override
  String toString() {
    return 'Conversation(id: $id, propertyAddress: $propertyAddress, lastMessage: $lastMessage)';
  }
}
