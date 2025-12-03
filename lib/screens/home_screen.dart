import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/ayah_selector_service.dart';
import '../models/ayah_with_surah.dart';
import '../services/favorites_service.dart';
import '../services/share_service.dart';
import 'search_screen.dart';
import '../services/collections_service.dart';

import '../services/streak_service.dart';
import '../services/badge_service.dart';

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
  int _totalAyahs = 6236; // Default approximation

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
      // AyahSelectorService handles data loading internally
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
      // Get read ayahs to ensure uniqueness
      final streakService = StreakService();
      await streakService.initialize();
      final readIds = streakService.stats.readAyahIds;

      final ayah = await _ayahSelectorService.getUniqueAyahOfTheDay(readIds);
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
      // Get read ayahs to ensure uniqueness
      final streakService = StreakService();
      await streakService.initialize();
      final readIds = streakService.stats.readAyahIds;

      final ayah = await _ayahSelectorService.getUniqueRandomAyah(readIds);
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

    // Cancel existing timer if user swipes/changes ayah before 7 seconds
    _readTimer?.cancel();

    _checkFavoriteStatus(ayah);

    // Start new 7-second timer for read count
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
    // Ayah.id is the number in surah
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
      // Show message to create collection first
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

    // Show collection selection dialog
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
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Daily Ayah',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1B5E20),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadTodaysAyah,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _currentAyah == null
          ? const Center(child: Text('No ayah found'))
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Date header card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Color(0xFF1B5E20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateTime.now().toString().split(' ')[0],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Arabic text card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.green.shade50,
                              Colors.green.shade100,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.shade200,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _currentAyah!.arabicText,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 32,
                            height: 2.2,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1B5E20),
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Translation card
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.translate,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Translation',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _currentAyah!.translation,
                              style: const TextStyle(
                                fontSize: 17,
                                height: 1.8,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Reference
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _currentAyah!.reference,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Favorite button
                        _ActionButton(
                          icon: _isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          label: 'Favorite',
                          color: Colors.red,
                          onPressed: _toggleFavorite,
                        ),

                        // Share button
                        _ActionButton(
                          icon: Icons.share,
                          label: 'Share',
                          color: Colors.blue,
                          onPressed: _shareAyah,
                        ),

                        // Add to Collection button
                        _ActionButton(
                          icon: Icons.folder,
                          label: 'Collection',
                          color: const Color(0xFF1B5E20),
                          onPressed: _showAddToCollectionDialog,
                        ),

                        // New Ayah button
                        _ActionButton(
                          icon: Icons.shuffle,
                          label: 'New Ayah',
                          color: Colors.green,
                          onPressed: _loadRandomAyah,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
