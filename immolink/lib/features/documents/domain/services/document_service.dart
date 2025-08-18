import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../models/document_model.dart';

class DocumentService {
  static const String _baseUrl = 'http://localhost:3000/api/documents';
  
  // Mock storage for documents - replace with actual database/storage implementation
  static final List<DocumentModel> _documents = [];

  /// Get all documents (deprecated - use getDocumentsForTenant instead)
  @Deprecated('Use getDocumentsForTenant with specific tenant ID instead')
  Future<List<DocumentModel>> getAllDocuments() async {
    try {
      // This method is deprecated and should not be used for tenant-specific data
      // Return empty list to avoid confusion
      print('Warning: getAllDocuments() is deprecated. Use getDocumentsForTenant() instead.');
      return [];
    } catch (e) {
      print('Error in deprecated getAllDocuments: $e');
      return [];
    }
  }

  /// Get documents by category
  Future<List<DocumentModel>> getDocumentsByCategory(String category) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _documents.where((doc) => doc.category == category).toList();
  }

  /// Get documents for a specific tenant
  Future<List<DocumentModel>> getDocumentsForTenant(String tenantId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/tenant/$tenantId'));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => DocumentModel.fromJson(json)).toList();
      } else {
        print('Failed to fetch tenant documents: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching tenant documents: $e');
      return [];
    }
  }

  /// Get documents for a specific landlord
  Future<List<DocumentModel>> getLandlordDocuments(String landlordId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/landlord/$landlordId'));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => DocumentModel.fromJson(json)).toList();
      } else {
        // Fallback to mock data if API fails
        await Future.delayed(const Duration(milliseconds: 300));
        return _documents.where((doc) => doc.uploadedBy == landlordId).toList();
      }
    } catch (e) {
      // Fallback to mock data if API fails
      await Future.delayed(const Duration(milliseconds: 300));
      return _documents.where((doc) => doc.uploadedBy == landlordId).toList();
    }
  }

  /// Upload a document with file
  Future<DocumentModel> uploadDocument({
    required PlatformFile file,
    required String name,
    required String description,
    required String category,
    required String uploadedBy,
    String? propertyId,
    List<String> tenantIds = const [],
    DateTime? expiryDate,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload'));
      
      // Add file
      final bytes = file.bytes ?? await _getBytesFromPath(file.path!);
      request.files.add(http.MultipartFile.fromBytes(
        'document',
        bytes,
        filename: file.name,
      ));
      
      // Add form data
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['category'] = category;
      request.fields['uploadedBy'] = uploadedBy;
      if (propertyId != null) {
        request.fields['propertyIds'] = json.encode([propertyId]);
      }
      if (tenantIds.isNotEmpty) {
        request.fields['assignedTenantIds'] = json.encode(tenantIds);
      }
      if (expiryDate != null) {
        request.fields['expiryDate'] = expiryDate.toIso8601String();
      }
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 201) {
        final jsonData = json.decode(responseData);
        return DocumentModel.fromJson(jsonData['document']);
      } else {
        throw Exception('Failed to upload document: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading document: $e');
      // Fallback to mock behavior for development
      await Future.delayed(const Duration(seconds: 2));
      
      final documentId = 'doc_${DateTime.now().millisecondsSinceEpoch}';
      final document = DocumentModel(
        id: documentId,
        name: name,
        description: description,
        category: category,
        filePath: file.path ?? '',
        fileSize: file.size,
        mimeType: _getMimeType(file.extension ?? ''),
        uploadDate: DateTime.now(),
        assignedTenantIds: tenantIds,
        propertyIds: propertyId != null ? [propertyId] : [],
        uploadedBy: uploadedBy,
        expiryDate: expiryDate,
        status: 'active',
      );
      
      _documents.add(document);
      return document;
    }
  }

  /// Helper method to get bytes from file path
  Future<Uint8List> _getBytesFromPath(String path) async {
    // This is a placeholder - in a real implementation, you'd read the file
    // For web, file.bytes should be used directly
    return Uint8List(0);
  }

  /// Add a new document
  Future<DocumentModel> addDocument(DocumentModel document) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _documents.add(document);
    return document;
  }

  /// Update an existing document
  Future<DocumentModel> updateDocument(DocumentModel document) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _documents.indexWhere((doc) => doc.id == document.id);
    if (index != -1) {
      _documents[index] = document;
      return document;
    }
    throw Exception('Document not found');
  }

  /// Get document counts by category for a tenant
  Future<Map<String, int>> getDocumentCountsByCategory(String tenantId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/tenant/$tenantId'));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final documents = jsonList.map((json) => DocumentModel.fromJson(json)).toList();
        
        final Map<String, int> counts = {};
        final Map<String, String> categoryMapping = {
          'Lease Agreement': 'Mietvertrag',
          'Utility Bills': 'Nebenkosten',
          'Inspection Reports': 'Protokolle',
          'Correspondence': 'Korrespondenz',
          'Other': 'Sonstiges',
        };
        
        for (final doc in documents) {
          final germanCategory = categoryMapping[doc.category] ?? doc.category;
          counts[germanCategory] = (counts[germanCategory] ?? 0) + 1;
        }
        return counts;
      } else {
        return _getMockCategoryCounts();
      }
    } catch (e) {
      print('Error fetching document counts: $e');
      return _getMockCategoryCounts();
    }
  }

  /// Get mock category counts for fallback
  Map<String, int> _getMockCategoryCounts() {
    return {
      'Mietvertrag': 0,
      'Nebenkosten': 0,
      'Protokolle': 0,
      'Korrespondenz': 0,
    };
  }

  /// Delete a document
  Future<void> deleteDocument(String documentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _documents.removeWhere((doc) => doc.id == documentId);
  }

  /// Assign document to tenants
  Future<void> assignDocumentToTenants(String documentId, List<String> tenantIds) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _documents.indexWhere((doc) => doc.id == documentId);
    if (index != -1) {
      final document = _documents[index];
      final updatedDocument = document.copyWith(assignedTenantIds: tenantIds);
      _documents[index] = updatedDocument;
    } else {
      throw Exception('Document not found');
    }
  }

  /// Assign document to properties
  Future<void> assignDocumentToProperties(String documentId, List<String> propertyIds) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _documents.indexWhere((doc) => doc.id == documentId);
    if (index != -1) {
      final document = _documents[index];
      final updatedDocument = document.copyWith(propertyIds: propertyIds);
      _documents[index] = updatedDocument;
    } else {
      throw Exception('Document not found');
    }
  }

  /// Pick and upload a document file
  Future<DocumentModel?> pickAndUploadDocument({
    required String category,
    String? name,
    String? description,
    List<String> assignedTenantIds = const [],
    List<String> propertyIds = const [],
    DateTime? expiryDate,
  }) async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Generate document ID
        final documentId = 'doc_${DateTime.now().millisecondsSinceEpoch}';
        
        // Create document model
        final document = DocumentModel(
          id: documentId,
          name: name ?? file.name,
          description: description ?? '',
          category: category,
          filePath: file.path ?? '',
          fileSize: file.size,
          mimeType: _getMimeType(file.extension ?? ''),
          uploadDate: DateTime.now(),
          assignedTenantIds: assignedTenantIds,
          propertyIds: propertyIds,
          uploadedBy: 'current_user', // Replace with actual user ID
          expiryDate: expiryDate,
          status: 'active',
        );

        // In a real implementation, you would upload the file to storage here
        // For now, we'll just add the document to our mock storage
        await addDocument(document);
        
        return document;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick and upload document: $e');
    }
  }

  /// Download a document
  Future<void> downloadDocument(DocumentModel document) async {
    // In a real implementation, this would download the file from storage
    // For now, we'll just simulate the download
    await Future.delayed(const Duration(seconds: 1));
    // You would typically save the file to the device's downloads folder
    // or open it with an appropriate app
  }

  /// Get document file as bytes (for viewing)
  Future<Uint8List?> getDocumentBytes(DocumentModel document) async {
    // In a real implementation, this would fetch the file bytes from storage
    // For now, return null to indicate file not available
    await Future.delayed(const Duration(milliseconds: 500));
    return null;
  }

  /// Check if document exists
  Future<bool> documentExists(String documentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _documents.any((doc) => doc.id == documentId);
  }

  /// Get document by ID
  Future<DocumentModel?> getDocumentById(String documentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _documents.firstWhere((doc) => doc.id == documentId);
    } catch (e) {
      return null;
    }
  }

  /// Search documents by name or description
  Future<List<DocumentModel>> searchDocuments(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final lowercaseQuery = query.toLowerCase();
    return _documents.where((doc) => 
      doc.name.toLowerCase().contains(lowercaseQuery) ||
      doc.description.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  /// Get documents expiring soon (within next 30 days)
  Future<List<DocumentModel>> getExpiringSoonDocuments() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _documents.where((doc) => doc.isExpiringSoon).toList();
  }

  /// Get expired documents
  Future<List<DocumentModel>> getExpiredDocuments() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _documents.where((doc) => doc.isExpired).toList();
  }

  /// Helper method to get MIME type from file extension
  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  /// Initialize with sample data for testing
  static void initializeSampleData() {
    if (_documents.isEmpty) {
      final sampleDocs = [
        DocumentModel(
          id: 'doc_1',
          name: 'Lease Agreement 2024',
          description: 'Annual lease agreement for Apartment 2A',
          category: DocumentCategory.lease.id,
          filePath: '/documents/lease_agreement_2024.pdf',
          fileSize: 2048576, // 2MB
          mimeType: 'application/pdf',
          uploadDate: DateTime.now().subtract(const Duration(days: 10)),
          assignedTenantIds: ['tenant_1', 'tenant_2'],
          propertyIds: ['property_1'],
          uploadedBy: 'landlord_1',
          status: 'active',
        ),
        DocumentModel(
          id: 'doc_2',
          name: 'Utility Bills - March 2024',
          description: 'Electricity and water bills for March',
          category: DocumentCategory.utilities.id,
          filePath: '/documents/utility_bills_march_2024.pdf',
          fileSize: 512000, // 512KB
          mimeType: 'application/pdf',
          uploadDate: DateTime.now().subtract(const Duration(days: 5)),
          assignedTenantIds: ['tenant_1'],
          propertyIds: ['property_1'],
          uploadedBy: 'landlord_1',
          status: 'active',
        ),
        DocumentModel(
          id: 'doc_3',
          name: 'Maintenance Protocol',
          description: 'HVAC maintenance schedule and procedures',
          category: DocumentCategory.maintenance.id,
          filePath: '/documents/maintenance_protocol.pdf',
          fileSize: 1024000, // 1MB
          mimeType: 'application/pdf',
          uploadDate: DateTime.now().subtract(const Duration(days: 15)),
          assignedTenantIds: [],
          propertyIds: ['property_1', 'property_2'],
          uploadedBy: 'landlord_1',
          expiryDate: DateTime.now().add(const Duration(days: 365)),
          status: 'active',
        ),
      ];
      
      _documents.addAll(sampleDocs);
    }
  }
}
