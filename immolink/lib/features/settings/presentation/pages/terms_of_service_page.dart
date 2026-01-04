import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:immosync/l10n/app_localizations.dart';
import '../../../../core/theme/app_typography.dart';

const _bgTop = Color(0xFF0A1128);
const _bgBottom = Colors.black;
const _bentoCard = Color(0xFF1C1C1E);

class TermsOfServicePage extends ConsumerStatefulWidget {
  const TermsOfServicePage({super.key});
  @override
  ConsumerState<TermsOfServicePage> createState() => _TermsOfServicePageState();
}

class _TermsOfServicePageState extends ConsumerState<TermsOfServicePage> {
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _headingKeys = {};
  final Set<String> _assignedOnce = {};
  final Set<int> _skipIndices =
      {}; // lines belonging to embedded static TOC enumeration
  // Similar pattern: numbered headings need content after number. Include explicit first-section labels for multiple locales.
  final _headingRegex = RegExp(
      r'^(?:[0-9]{1,2}\.[ \t]+\S|Vertragliche Grundlagen|Foundational Provisions|Disposizioni Fondamentali|Dispositions fondamentales)');
  late List<String> _lines;
  late List<String> _headings;

  void _prepare(String body) {
    _lines = body.split('\n');
    _skipIndices.clear();
    // Detect embedded static TOC (language variants of a TOC heading) and skip its lines.
    const tocMarkers = [
      'Inhaltsverzeichnis',
      'Indice',
      'Index',
      'Table des matières',
      'Table of Contents'
    ];
    final tocTitleIndex =
        _lines.indexWhere((l) => tocMarkers.contains(l.trim()));
    final List<String> enumerationHeadings = [];
    if (tocTitleIndex != -1) {
      _skipIndices.add(tocTitleIndex);
      final seenLocal = <String>{};
      for (var i = tocTitleIndex + 1; i < _lines.length; i++) {
        final t = _lines[i].trim();
        if (t.isEmpty) break;
        final isHeading = _headingRegex.hasMatch(t);
        if (!isHeading) break;
        if (seenLocal.contains(t)) break; // start of real content
        enumerationHeadings.add(t);
        seenLocal.add(t);
        _skipIndices.add(i);
      }
    }
    // Collect all headings (dedupe preserving order)
    final all = _lines
        .asMap()
        .entries
        .where((e) => _headingRegex.hasMatch(e.value.trim()))
        .map((e) => e.value.trim())
        .toList();
    if (enumerationHeadings.isNotEmpty) {
      _headings = enumerationHeadings;
    } else {
      final seen = <String>{};
      _headings = [
        for (final h in all)
          if (seen.add(h)) h
      ];
    }
    _headingKeys.clear();
    _assignedOnce.clear();
    for (final h in _headings) {
      if (!_headingKeys.containsKey(h)) {
        _headingKeys[h] = GlobalKey();
      }
    }
  }

  Future<void> _scrollTo(String heading) async {
    final key = _headingKeys[heading];
    if (key == null) return;
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.1);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final body = l.termsOfServiceContent;
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;
    _prepare(body);
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_bgTop, _bgBottom],
            ),
          ),
        ),
        title: Text(
          l.termsOfService,
          style: AppTypography.pageTitle.copyWith(color: Colors.white),
        ),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => context.pop()),
        actions: [
          IconButton(
            tooltip: l.copy,
            icon: const Icon(Icons.copy, color: Colors.white),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: body));
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l.copied)));
              }
            },
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(16, topInset + 16, 16, 24),
          children: [
            Container(
              decoration: BoxDecoration(
                color: _bentoCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.termsOfService,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(l.termsOfServiceLastUpdated,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 20),
                    if (_headings.isNotEmpty)
                      _Toc(
                          headings: _headings,
                          title: l.tableOfContents,
                          onTap: _scrollTo),
                    Divider(
                      height: 32,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                    ..._buildParagraphs(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildParagraphs() {
    final widgets = <Widget>[];
    for (var i = 0; i < _lines.length; i++) {
      if (_skipIndices.contains(i)) continue; // hide static TOC lines
      final text = _lines[i].trim();
      if (text.isEmpty) continue;
      final isHeading = _headingRegex.hasMatch(text);
      GlobalKey? key;
      if (isHeading && !_assignedOnce.contains(text)) {
        key = _headingKeys[text];
        _assignedOnce.add(text);
      }
      widgets.add(Padding(
        key: key,
        padding: EdgeInsets.only(
            bottom: isHeading ? 12 : 10, top: isHeading ? 16 : 0),
        child: SelectableText(
          text,
          style: isHeading
              ? const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                )
              : const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.white70,
                ),
        ),
      ));
    }
    return widgets;
  }
}

class _Toc extends StatelessWidget {
  final List<String> headings;
  final String title;
  final void Function(String heading) onTap;
  const _Toc(
      {required this.headings, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            )),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final h in headings)
              ActionChip(
                label: Text(
                  h,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                backgroundColor: _bentoCard,
                onPressed: () => onTap(h.trim()),
              )
          ],
        )
      ],
    );
  }
}
