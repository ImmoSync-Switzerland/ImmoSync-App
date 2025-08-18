import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/document_model.dart';
import '../../domain/services/document_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// Document service provider
final documentServiceProvider = Provider<DocumentService>((ref) {
  return DocumentService();
});

// All documents provider
final documentsProvider = StateNotifierProvider<DocumentsNotifier, AsyncValue<List<DocumentModel>>>((ref) {
  final authState = ref.watch(authProvider);
  return DocumentsNotifier(ref.watch(documentServiceProvider), tenantId: authState.userId);
});

// Landlord documents provider (for documents uploaded by the current landlord)
final landlordDocumentsProvider = StateNotifierProvider<LandlordDocumentsNotifier, AsyncValue<List<DocumentModel>>>((ref) {
  return LandlordDocumentsNotifier(ref.watch(documentServiceProvider), ref.watch(currentUserProvider));
});

// Tenant documents provider (for documents visible to current tenant)
final tenantDocumentsProvider = StateNotifierProvider<TenantDocumentsNotifier, AsyncValue<List<DocumentModel>>>((ref) {
  final authState = ref.watch(authProvider);
  return TenantDocumentsNotifier(ref.watch(documentServiceProvider), authState.userId);
});

// Documents by category provider
final documentsByCategoryProvider = Provider.family<List<DocumentModel>, String>((ref, category) {
  final documentsAsync = ref.watch(documentsProvider);
  return documentsAsync.when(
    data: (documents) => documents.where((doc) => doc.category == category).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Documents for specific tenant provider (family)
final tenantDocumentsByIdProvider = Provider.family<List<DocumentModel>, String>((ref, tenantId) {
  final documentsAsync = ref.watch(documentsProvider);
  return documentsAsync.when(
    data: (documents) => documents.where((doc) => 
      doc.assignedTenantIds.contains(tenantId) || doc.assignedTenantIds.isEmpty
    ).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Documents for specific property provider
final propertyDocumentsProvider = Provider.family<List<DocumentModel>, String>((ref, propertyId) {
  final documentsAsync = ref.watch(documentsProvider);
  return documentsAsync.when(
    data: (documents) => documents.where((doc) => 
      doc.propertyIds.contains(propertyId) || doc.propertyIds.isEmpty
    ).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Recent documents provider (last 30 days)
final recentDocumentsProvider = Provider<List<DocumentModel>>((ref) {
  final documentsAsync = ref.watch(documentsProvider);
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
  
  return documentsAsync.when(
    data: (documents) => documents
        .where((doc) => doc.uploadDate.isAfter(thirtyDaysAgo))
        .toList()
        ..sort((a, b) => b.uploadDate.compareTo(a.uploadDate)),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Document statistics provider
final documentStatsProvider = Provider<Map<String, int>>((ref) {
  final documentsAsync = ref.watch(documentsProvider);
  
  return documentsAsync.when(
    data: (documents) {
      final stats = <String, int>{};
      for (final category in DocumentCategory.values) {
        stats[category.id] = documents.where((doc) => doc.category == category.id).length;
      }
      stats['total'] = documents.length;
      stats['expiring'] = documents.where((doc) => doc.isExpiringSoon).length;
      stats['expired'] = documents.where((doc) => doc.isExpired).length;
      return stats;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

class DocumentsNotifier extends StateNotifier<AsyncValue<List<DocumentModel>>> {
  DocumentsNotifier(this._documentService, {this.tenantId}) : super(const AsyncValue.loading()) {
    _loadDocuments();
  }

  final DocumentService _documentService;
  final String? tenantId;

  Future<void> _loadDocuments() async {
    try {
      state = const AsyncValue.loading();
      List<DocumentModel> documents = const [];
      if (tenantId != null && tenantId!.isNotEmpty) {
        documents = await _documentService.getDocumentsForTenant(tenantId!);
      } else {
        // Fallback: keep empty to avoid deprecated call and confusion
        documents = const [];
      }
      state = AsyncValue.data(documents);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addDocument(DocumentModel document) async {
    try {
      await _documentService.addDocument(document);
      await _loadDocuments(); // Reload documents
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateDocument(DocumentModel document) async {
    try {
      await _documentService.updateDocument(document);
      await _loadDocuments(); // Reload documents
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      await _documentService.deleteDocument(documentId);
      await _loadDocuments(); // Reload documents
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> assignDocumentToTenants(String documentId, List<String> tenantIds) async {
    try {
      await _documentService.assignDocumentToTenants(documentId, tenantIds);
      await _loadDocuments(); // Reload documents
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> assignDocumentToProperties(String documentId, List<String> propertyIds) async {
    try {
      await _documentService.assignDocumentToProperties(documentId, propertyIds);
      await _loadDocuments(); // Reload documents
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void refresh() {
    _loadDocuments();
  }
}

class LandlordDocumentsNotifier extends StateNotifier<AsyncValue<List<DocumentModel>>> {
  LandlordDocumentsNotifier(this._documentService, this._currentUser) : super(const AsyncValue.loading()) {
    _loadDocuments();
  }

  final DocumentService _documentService;
  final dynamic _currentUser;

  Future<void> _loadDocuments() async {
    try {
      if (_currentUser == null) {
        state = const AsyncValue.data([]);
        return;
      }
      
      state = const AsyncValue.loading();
      final documents = await _documentService.getLandlordDocuments(_currentUser.id);
      state = AsyncValue.data(documents);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addDocument(DocumentModel document) async {
    try {
      await _documentService.addDocument(document);
      await _loadDocuments(); // Reload documents
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateDocument(DocumentModel document) async {
    try {
      await _documentService.updateDocument(document);
      await _loadDocuments(); // Reload documents
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteDocument(String documentId) async {
    try {
      await _documentService.deleteDocument(documentId);
      await _loadDocuments(); // Reload documents
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void refresh() {
    _loadDocuments();
  }
}

class TenantDocumentsNotifier extends StateNotifier<AsyncValue<List<DocumentModel>>> {
  TenantDocumentsNotifier(this._documentService, this._tenantId) : super(const AsyncValue.loading()) {
    _loadDocuments();
  }

  final DocumentService _documentService;
  final String? _tenantId;

  Future<void> _loadDocuments() async {
    try {
      state = const AsyncValue.loading();
      if (_tenantId != null) {
        final documents = await _documentService.getDocumentsForTenant(_tenantId!);
        state = AsyncValue.data(documents);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadDocuments();
  }

  Future<void> addDocument(DocumentModel document) async {
    try {
      await _documentService.addDocument(document);
      await _loadDocuments(); // Reload documents
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
