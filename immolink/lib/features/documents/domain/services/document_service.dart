import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/document_model.dart';
import '../../../../core/config/db_config.dart';

class DocumentService {
  static String get _baseUrl => '${DbConfig.apiUrl}/documents';
  static const String _documentsKey = 'stored_documents';
  
  // Mock storage for documents - replace with actual database/storage implementation
  static final List<DocumentModel> _documents = [];
  static bool _isInitialized = false;

  /// Reset initialization state (for testing/debugging)
  static void resetInitialization() {
    _isInitialized = false;
    _documents.clear();
    print('DocumentService: Initialization state reset');
  }

  /// Initialize the service and load persisted documents
  Future<void> _initialize() async {
    print('DocumentService: Initialize called - _isInitialized: $_isInitialized');
    if (_isInitialized) {
      print('DocumentService: Already initialized, current document count: ${_documents.length}');
      return;
    }
    
    print('DocumentService: Initializing...');
    await _loadPersistedDocuments();
    if (_documents.isEmpty) {
      print('DocumentService: No persisted documents found, initializing sample data');
      initializeSampleData();
    } else {
      print('DocumentService: Loaded ${_documents.length} persisted documents');
    }
    _isInitialized = true;
    print('DocumentService: Initialization complete, total documents: ${_documents.length}');
  }

  /// Load documents from SharedPreferences
  Future<void> _loadPersistedDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final documentsJson = prefs.getString(_documentsKey);
      
      print('DocumentService: Loading from SharedPreferences key: $_documentsKey');
      print('DocumentService: Stored JSON length: ${documentsJson?.length ?? 0}');
      
