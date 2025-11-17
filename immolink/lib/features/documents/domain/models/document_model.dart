import 'package:flutter/material.dart';

class DocumentModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String filePath;
  final String mimeType;
  final int fileSize;
  final DateTime uploadDate;
  final DateTime? lastModified;
  final String uploadedBy;
  final List<String> assignedTenantIds;
  final List<String> propertyIds;
  final Map<String, dynamic>? metadata;
  final String status; // 'active', 'archived', 'draft'
  final bool isRequired;
  final DateTime? expiryDate;

  const DocumentModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.filePath,
    required this.mimeType,
    required this.fileSize,
    required this.uploadDate,
    this.lastModified,
    required this.uploadedBy,
    required this.assignedTenantIds,
    required this.propertyIds,
    this.metadata,
    this.status = 'active',
    this.isRequired = false,
    this.expiryDate,
  });

  DocumentModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? filePath,
    String? mimeType,
    int? fileSize,
    DateTime? uploadDate,
    DateTime? lastModified,
    String? uploadedBy,
    List<String>? assignedTenantIds,
    List<String>? propertyIds,
    Map<String, dynamic>? metadata,
    String? status,
    bool? isRequired,
    DateTime? expiryDate,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      filePath: filePath ?? this.filePath,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      uploadDate: uploadDate ?? this.uploadDate,
      lastModified: lastModified ?? this.lastModified,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      assignedTenantIds: assignedTenantIds ?? this.assignedTenantIds,
      propertyIds: propertyIds ?? this.propertyIds,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      isRequired: isRequired ?? this.isRequired,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'filePath': filePath,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'uploadDate': uploadDate.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'uploadedBy': uploadedBy,
      'assignedTenantIds': assignedTenantIds,
      'propertyIds': propertyIds,
      'metadata': metadata,
      'status': status,
      'isRequired': isRequired,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    // Handle different ID formats from API vs local storage
    String documentId;
    final idField = json['_id'] ?? json['id'];
    if (idField is Map && idField['\$oid'] != null) {
      documentId = idField['\$oid'] as String;
    } else if (idField is String) {
      documentId = idField;
    } else {
      documentId = DateTime.now().millisecondsSinceEpoch.toString();
    }

    // Handle fileSize which might be null or a different type
    int documentFileSize;
    if (json['fileSize'] is int) {
      documentFileSize = json['fileSize'] as int;
    } else if (json['fileSize'] is String) {
      documentFileSize = int.tryParse(json['fileSize'] as String) ?? 0;
    } else {
      documentFileSize = 0;
    }

    // Normalize category
    final rawCategory = (json['category'] as String?) ?? 'Other';
    final normalizedCategory = _normalizeCategory(rawCategory);
    final rawFilePath = (json['filePath'] as String?) ?? '';
    final mime = (json['mimeType'] as String?) ?? 'application/octet-stream';

    // Parse uploadDate flexibly (may be Date string or Date object serialized)
    DateTime parsedUploadDate = DateTime.now();
    final uploadDateVal = json['uploadDate'];
    if (uploadDateVal is String) {
      try {
        parsedUploadDate = DateTime.parse(uploadDateVal);
      } catch (_) {}
    } else if (uploadDateVal is Map && uploadDateVal['\$date'] != null) {
      try {
        parsedUploadDate = DateTime.parse(uploadDateVal['\$date']);
      } catch (_) {}
    }

    // uploadedBy may be missing in legacy docs
    String uploadedBy = '';
    final uploadedByVal = json['uploadedBy'];
    if (uploadedByVal is Map && uploadedByVal['\$oid'] != null) {
      uploadedBy = uploadedByVal['\$oid'];
    } else if (uploadedByVal is String) {
      uploadedBy = uploadedByVal;
    }

    // Helper to coerce lists with ObjectIds / maps / mixed to List<String>
    List<String> _coerceIdList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) {
          if (e is String) return e;
          if (e is Map && e['\$oid'] != null) return e['\$oid'].toString();
          return e.toString();
        }).toList();
      }
      return [];
    }

    final assignedTenantIds = _coerceIdList(json['assignedTenantIds']);
    final propertyIds = _coerceIdList(json['propertyIds']);

    DateTime? expiry;
    if (json['expiryDate'] is String) {
      try {
        expiry = DateTime.parse(json['expiryDate']);
      } catch (_) {}
    } else if (json['expiryDate'] is Map &&
        json['expiryDate']['\$date'] != null) {
      try {
        expiry = DateTime.parse(json['expiryDate']['\$date']);
      } catch (_) {}
    }

    return DocumentModel(
      id: documentId,
      name: json['name'] as String? ?? 'Document',
      description: json['description'] as String? ?? '',
      category: normalizedCategory,
      filePath: rawFilePath,
      mimeType: mime,
      fileSize: documentFileSize,
      uploadDate: parsedUploadDate,
      lastModified: json['lastModified'] is String
          ? DateTime.tryParse(json['lastModified'])
          : null,
      uploadedBy: uploadedBy,
      assignedTenantIds: assignedTenantIds,
      propertyIds: propertyIds,
      metadata: json['metadata'] as Map<String, dynamic>?,
      status: json['status'] as String? ?? 'active',
      isRequired: json['isRequired'] as bool? ?? false,
      expiryDate: expiry,
    );
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String get fileExtension {
    return filePath.split('.').last.toUpperCase();
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate!.difference(now).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }
}

enum DocumentCategory {
  lease('lease', 'Mietvertrag', 'description'),
  utilities('utilities', 'Nebenkosten', 'receipt_long'),
  protocols('protocols', 'Protokolle', 'checklist'),
  correspondence('correspondence', 'Korrespondenz', 'email'),
  insurance('insurance', 'Versicherung', 'security'),
  maintenance('maintenance', 'Wartung', 'build'),
  legal('legal', 'Rechtliches', 'gavel'),
  other('other', 'Sonstiges', 'folder');

  const DocumentCategory(this.id, this.displayName, this.iconName);

  final String id;
  final String displayName;
  final String iconName;

  IconData get icon {
    switch (this) {
      case DocumentCategory.lease:
        return Icons.description;
      case DocumentCategory.utilities:
        return Icons.receipt_long;
      case DocumentCategory.protocols:
        return Icons.checklist;
      case DocumentCategory.correspondence:
        return Icons.email;
      case DocumentCategory.insurance:
        return Icons.security;
      case DocumentCategory.maintenance:
        return Icons.build;
      case DocumentCategory.legal:
        return Icons.gavel;
      case DocumentCategory.other:
        return Icons.folder;
    }
  }
}

// Helper to normalize possibly localized / variant category labels to canonical English keys used in filtering.
String _normalizeCategory(String input) {
  final lower = input.toLowerCase();
  switch (lower) {
    case 'mietvertrag':
    case 'lease agreement':
    case 'lease':
      return 'Lease Agreement';
    case 'nebenkosten':
    case 'utility bills':
    case 'operating costs':
    case 'utilities':
      return 'Operating Costs';
    case 'protokolle':
    case 'inspection reports':
    case 'protocols':
      return 'Inspection Reports';
    case 'korrespondenz':
    case 'correspondence':
      return 'Correspondence';
    case 'versicherung':
    case 'insurance':
      return 'Insurance';
    case 'wartung':
    case 'maintenance':
      return 'Maintenance';
    case 'rechtliches':
    case 'legal':
      return 'Legal Documents';
    case 'sonstiges':
    case 'other':
    default:
      return 'Other';
  }
}
