import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_settings.dart';
import '../services/ayah_selector_service.dart';
import '../models/ayah_with_surah.dart';
import '../services/favorites_service.dart';
import '../services/share_service.dart';
import 'search_screen.dart';
import '../services/collections_service.dart';
import '../services/streak_service.dart';
import '../services/badge_service.dart';
import '../widgets/islamic_pattern_painter.dart';
import '../widgets/ornamental_divider.dart';

class HomeScreen extends StatefulWidget {
  final int? initialSurahId;
  final int? initialAyahId;

  const HomeScreen({super.key, this.initialSurahId, this.initialAyahId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  AyahWithSurah? _currentAyah;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isFavorite = false;
  final int _totalAyahs = 6236;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final FavoritesService _favoritesService = FavoritesService();
  final AyahSelectorService _ayahSelectorService = AyahSelectorService();
  final CollectionsService _collectionsService = CollectionsService();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _initializeServices();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSurahId != null && widget.initialAyahId != null) {
      if (widget.initialSurahId != oldWidget.initialSurahId ||
          widget.initialAyahId != oldWidget.initialAyahId) {
        _loadSpecificAyah(widget.initialSurahId!, widget.initialAyahId!);
      }
    }
  }

  Future<void> _initializeServices() async {
    try {
      await _favoritesService.initialize();
      await _ayahSelectorService.initialize();
      if (widget.initialSurahId != null && widget.initialAyahId != null) {
        await _loadSpecificAyah(widget.initialSurahId!, widget.initialAyahId!);
      } else {
        await _loadTodaysAyah();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTodaysAyah() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // Get settings box (should already be open from main.dart initialization)
      Box<AppSettings> settingsBox;
      if (Hive.isBoxOpen('settings')) {
        settingsBox = Hive.box<AppSettings>('settings');
      } else {
        settingsBox = await Hive.openBox<AppSettings>('settings');
      }

      // Get existing settings or create new one if not exists
      AppSettings settings;
      if (settingsBox.containsKey('app_settings')) {
        settings = settingsBox.get('app_settings')!;
      } else {
        settings = AppSettings();
        await settingsBox.put('app_settings', settings);
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check if we already have a saved ayah for today
      if (settings.lastDailyAyahDate != null &&
          settings.lastDailyAyahDate!.year == today.year &&
          settings.lastDailyAyahDate!.month == today.month &&
          settings.lastDailyAyahDate!.day == today.day &&
          settings.lastDailyAyahSurahId != null &&
          settings.lastDailyAyahAyahId != null) {
        // Load the persisted ayah
        final ayah = await _ayahSelectorService.getSpecificAyah(
          settings.lastDailyAyahSurahId!,
          settings.lastDailyAyahAyahId!,
        );

        if (ayah != null) {
          _updateCurrentAyah(ayah);
          return;
        }
      }

      // If no persisted ayah or not for today, get a new unique one
      final streakService = StreakService();
      // Use async getter to ensure service is initialized
      final userStats = await streakService.getStatsAsync();
      final readIds = userStats.readAyahIds;
      final ayah = await _ayahSelectorService.getUniqueAyahOfTheDay(readIds);

      // Save this ayah as today's ayah
      settings.lastDailyAyahDate = today;
      settings.lastDailyAyahSurahId = ayah.surah.id;
      settings.lastDailyAyahAyahId = ayah.ayah.id;
      await settings.save();

      _updateCurrentAyah(ayah);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading ayah: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSpecificAyah(int surahId, int ayahId) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final ayah = await _ayahSelectorService.getSpecificAyah(surahId, ayahId);
      if (ayah != null) {
        _updateCurrentAyah(ayah);
      } else {
        throw Exception('Ayah not found');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading specific ayah: $e';
          _isLoading = false;
        });
        _loadTodaysAyah();
      }
    }
  }

  Future<void> _loadRandomAyah() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final streakService = StreakService();
      // Use async getter to ensure service is initialized
      final userStats = await streakService.getStatsAsync();
      final readIds = userStats.readAyahIds;
      final ayah = await _ayahSelectorService.getUniqueRandomAyah(readIds);

      // Update the persisted ayah - use proper Hive box access
      Box<AppSettings> settingsBox;
      if (Hive.isBoxOpen('settings')) {
        settingsBox = Hive.box<AppSettings>('settings');
      } else {
        settingsBox = await Hive.openBox<AppSettings>('settings');
      }

      final settings = settingsBox.get('app_settings');
      if (settings != null) {
        final now = DateTime.now();
        settings.lastDailyAyahDate = DateTime(now.year, now.month, now.day);
        settings.lastDailyAyahSurahId = ayah.surah.id;
        settings.lastDailyAyahAyahId = ayah.ayah.id;
        await settings.save();
      }

