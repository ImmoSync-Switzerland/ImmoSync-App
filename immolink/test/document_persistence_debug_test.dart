import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/features/documents/domain/services/document_service.dart';
import '../lib/features/documents/domain/models/document_model.dart';

void main() {
  group('Document Persistence Debug Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      DocumentService.resetInitialization();
    });

    test('Document persistence workflow', () async {
      print('\n=== STARTING DOCUMENT PERSISTENCE TEST ===');

      // Step 1: Create a service instance and add a document
      print('\n--- Step 1: Create service and add document ---');
      final service1 = DocumentService();

      final testDocument = DocumentModel(
        id: 'test_persist_doc',
        name: 'Test Persistence Document',
        description: 'Testing document persistence',
        category: 'test',
        filePath: '/test/path.pdf',
        fileSize: 1024,
        mimeType: 'application/pdf',
        uploadDate: DateTime.now(),
        assignedTenantIds: [],
        propertyIds: [],
        uploadedBy: 'test_user',
        status: 'active',
      );

      await service1.addDocument(testDocument);

      // Verify document was added
      final documents1 = await service1.getAllDocuments();
      print('Documents after adding: ${documents1.length}');
      final hasTestDoc1 = documents1.any((doc) => doc.id == 'test_persist_doc');
      print('Test document found after adding: $hasTestDoc1');
      expect(hasTestDoc1, isTrue);

      print(
          '\n--- Step 2: Reset and create new service (simulating app restart) ---');
      DocumentService.resetInitialization();

      final service2 = DocumentService();
      final documents2 = await service2.getAllDocuments();
      print('Documents after restart simulation: ${documents2.length}');
      final hasTestDoc2 = documents2.any((doc) => doc.id == 'test_persist_doc');
      print('Test document found after restart: $hasTestDoc2');

      // This should pass if persistence is working
      expect(hasTestDoc2, isTrue,
          reason: 'Document should persist after app restart simulation');

      print('\n=== DOCUMENT PERSISTENCE TEST COMPLETE ===\n');
    });
  });
}
