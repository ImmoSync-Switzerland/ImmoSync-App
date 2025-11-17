import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:immosync/features/documents/domain/services/document_service.dart';
import 'package:immosync/features/documents/domain/models/document_model.dart';

void main() {
  group('Document Persistence Tests', () {
    late DocumentService documentService;

    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      documentService = DocumentService();
    });

    test('Documents should persist after app restart simulation', () async {
      // Initialize the service (this loads sample data)
      final initialDocuments = await documentService.getAllDocuments();
      expect(initialDocuments.isNotEmpty, isTrue);

      // Add a new document
      final newDocument = DocumentModel(
        id: 'test_doc_1',
        name: 'Test Document',
        description: 'This is a test document',
        category: 'lease',
        filePath: '/test/path.pdf',
        fileSize: 1024,
        mimeType: 'application/pdf',
        uploadDate: DateTime.now(),
        assignedTenantIds: ['test_tenant_1'],
        propertyIds: ['test_property_1'],
        uploadedBy: 'test_landlord_1',
        status: 'active',
      );

      await documentService.addDocument(newDocument);

      // Verify document was added
      final documentsBeforeRestart = await documentService.getAllDocuments();
      expect(
          documentsBeforeRestart.any((doc) => doc.id == 'test_doc_1'), isTrue);

      // Simulate app restart by creating a new service instance
      final newService = DocumentService();
      final documentsAfterRestart = await newService.getAllDocuments();

      // Verify document persists after restart
      expect(
          documentsAfterRestart.any((doc) => doc.id == 'test_doc_1'), isTrue);

      final persistedDocument =
          documentsAfterRestart.firstWhere((doc) => doc.id == 'test_doc_1');
      expect(persistedDocument.name, equals('Test Document'));
      expect(persistedDocument.assignedTenantIds, contains('test_tenant_1'));
      expect(persistedDocument.propertyIds, contains('test_property_1'));
    });

    test('Tenant should see documents assigned to their property', () async {
      // Initialize the service
      await documentService.getAllDocuments();

      // Add a document assigned to a property (not directly to tenant)
      final propertyDocument = DocumentModel(
        id: 'property_doc_1',
        name: 'Property-Assigned Document',
        description: 'Document assigned to property only',
        category: 'maintenance',
        filePath: '/property/doc.pdf',
        fileSize: 2048,
        mimeType: 'application/pdf',
        uploadDate: DateTime.now(),
        assignedTenantIds: [], // Not assigned to specific tenant
        propertyIds: ['property_1'], // Assigned to property
        uploadedBy: 'landlord_1',
        status: 'active',
      );

      await documentService.addDocument(propertyDocument);

      // Get documents for a tenant (simulating a tenant in property_1)
      final tenantDocuments =
          await documentService.getDocumentsForTenant('tenant_1');

      // Verify the tenant can see property-assigned documents
      expect(tenantDocuments.any((doc) => doc.id == 'property_doc_1'), isTrue);

      // Verify tenant can see global documents (no property assignment)
      expect(
          tenantDocuments.any((doc) =>
              doc.propertyIds.isEmpty && doc.assignedTenantIds.isEmpty),
          isTrue);
    });

    test('Document assignment should persist', () async {
      // Initialize the service
      await documentService.getAllDocuments();

      // Add a document
      final document = DocumentModel(
        id: 'assign_test_doc',
        name: 'Assignment Test Document',
        description: 'Testing assignment persistence',
        category: 'other',
        filePath: '/assign/test.pdf',
        fileSize: 1024,
        mimeType: 'application/pdf',
        uploadDate: DateTime.now(),
        assignedTenantIds: [],
        propertyIds: [],
        uploadedBy: 'landlord_1',
        status: 'active',
      );

      await documentService.addDocument(document);

      // Assign document to tenants and properties
      await documentService
          .assignDocumentToTenants('assign_test_doc', ['tenant_1', 'tenant_2']);
      await documentService
          .assignDocumentToProperties('assign_test_doc', ['property_1']);

      // Simulate app restart
      final newService = DocumentService();
      final tenantDocuments =
          await newService.getDocumentsForTenant('tenant_1');

      // Verify assignments persisted
      final assignedDocument =
          tenantDocuments.firstWhere((doc) => doc.id == 'assign_test_doc');
      expect(assignedDocument.assignedTenantIds, contains('tenant_1'));
      expect(assignedDocument.assignedTenantIds, contains('tenant_2'));
      expect(assignedDocument.propertyIds, contains('property_1'));
    });
  });
}
