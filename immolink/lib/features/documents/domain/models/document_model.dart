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
    return DocumentModel(
      id: json['_id']?['\$oid'] ?? json['_id'] ?? json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      filePath: json['filePath'] as String,
      mimeType: json['mimeType'] as String,
      fileSize: json['fileSize'] as int,
      uploadDate: DateTime.parse(json['uploadDate'] as String),
      lastModified: json['lastModified'] != null 
          ? DateTime.parse(json['lastModified'] as String) 
          : null,
      uploadedBy: json['uploadedBy'] as String,
      assignedTenantIds: List<String>.from(json['assignedTenantIds'] as List? ?? []),
      propertyIds: List<String>.from(json['propertyIds'] as List? ?? []),
      metadata: json['metadata'] as Map<String, dynamic>?,
      status: json['status'] as String? ?? 'active',
      isRequired: json['isRequired'] as bool? ?? false,
      expiryDate: json['expiryDate'] != null 
          ? DateTime.parse(json['expiryDate'] as String) 
          : null,
    );
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
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
