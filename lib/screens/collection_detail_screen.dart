import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/collection.dart';
import '../services/collections_service.dart';
import '../services/ayah_selector_service.dart';
import '../models/ayah_with_surah.dart';
import '../widgets/islamic_pattern_painter.dart';
import '../widgets/ornamental_divider.dart';

class CollectionDetailScreen extends StatefulWidget {
  final Collection collection;

  const CollectionDetailScreen({super.key, required this.collection});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen>
    with SingleTickerProviderStateMixin {
  final CollectionsService _collectionsService = CollectionsService();
  final AyahSelectorService _ayahService = AyahSelectorService();
  List<AyahWithSurah> _ayahs = [];
  bool _isLoading = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadAyahs();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadAyahs() async {
    setState(() => _isLoading = true);
    await _ayahService.initialize();

    final ayahs = <AyahWithSurah>[];
    for (final key in widget.collection.ayahKeys) {
      final parts = key.split('_');
      if (parts.length == 2) {
        final surahId = int.parse(parts[0]);
        final ayahId = int.parse(parts[1]);
        final ayah = await _ayahService.getSpecificAyah(surahId, ayahId);
        if (ayah != null) ayahs.add(ayah);
      }
    }

    if (mounted) {
      setState(() {
        _ayahs = ayahs;
        _isLoading = false;
      });
      _fadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.collection.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    colorScheme.primary.withOpacity(0.3),
                    colorScheme.surface,
                    colorScheme.surface,
                  ]
                : [
                    colorScheme.primary.withOpacity(0.15),
                    colorScheme.surface,
                    colorScheme.surface,
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Islamic pattern background
            Positioned.fill(
              child: RepaintBoundary(
                child: Opacity(
                  opacity: isDark ? 0.03 : 0.05,
                  child: CustomPaint(
                    painter: IslamicPatternPainter(color: colorScheme.primary),
                  ),
                ),
              ),
            ),
            // Content
            SafeArea(
              child: _isLoading
                  ? _buildLoadingState(colorScheme)
                  : _ayahs.isEmpty
                  ? _buildEmptyState(theme, isDark)
                  : _buildAyahList(theme, colorScheme, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 3),
          const SizedBox(height: 16),
          Text(
            'Loading verses...',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.2),
                      theme.colorScheme.secondary.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Icon(
                  Icons.bookmark_border,
                  size: 50,
                  color: theme.colorScheme.primary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Verses Yet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Add ayahs to this collection from the home screen by tapping the bookmark icon',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAyahList(ThemeData theme, ColorScheme colorScheme, bool isDark) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _ayahs.length,
        itemBuilder: (context, index) {
          final ayah = _ayahs[index];
          return _buildAyahCard(ayah, theme, colorScheme, isDark, index);
        },
      ),
    );
  }

  Widget _buildAyahCard(
    AyahWithSurah ayah,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : colorScheme.primary.withOpacity(0.15),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with reference and remove button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary.withOpacity(0.15),
                                colorScheme.secondary.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            ayah.reference,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () async {
                              await _collectionsService
                                  .removeAyahFromCollection(
                                    widget.collection.id,
                                    ayah.surah.id,
                                    ayah.ayah.id,
                                  );
                              _loadAyahs();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Arabic text
                    Text(
                      ayah.ayah.text,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 22,
                        height: 2.0,
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 16),
                    // Ornamental divider
                    OrnamentalDivider(color: colorScheme.primary),
                    const SizedBox(height: 16),
                    // Translation
                    Text(
                      ayah.ayah.translation,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: isDark
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Surah name
                    Text(
                      'Surah ${ayah.surah.transliteration}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFD4AF37).withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