      if (documentsJson != null) {
        final List<dynamic> jsonList = json.decode(documentsJson);
        _documents.clear();
        _documents.addAll(
          jsonList.map((json) => DocumentModel.fromJson(json)).toList()
        );
        print('DocumentService: Successfully loaded ${_documents.length} documents from local storage');
        for (var doc in _documents) {
          print('  - ${doc.name} (${doc.id})');
        }
      } else {
        print('DocumentService: No documents found in SharedPreferences');
      }
    } catch (e) {
      print('DocumentService: Error loading persisted documents: $e');
    }
  }

  /// Save documents to SharedPreferences
  Future<void> _saveDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final documentsJson = json.encode(
        _documents.map((doc) => doc.toJson()).toList()
      );
      await prefs.setString(_documentsKey, documentsJson);
      print('DocumentService: Successfully saved ${_documents.length} documents to local storage');
      print('DocumentService: Saved JSON length: ${documentsJson.length}');
      for (var doc in _documents) {
        print('  - Saved: ${doc.name} (${doc.id})');
      }
    } catch (e) {
      print('DocumentService: Error saving documents: $e');
    }
  }

  /// Get all documents
  Future<List<DocumentModel>> getAllDocuments() async {
    await _initialize();
    
    try {
      print('DocumentService: Fetching all documents from local storage first');
      print('DocumentService: Current local documents count: ${_documents.length}');
      
      // For now, return local documents since there's no general "get all documents" endpoint
      // The backend has landlord-specific and tenant-specific endpoints
      // This method should be used primarily for local/cached documents
      return List.from(_documents);
    } catch (e) {
      print('DocumentService: Error in getAllDocuments: $e');
      return List.from(_documents);
    }
  }

  /// Get documents by category
  Future<List<DocumentModel>> getDocumentsByCategory(String category) async {
    await _initialize();
    await Future.delayed(const Duration(milliseconds: 300));
    return _documents.where((doc) => doc.category == category).toList();
  }

  /// Get documents for a specific tenant
  Future<List<DocumentModel>> getDocumentsForTenant(String tenantId) async {
    await _initialize();
    
    try {
      final response = await http.get(Uri.parse('$_baseUrl/tenant/$tenantId'));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final documents = jsonList.map((json) => DocumentModel.fromJson(json)).toList();
        print('Fetched ${documents.length} documents for tenant $tenantId from API');
        return documents;
      } else {
        print('Failed to fetch tenant documents: ${response.statusCode}');
        // Return documents assigned to this tenant from local storage with property filtering
        return await _getLocalTenantDocuments(tenantId);
      }
    } catch (e) {
      print('Error fetching tenant documents: $e');
      // Return documents assigned to this tenant from local storage with property filtering
      return await _getLocalTenantDocuments(tenantId);
    }
  }

  /// Get tenant documents from local storage with property-based filtering
  Future<List<DocumentModel>> _getLocalTenantDocuments(String tenantId) async {
    // Get tenant's assigned property IDs (this would normally come from user service)
    // For now, we'll check all documents assigned to this tenant or with no specific assignment
    final tenantDocuments = _documents.where((doc) {
      // Document is assigned to this specific tenant
      if (doc.assignedTenantIds.contains(tenantId)) {
        return true;
      }
      
      // Document has no tenant assignment (global documents)
      if (doc.assignedTenantIds.isEmpty) {
        return true;
      }
      
      // Document is assigned to properties that this tenant might be assigned to
      // This is a simplified check - in a real app, you'd fetch the tenant's propertyId
      // and check if any of doc.propertyIds match the tenant's property
      if (doc.propertyIds.isNotEmpty) {
        // For now, we'll include property-assigned documents for all tenants
        // This should be enhanced with actual property-tenant relationship lookup
        return true;
      }
      
      return false;
    }).toList();
    
    print('Returning ${tenantDocuments.length} documents for tenant $tenantId from local storage');
    return tenantDocuments;
  }

  /// Force refresh documents from database (call this on app start)
  Future<void> refreshFromDatabase(String userId, String userRole) async {
    await _initialize();
    
    try {
      print('DocumentService: Refreshing documents from database for user: $userId, role: $userRole');
      
      List<DocumentModel> freshDocuments = [];
      
      if (userRole == 'landlord') {
        freshDocuments = await _fetchLandlordDocumentsFromAPI(userId);
      } else if (userRole == 'tenant') {
        freshDocuments = await _fetchTenantDocumentsFromAPI(userId);
      }
      
      if (freshDocuments.isNotEmpty) {
        print('DocumentService: Loaded ${freshDocuments.length} documents from database');
        _documents.clear();
        _documents.addAll(freshDocuments);
        await _saveDocuments();
        print('DocumentService: Documents synced to local storage');
      } else {
        print('DocumentService: No documents found in database, keeping local documents');
      }
    } catch (e) {
      print('DocumentService: Error refreshing from database: $e');
      print('DocumentService: Keeping existing local documents');
    }
  }

  /// Internal method to fetch landlord documents from API
  Future<List<DocumentModel>> _fetchLandlordDocumentsFromAPI(String landlordId) async {
    final response = await http.get(Uri.parse('$_baseUrl/landlord/$landlordId'));
    
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => DocumentModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch landlord documents: ${response.statusCode}');
    }
  }

  /// Internal method to fetch tenant documents from API
  Future<List<DocumentModel>> _fetchTenantDocumentsFromAPI(String tenantId) async {
    final response = await http.get(Uri.parse('$_baseUrl/tenant/$tenantId'));
    
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => DocumentModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch tenant documents: ${response.statusCode}');
    }
  }

  /// Get documents for a specific landlord
  Future<List<DocumentModel>> getLandlordDocuments(String landlordId) async {
    await _initialize();
    
    try {
      print('DocumentService: Fetching landlord documents from API for landlord: $landlordId');
      final response = await http.get(Uri.parse('$_baseUrl/landlord/$landlordId'));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final apiDocuments = jsonList.map((json) => DocumentModel.fromJson(json)).toList();
        
        print('DocumentService: Successfully fetched ${apiDocuments.length} documents from API');
        
        // Update local storage with landlord documents from API
        // Remove old landlord documents and add fresh ones
        _documents.removeWhere((doc) => doc.uploadedBy == landlordId);
        _documents.addAll(apiDocuments);
        await _saveDocuments();
        
        return apiDocuments;
      } else {
        print('DocumentService: API call failed with status ${response.statusCode}, using local storage');
        return _documents.where((doc) => doc.uploadedBy == landlordId).toList();
      }
    } catch (e) {
      print('DocumentService: Error fetching landlord documents from API: $e');
      // Fallback to local documents
      final localDocs = _documents.where((doc) => doc.uploadedBy == landlordId).toList();
      print('DocumentService: Using local storage (${localDocs.length} documents for landlord)');
      return localDocs;
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
    print('DocumentService: Starting upload to ${_baseUrl}/upload');
    
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
      
      print('DocumentService: Sending request with fields: ${request.fields}');
      print('DocumentService: Request URL: ${request.url}');
      print('DocumentService: File info - Name: ${file.name}, Size: ${file.size}');
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      print('DocumentService: Upload response - Status: ${response.statusCode}');
      print('DocumentService: Upload response - Headers: ${response.headers}');
      print('DocumentService: Upload response - Data: $responseData');
      
      if (response.statusCode == 201) {
        final jsonData = json.decode(responseData);
        final document = DocumentModel.fromJson(jsonData['document']);
        
        print('DocumentService: Document successfully uploaded to database with ID: ${document.id}');
        
        // Also save to local storage for offline access
        await _initialize();
        _documents.add(document);
        await _saveDocuments();
        
        print('DocumentService: Document also saved to local storage');
        return document;
      } else {
        print('DocumentService: Upload failed - Status: ${response.statusCode}, Response: $responseData');
        throw Exception('Failed to upload document: ${response.statusCode} - $responseData');
      }
    } catch (e) {
      print('DocumentService: Upload failed with error: $e');
      print('DocumentService: Falling back to local storage only');
      
      // Fallback to local storage only (this should be temporary until backend is fixed)
      await _initialize();
      await Future.delayed(const Duration(seconds: 1)); // Simulate upload time
      
      final documentId = 'local_${DateTime.now().millisecondsSinceEpoch}';
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
      await _saveDocuments(); // Save to local storage
      return document;
    }
  }

  /// Helper method to get bytes from file path
  Future<Uint8List> _getBytesFromPath(String path) async {
    // This is a placeholder - in a real implementation, you'd read the file
    // For web, file.bytes should be used directly
    return Uint8List(0);
  }

  /// Add a new document (primarily for local/temporary documents)
  /// For file uploads, use uploadDocument() instead
  Future<DocumentModel> addDocument(DocumentModel document) async {
    print('DocumentService: Adding document: ${document.name} (${document.id})');
    await _initialize();
    
    // Note: This method is primarily for local documents since the backend
    // expects documents to be uploaded via the /upload endpoint with actual files
    // Real documents should be created via uploadDocument() method
    
    await Future.delayed(const Duration(milliseconds: 500));
    _documents.add(document);
    print('DocumentService: Document added to local storage, total count: ${_documents.length}');
    await _saveDocuments(); // Save to local storage
    print('DocumentService: Document persisted to local storage successfully');
    
    // TODO: If needed, implement backend API call for metadata-only documents
    
    return document;
  }

  /// Update an existing document
  Future<DocumentModel> updateDocument(DocumentModel document) async {
    await _initialize();
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _documents.indexWhere((doc) => doc.id == document.id);
    if (index != -1) {
      _documents[index] = document;
      await _saveDocuments(); // Save to local storage
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
    await _initialize();
    await Future.delayed(const Duration(milliseconds: 500));
    _documents.removeWhere((doc) => doc.id == documentId);
    await _saveDocuments(); // Save to local storage
  }

  /// Assign document to tenants
  Future<void> assignDocumentToTenants(String documentId, List<String> tenantIds) async {
    await _initialize();
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _documents.indexWhere((doc) => doc.id == documentId);
    if (index != -1) {
      final document = _documents[index];
      final updatedDocument = document.copyWith(assignedTenantIds: tenantIds);
      _documents[index] = updatedDocument;
      await _saveDocuments(); // Save to local storage
    } else {
      throw Exception('Document not found');
    }
  }

  /// Assign document to properties
  Future<void> assignDocumentToProperties(String documentId, List<String> propertyIds) async {
    await _initialize();
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _documents.indexWhere((doc) => doc.id == documentId);
    if (index != -1) {
      final document = _documents[index];
      final updatedDocument = document.copyWith(propertyIds: propertyIds);
      _documents[index] = updatedDocument;
      await _saveDocuments(); // Save to local storage
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
          assignedTenantIds: [], // No specific tenant assignment
          propertyIds: ['property_1', 'property_2'], // Assigned to properties
          uploadedBy: 'landlord_1',
          expiryDate: DateTime.now().add(const Duration(days: 365)),
          status: 'active',
        ),
        DocumentModel(
          id: 'doc_4',
          name: 'Building Safety Guidelines',
          description: 'Important safety information for all tenants',
          category: DocumentCategory.other.id,
          filePath: '/documents/safety_guidelines.pdf',
          fileSize: 750000, // 750KB
          mimeType: 'application/pdf',
          uploadDate: DateTime.now().subtract(const Duration(days: 2)),
          assignedTenantIds: [], // Global document - no specific tenant
          propertyIds: [], // Global document - applies to all properties
          uploadedBy: 'landlord_1',
          status: 'active',
        ),
        DocumentModel(
          id: 'doc_5',
          name: 'Property Insurance Certificate',
          description: 'Insurance coverage details for the property',
          category: DocumentCategory.other.id,
          filePath: '/documents/insurance_certificate.pdf',
          fileSize: 890000, // 890KB
          mimeType: 'application/pdf',
          uploadDate: DateTime.now().subtract(const Duration(days: 7)),
          assignedTenantIds: [], // No specific tenant assignment
          propertyIds: ['property_1'], // Only for property_1
          uploadedBy: 'landlord_1',
          expiryDate: DateTime.now().add(const Duration(days: 365)),
          status: 'active',
        ),
      ];
      
      _documents.addAll(sampleDocs);
      print('Initialized ${sampleDocs.length} sample documents');
    }
  }
}
