import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/providers/dynamic_colors_provider.dart';
import '../../domain/models/support_request.dart';
import '../../domain/services/support_request_service.dart';

final _supportRequestDetailProvider =
    FutureProvider.family<SupportRequest, String>((ref, id) async {
  final service = ref.read(supportRequestServiceProvider);
  return service.fetch(id);
});

class SupportRequestDetailPage extends ConsumerStatefulWidget {
  final String requestId;
  const SupportRequestDetailPage({super.key, required this.requestId});
  @override
  ConsumerState<SupportRequestDetailPage> createState() =>
      _SupportRequestDetailPageState();
}

class _SupportRequestDetailPageState
    extends ConsumerState<SupportRequestDetailPage> {
  final _noteCtrl = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(dynamicColorsProvider);
    final loc = AppLocalizations.of(context)!;
    final asyncReq = ref.watch(_supportRequestDetailProvider(widget.requestId));
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.supportRequests,
            style: TextStyle(color: colors.textPrimary)),
        backgroundColor: colors.primaryBackground,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      backgroundColor: colors.primaryBackground,
      body: asyncReq.when(
        data: (r) => RefreshIndicator(
          onRefresh: () async => ref
              .refresh(_supportRequestDetailProvider(widget.requestId).future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(r.subject,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary)),
              const SizedBox(height: 8),
              _metaRow(loc, colors, 'ID', r.id),
              _metaRow(loc, colors, loc.category, r.category),
              _metaRow(loc, colors, loc.priority, r.priority),
              _metaRow(loc, colors, loc.status, r.status),
              const SizedBox(height: 12),
              Text(r.message, style: TextStyle(color: colors.textSecondary)),
              const SizedBox(height: 24),
              Text(loc.notes,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary)),
              const SizedBox(height: 8),
              if (r.notes.isEmpty)
                Text(loc.noData, style: TextStyle(color: colors.textSecondary))
              else
                ...r.notes.map((n) => Card(
                      color: colors.surfaceCards,
                      child: ListTile(
                        title: Text(n.body,
                            style: TextStyle(color: colors.textPrimary)),
                        subtitle: Text(_formatDate(n.createdAt),
                            style: TextStyle(
                                fontSize: 11, color: colors.textSecondary)),
                      ),
                    )),
              const SizedBox(height: 16),
              TextField(
                controller: _noteCtrl,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: loc.addNote,
                  filled: true,
                  fillColor: colors.surfaceCards,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.borderLight)),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _adding ? null : () => _submitNote(context, loc),
                  child: _adding
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(loc.save),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
            child: Text('${loc.error}: $e',
                style: TextStyle(color: colors.error))),
      ),
    );
  }

  Widget _metaRow(AppLocalizations loc, DynamicAppColors colors, String label,
      String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
              width: 120,
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: colors.textPrimary))),
          Expanded(
              child:
                  Text(value, style: TextStyle(color: colors.textSecondary))),
        ],
      ),
    );
  }

  Future<void> _submitNote(BuildContext context, AppLocalizations loc) async {
    final txt = _noteCtrl.text.trim();
    if (txt.isEmpty) return;
    setState(() => _adding = true);
    try {
      await ref
          .read(supportRequestServiceProvider)
          .addNote(widget.requestId, txt);
      _noteCtrl.clear();
      ref.invalidate(_supportRequestDetailProvider(widget.requestId));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.noteAddedSuccessfully)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${loc.failedToAddNote}: $e')));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
