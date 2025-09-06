class MaintenanceRequest {
  final String id;
  final String propertyId;
  final String tenantId;
  final String landlordId;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final String location;
  final List<String> images;
  final DateTime requestedDate;
  final DateTime? scheduledDate;
  final DateTime? completedDate;
  final int urgencyLevel;
  final MaintenanceCost? cost;
  final ContractorInfo? contractorInfo;
  final List<MaintenanceNote> notes;

  // Populated fields
  final PropertyAddress? propertyAddress;
  final String? tenantName;
  final String? tenantEmail;
  final String? landlordName;
  final String? landlordEmail;

  const MaintenanceRequest({
    required this.id,
    required this.propertyId,
    required this.tenantId,
    required this.landlordId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.location,
    this.images = const [],
    required this.requestedDate,
    this.scheduledDate,
    this.completedDate,
    this.urgencyLevel = 3,
    this.cost,
    this.contractorInfo,
    this.notes = const [],
    this.propertyAddress,
    this.tenantName,
    this.tenantEmail,
    this.landlordName,
    this.landlordEmail,
  });

  factory MaintenanceRequest.fromMap(Map<String, dynamic> map) {
    return MaintenanceRequest(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '',
      propertyId: map['propertyId']?.toString() ?? '',
      tenantId: map['tenantId']?.toString() ?? '',
      landlordId: map['landlordId']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'other',
      priority: map['priority'] ?? 'medium',
      status: map['status'] ?? 'pending',
      location: map['location'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      requestedDate: map['requestedDate'] != null
          ? DateTime.parse(map['requestedDate'])
          : (map['createdAt'] != null
              ? DateTime.parse(map['createdAt'])
              : (map['dateCreated'] != null
                  ? DateTime.parse(map['dateCreated'])
                  : DateTime.now())),
      scheduledDate: map['scheduledDate'] != null
          ? DateTime.parse(map['scheduledDate'])
          : null,
      completedDate: map['completedDate'] != null
          ? DateTime.parse(map['completedDate'])
          : (map['dateResolved'] != null
              ? DateTime.parse(map['dateResolved'])
              : null),
      urgencyLevel: map['urgencyLevel'] ?? 3,
      cost: map['cost'] != null ? MaintenanceCost.fromMap(map['cost']) : null,
      contractorInfo: map['contractorInfo'] != null
          ? ContractorInfo.fromMap(map['contractorInfo'])
          : null,
      notes: map['notes'] != null
          ? List<MaintenanceNote>.from(
              map['notes'].map((note) => MaintenanceNote.fromMap(note)))
          : [],
      // Handle populated fields
      propertyAddress: map['propertyId'] is Map
          ? PropertyAddress.fromMap(map['propertyId']['address'] ?? {})
          : null,
      tenantName: map['tenantId'] is Map ? map['tenantId']['fullName'] : null,
      tenantEmail: map['tenantId'] is Map ? map['tenantId']['email'] : null,
      landlordName:
          map['landlordId'] is Map ? map['landlordId']['fullName'] : null,
      landlordEmail:
          map['landlordId'] is Map ? map['landlordId']['email'] : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'propertyId': propertyId,
      'tenantId': tenantId,
      'landlordId': landlordId,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'location': location,
      'images': images,
      'requestedDate': requestedDate.toIso8601String(),
      'scheduledDate': scheduledDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'urgencyLevel': urgencyLevel,
      'cost': cost?.toMap(),
      'contractorInfo': contractorInfo?.toMap(),
      'notes': notes.map((note) => note.toMap()).toList(),
    };
  }

  String get priorityDisplayText {
    switch (priority) {
      case 'low':
        return 'Low Priority';
      case 'medium':
        return 'Medium Priority';
      case 'high':
        return 'High Priority';
      case 'urgent':
        return 'Urgent';
      default:
        return 'Medium Priority';
    }
  }

  // Getter methods for backward compatibility
  DateTime get createdAt => requestedDate;
  DateTime? get updatedAt => completedDate ?? scheduledDate;

  String get statusDisplayText {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  String get categoryDisplayText {
    switch (category) {
      case 'plumbing':
        return 'Plumbing';
      case 'electrical':
        return 'Electrical';
      case 'heating':
        return 'Heating';
      case 'cooling':
        return 'Cooling';
      case 'appliances':
        return 'Appliances';
      case 'structural':
        return 'Structural';
      case 'cleaning':
        return 'Cleaning';
      case 'pest_control':
        return 'Pest Control';
      case 'other':
        return 'Other';
      default:
        return 'Other';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(requestedDate);

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

  // Backward compatibility getters for legacy code
  DateTime get dateCreated => requestedDate;
  DateTime? get dateResolved => completedDate;
  String? get assignedTo => contractorInfo?.name;
}

class MaintenanceCost {
  final double? estimated;
  final double? actual;

  const MaintenanceCost({
    this.estimated,
    this.actual,
  });

  factory MaintenanceCost.fromMap(Map<String, dynamic> map) {
    return MaintenanceCost(
      estimated: map['estimated']?.toDouble(),
      actual: map['actual']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'estimated': estimated,
      'actual': actual,
    };
  }
}

class ContractorInfo {
  final String? name;
  final String? contact;
  final String? company;

  const ContractorInfo({
    this.name,
    this.contact,
    this.company,
  });

  factory ContractorInfo.fromMap(Map<String, dynamic> map) {
    return ContractorInfo(
      name: map['name'],
      contact: map['contact'],
      company: map['company'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'contact': contact,
      'company': company,
    };
  }
}

class MaintenanceNote {
  final String author;
  final String content;
  final DateTime timestamp;
  final String? authorName;

  const MaintenanceNote({
    required this.author,
    required this.content,
    required this.timestamp,
    this.authorName,
  });

  factory MaintenanceNote.fromMap(Map<String, dynamic> map) {
    return MaintenanceNote(
      author: map['author']?.toString() ?? '',
      content: map['content'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      authorName: map['authorName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'author': author,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class PropertyAddress {
  final String street;
  final String city;
  final String postalCode;
  final String country;

  const PropertyAddress({
    required this.street,
    required this.city,
    required this.postalCode,
    required this.country,
  });

  factory PropertyAddress.fromMap(Map<String, dynamic> map) {
    return PropertyAddress(
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? '',
    );
  }

  @override
  String toString() {
    return '$street, $city $postalCode';
  }
}
