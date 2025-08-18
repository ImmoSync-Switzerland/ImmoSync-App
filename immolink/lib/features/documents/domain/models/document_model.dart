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
    String _parseId(dynamic value) {
      if (value is String) return value;
      if (value is Map) {
        final dynamic oid = value['\$oid'];
        if (oid is String) return oid;
      }
      return value?.toString() ?? '';
    }

    int _parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
      return 0;
    }

    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (value is DateTime) return value;
      if (value is String) {
        final dt = DateTime.tryParse(value);
        if (dt != null) return dt;
      }
      if (value is int) {
        try { return DateTime.fromMillisecondsSinceEpoch(value); } catch (_) {}
      }
      if (value is Map) {
        final dynamic dateVal = value['\$date'];
        if (dateVal is String) {
          final dt = DateTime.tryParse(dateVal);
          if (dt != null) return dt;
        }
        if (dateVal is int) {
          try { return DateTime.fromMillisecondsSinceEpoch(dateVal); } catch (_) {}
        }
      }
      // Fallback
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    DateTime? _parseNullableDate(dynamic value) {
      if (value == null) return null;
      final dt = _parseDate(value);
      // Treat epoch 0 fallback as null when original was non-null but unparsable
      return dt.millisecondsSinceEpoch == 0 && value is! int ? null : dt;
    }

    List<String> _parseIdList(dynamic value) {
      final list = <String>[];
      if (value is List) {
        for (final e in value) {
          list.add(_parseId(e));
        }
      }
      return list;
    }

    return DocumentModel(
      id: _parseId(json['_id'] ?? json['id']),
      name: (json['name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      category: (json['category'] ?? 'other') as String,
      filePath: (json['filePath'] ?? '') as String,
      mimeType: (json['mimeType'] ?? 'application/octet-stream') as String,
      fileSize: _parseInt(json['fileSize']),
      uploadDate: _parseDate(json['uploadDate']),
      lastModified: _parseNullableDate(json['lastModified']),
      uploadedBy: (json['uploadedBy'] ?? '') as String,
      assignedTenantIds: _parseIdList(json['assignedTenantIds'] ?? const []),
      propertyIds: _parseIdList(json['propertyIds'] ?? const []),
      metadata: json['metadata'] is Map<String, dynamic> ? json['metadata'] as Map<String, dynamic> : null,
      status: (json['status'] ?? 'active') as String,
      isRequired: (json['isRequired'] ?? false) as bool,
      expiryDate: _parseNullableDate(json['expiryDate']),
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
