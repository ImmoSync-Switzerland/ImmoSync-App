import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  static const _bgTop = Color(0xFF0A1128);
  static const _bgBottom = Colors.black;
  static const _card = Color(0xFF1C1C1E);

  @override
  Widget build(BuildContext context) {
    final recentFiles = <_RecentFileItem>[
      const _RecentFileItem(
        fileName: 'Lease_Agreement_2026.pdf',
        dateLabel: 'Jan 2, 2026',
      ),
      const _RecentFileItem(
        fileName: 'MoveIn_Photos_LivingRoom.jpg',
        dateLabel: 'Dec 28, 2025',
      ),
      const _RecentFileItem(
        fileName: 'Notice_Rent_Adjustment.docx',
        dateLabel: 'Dec 15, 2025',
      ),
      const _RecentFileItem(
        fileName: 'Receipt_Plumbing_Invoice.pdf',
        dateLabel: 'Nov 30, 2025',
      ),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          tooltip: 'Back',
        ),
        title: const Text(
          'Documents',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            tooltip: 'Search',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            tooltip: 'Filter',
          ),
          const SizedBox(width: 6),
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BentoCard(
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF3B82F6).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: 0.25),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.folder_rounded,
                          color: Color(0xFF3B82F6),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Documents',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: -0.1,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              '4 Files • 12 MB Used',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Upload New',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const [
                      SizedBox(width: 0),
                      _QuickActionCard(
                        label: 'Lease',
                        icon: Icons.description_rounded,
                      ),
                      SizedBox(width: 12),
                      _QuickActionCard(
                        label: 'Receipt',
                        icon: Icons.receipt_long_rounded,
                      ),
                      SizedBox(width: 12),
                      _QuickActionCard(
                        label: 'Notice',
                        icon: Icons.campaign_rounded,
                      ),
                      SizedBox(width: 0),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Recent Files',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentFiles.length,
                  itemBuilder: (context, index) {
                    final item = recentFiles[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == recentFiles.length - 1 ? 0 : 10,
                      ),
                      child: _BentoCard(
                        child: Row(
                          children: [
                            _FileTypeIconBox(fileName: item.fileName),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.dateLabel,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.more_horiz_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                              tooltip: 'More',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  const _BentoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DocumentsScreen._card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    const baseColor = DocumentsScreen._card;
    final pressedColor = Colors.white.withValues(alpha: 0.06);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 110,
        decoration: BoxDecoration(
          color: _pressed ? pressedColor : baseColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: Colors.white, size: 26),
            const SizedBox(height: 10),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileTypeIconBox extends StatelessWidget {
  const _FileTypeIconBox({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    final ext = fileName.toLowerCase();

    final bool isPdf = ext.endsWith('.pdf');
    final bool isImage = ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.webp');
    final bool isDoc = ext.endsWith('.doc') || ext.endsWith('.docx');

    final IconData icon;
    final Color color;

    if (isPdf) {
      icon = Icons.picture_as_pdf_rounded;
      color = const Color(0xFFEF4444);
    } else if (isImage) {
      icon = Icons.image_rounded;
      color = const Color(0xFF3B82F6);
    } else if (isDoc) {
      icon = Icons.description_rounded;
      color = const Color(0xFF3B82F6);
    } else {
      icon = Icons.insert_drive_file_rounded;
      color = Colors.white70;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _RecentFileItem {
  const _RecentFileItem({required this.fileName, required this.dateLabel});

  final String fileName;
  final String dateLabel;
}