      _updateCurrentAyah(ayah);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading random ayah: $e';
          _isLoading = false;
        });
      }
    }
  }

  Timer? _readTimer;

  @override
  void dispose() {
    _readTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _updateCurrentAyah(AyahWithSurah ayah) {
    if (!mounted) return;
    _readTimer?.cancel();
    _checkFavoriteStatus(ayah);
    _readTimer = Timer(const Duration(seconds: 7), () {
      if (mounted && _currentAyah == ayah) {
        _incrementReadStats();
      }
    });
    setState(() {
      _currentAyah = ayah;
      _isLoading = false;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  Future<void> _incrementReadStats() async {
    final streakService = StreakService();
    await streakService.initialize();
    await streakService.incrementAyahsRead(
      _currentAyah!.surah.id,
      _currentAyah!.ayah.id,
    );
    final badgeService = BadgeService();
    await badgeService.initialize();
    final newBadges = await badgeService.checkNewUnlocks();
    if (newBadges.isNotEmpty && mounted) {
      for (var badge in newBadges) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(badge.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Badge Unlocked!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(badge.name),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _checkFavoriteStatus(AyahWithSurah ayah) {
    final isFav = _favoritesService.isFavorite(ayah.surah.id, ayah.ayah.id);
    setState(() {
      _isFavorite = isFav;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_currentAyah == null) return;
    await _favoritesService.toggleFavorite(_currentAyah!);
    if (mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? 'Added to favorites' : 'Removed from favorites',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _shareAyah() {
    if (_currentAyah != null) {
      ShareService.shareAyah(_currentAyah!);
    }
  }

  Future<void> _showAddToCollectionDialog() async {
    if (_currentAyah == null) return;
    await _collectionsService.initialize();
    final collections = _collectionsService.getAllCollections();
    if (!mounted) return;
    if (collections.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Collections'),
          content: const Text(
            'Create a collection first from the Collections tab.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Collection'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final collection = collections[index];
              final isInCollection = _collectionsService.isAyahInCollection(
                collection.id,
                _currentAyah!.surah.id,
                _currentAyah!.ayah.id,
              );
              return CheckboxListTile(
                title: Text(collection.name),
                subtitle: Text('${collection.ayahKeys.length} ayahs'),
                value: isInCollection,
                onChanged: (value) async {
                  if (value == true) {
                    await _collectionsService.addAyahToCollection(
                      collection.id,
                      _currentAyah!.surah.id,
                      _currentAyah!.ayah.id,
                    );
                  } else {
                    await _collectionsService.removeAyahFromCollection(
                      collection.id,
                      _currentAyah!.surah.id,
                      _currentAyah!.ayah.id,
                    );
                  }
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value == true
                              ? 'Added to ${collection.name}'
                              : 'Removed from ${collection.name}',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Daily Ayah',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About'),
                  content: Text(
                    'Total Ayahs: $_totalAyahs\n\nThis app shows you a different ayah every day based on a deterministic formula.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                  theme.scaffoldBackgroundColor,
                ],
                stops: const [0.0, 0.3, 0.6],
              ),
            ),
          ),

          // Islamic Geometric Pattern Background
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: IslamicPatternPainter(
                  color: Colors.white,
                  opacity: 0.08,
                ),
              ),
            ),
          ),

          // Decorative Glow Elements
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white.withOpacity(0.1), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.tertiary.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _errorMessage.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.white70,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadTodaysAyah,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _currentAyah == null
                ? const Center(
                    child: Text(
                      'No ayah found',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Date Display
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateTime.now().toString().split(' ')[0],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Main Ayah Card
                          Container(
                            decoration: BoxDecoration(
                              color: theme.cardTheme.color,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Header with Surah Info
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(
                                      0.03,
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(30),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'SURAH',
                                            style: TextStyle(
                                              fontSize: 10,
                                              letterSpacing: 1.5,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.secondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _currentAyah!.surah.transliteration,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.tertiary,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          _currentAyah!.reference,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Arabic Text
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    32,
                                    24,
                                    24,
                                  ),
                                  child: Text(
                                    _currentAyah!.arabicText,
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 36,
                                      height: 2.0,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.primary,
                                    ),
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),

                                // Ornamental Divider
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: OrnamentalDivider(
                                    color: colorScheme.tertiary,
                                    height: 40,
                                  ),
                                ),

                                // Translation
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    _currentAyah!.translation,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontSize: 18,
                                      height: 1.6,
                                      color: theme.textTheme.bodyLarge?.color
                                          ?.withOpacity(0.8),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _ActionButton(
                                icon: _isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                label: 'Favorite',
                                isActive: _isFavorite,
                                activeColor: Colors.red,
                                onPressed: _toggleFavorite,
                              ),
                              _ActionButton(
                                icon: Icons.share_outlined,
                                label: 'Share',
                                onPressed: _shareAyah,
                              ),
                              _ActionButton(
                                icon: Icons.bookmark_border,
                                label: 'Collection',
                                onPressed: _showAddToCollectionDialog,
                              ),
                              _ActionButton(
                                icon: Icons.shuffle,
                                label: 'New Ayah',
                                isPrimary: true,
                                onPressed: _loadRandomAyah,
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isActive;
  final bool isPrimary;
  final Color? activeColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
    this.isPrimary = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isPrimary) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                borderRadius: BorderRadius.circular(30),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isActive
                ? (activeColor ?? colorScheme.primary).withOpacity(0.1)
                : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(30),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(
                  icon,
                  color: isActive
                      ? (activeColor ?? colorScheme.primary)
                      : Colors.grey.shade600,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? (activeColor ?? colorScheme.primary)
                : Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
