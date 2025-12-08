import '../../../../core/config/db_config.dart';

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

    String _sanitizeString(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty ||
          trimmed.toLowerCase() == 'null' ||
          trimmed.toLowerCase() == 'undefined') {
        return '';
      }
      if (trimmed == '[encrypted]') {
        return 'Encrypted message';
      }
      return trimmed;
    }

    String _buildPreview(dynamic raw) {
      if (raw == null) return '';
      if (raw is String) {
        return _sanitizeString(raw);
      }
      if (raw is Map) {
        final candidateKeys = <String>[
          'preview',
          'plaintext',
          'plainText',
          'text',
          'body',
          'content',
          'message',
          'lastMessage',
          'snippet',
          'summary',
          'value',
        ];
        for (final key in candidateKeys) {
          final candidate = raw[key];
          if (candidate is String && candidate.trim().isNotEmpty) {
            return _sanitizeString(candidate);
          }
        }

        final messageType = raw['messageType'] ?? raw['type'];
        final metadata = raw['metadata'] is Map
            ? Map<String, dynamic>.from(raw['metadata'])
            : null;

        bool _isImage() {
          if (messageType == 'image') return true;
          if (metadata != null && metadata['fileType'] == 'image') return true;
          return false;
        }

        bool _isFile() {
          if (messageType == 'file' || messageType == 'document') return true;
          if (metadata != null &&
              (metadata['fileType'] == 'file' ||
                  metadata.containsKey('fileName') ||
                  metadata.containsKey('filename'))) {
            return true;
          }
          if (raw.containsKey('fileName') || raw.containsKey('filename')) {
            return true;
          }
          return false;
        }

        if (_isImage()) {
          return '[Photo]';
        }
        if (_isFile()) {
          final fileNameCandidates = <dynamic>[
            if (metadata != null) metadata['fileName'],
            if (metadata != null) metadata['filename'],
            raw['fileName'],
            raw['filename'],
            raw['name'],
            raw['title'],
          ];
          for (final candidate in fileNameCandidates) {
            if (candidate is String && candidate.trim().isNotEmpty) {
              return '[File] ${candidate.trim()}';
            }
          }
          return '[File]';
        }

        for (final entry in raw.entries) {
          final value = entry.value;
          if (value is String && value.trim().isNotEmpty) {
            return _sanitizeString(value);
          }
        }
      }

      if (raw is Iterable) {
        for (final item in raw) {
          final preview = _buildPreview(item);
          if (preview.isNotEmpty) return preview;
        }
        return '';
      }

      return _sanitizeString(raw.toString());
    }

    DateTime? _tryParseTimestamp(dynamic raw) {
      if (raw == null) return null;
      if (raw is DateTime) return raw;
      if (raw is int) {
        final isSeconds = raw < 1000000000000;
        try {
          return DateTime.fromMillisecondsSinceEpoch(
            isSeconds ? raw * 1000 : raw,
            isUtc: true,
          ).toLocal();
        } catch (_) {
          return null;
        }
      }
      if (raw is double) return _tryParseTimestamp(raw.toInt());
      if (raw is String) {
        final sanitized = raw.trim();
        if (sanitized.isEmpty ||
            sanitized.toLowerCase() == 'null' ||
            sanitized.toLowerCase() == 'undefined') {
          return null;
        }
        try {
          return DateTime.parse(sanitized).toLocal();
        } catch (_) {
          // Try parsing as integer timestamp string
          final parsedInt = int.tryParse(sanitized);
          if (parsedInt != null) return _tryParseTimestamp(parsedInt);
          return null;
        }
      }
      if (raw is Map) {
        final dynamic nested = raw[r'$date'] ??
            raw['date'] ??
            raw['timestamp'] ??
            raw['iso'] ??
            raw['value'];
        if (nested != null) return _tryParseTimestamp(nested);
      }
      if (raw is Iterable) {
        for (final item in raw) {
          final ts = _tryParseTimestamp(item);
          if (ts != null) return ts;
        }
      }
      return null;
    }

    DateTime _parseTimestamp(dynamic raw) =>
        _tryParseTimestamp(raw) ?? DateTime.now();

    final lastMessageSource = map.containsKey('lastMessage')
        ? map['lastMessage']
        : (map['lastMessagePreview'] ??
            map['messagePreview'] ??
            map['lastMessageBody'] ??
            map['latestMessage']);

    final lastMessageTimeSource = map['lastMessageTime'] ??
        map['lastMessageAt'] ??
        map['updatedAt'] ??
        map['lastActivityAt'] ??
        map['createdAt'];

    return Conversation(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
      propertyId: map['propertyId'] ?? '',
      landlordId: map['landlordId'] ?? '',
      tenantId: map['tenantId'] ?? '',
      propertyAddress: map['propertyAddress'] ?? 'Unknown Property',
      lastMessage: _buildPreview(lastMessageSource),
      lastMessageTime: _parseTimestamp(lastMessageTimeSource),
      landlordName: map['landlordName'],
      tenantName: map['tenantName'],
      relatedInvitationId: map['relatedInvitationId'],
      otherParticipantId: map['otherParticipantId'],
      otherParticipantName: map['otherParticipantName'],
      otherParticipantEmail: map['otherParticipantEmail'],
      otherParticipantRole: map['otherParticipantRole'],
      otherParticipantAvatar: _asId(map['otherParticipantAvatar'] ??
          map['otherParticipantImage'] ??
          map['profileImage']),
      participants: map['participants'] != null
          ? List<String>.from(map['participants'])
          : null,
      matrixRoomId:
          map['matrixRoomId'] ?? map['matrix_room_id'] ?? map['roomId'],
    );
  }

  // Compute a canonical avatar URL for the other participant to match dashboard logic
  String? getOtherParticipantAvatarUrl() {
    final ref = otherParticipantAvatar;
    // If backend already provided an absolute URL (canonical or provider picture), use it
    if (ref != null &&
        (ref.startsWith('http://') ||
            ref.startsWith('https://') ||
            ref.startsWith('data:'))) {
      return ref;
    }
    // Otherwise, try to compose the canonical inline URL for this user
    if (otherParticipantId != null && otherParticipantId!.isNotEmpty) {
      return '${DbConfig.apiUrl}/users/$otherParticipantId/profile-image';
    }
    return null;
  }

  // Return best available reference for avatar (URL or legacy GridFS id)
  // Preference order: provided absolute URL -> provided legacy id -> composed canonical URL
  String? getOtherParticipantAvatarRef() {
    final ref = otherParticipantAvatar;
    if (ref != null && ref.isNotEmpty) {
      // If it's already a URL or data URI, use as-is
      if (ref.startsWith('http://') ||
          ref.startsWith('https://') ||
          ref.startsWith('data:')) {
        return ref;
      }
      // Otherwise it's likely a legacy GridFS id; let MongoImage handle it
      return ref;
    }
    // Fallback to composed canonical URL
    return getOtherParticipantAvatarUrl();
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

  Conversation copyWith({
    String? id,
    String? propertyId,
    String? landlordId,
    String? tenantId,
    String? propertyAddress,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? landlordName,
    String? tenantName,
    String? relatedInvitationId,
    String? otherParticipantId,
    String? otherParticipantName,
    String? otherParticipantEmail,
    String? otherParticipantRole,
    String? otherParticipantAvatar,
    List<String>? participants,
    String? matrixRoomId,
  }) {
    return Conversation(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      landlordId: landlordId ?? this.landlordId,
      tenantId: tenantId ?? this.tenantId,
      propertyAddress: propertyAddress ?? this.propertyAddress,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      landlordName: landlordName ?? this.landlordName,
      tenantName: tenantName ?? this.tenantName,
      relatedInvitationId: relatedInvitationId ?? this.relatedInvitationId,
      otherParticipantId: otherParticipantId ?? this.otherParticipantId,
      otherParticipantName: otherParticipantName ?? this.otherParticipantName,
      otherParticipantEmail:
          otherParticipantEmail ?? this.otherParticipantEmail,
      otherParticipantRole: otherParticipantRole ?? this.otherParticipantRole,
      otherParticipantAvatar:
          otherParticipantAvatar ?? this.otherParticipantAvatar,
      participants: participants ?? this.participants,
      matrixRoomId: matrixRoomId ?? this.matrixRoomId,
    );
  }
}
