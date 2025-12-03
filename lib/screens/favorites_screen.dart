import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/favorite_ayah.dart';
import '../services/favorites_service.dart';
import '../services/share_service.dart';
import '../models/ayah_with_surah.dart';
import '../models/surah.dart';
import '../models/ayah.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    await _favoritesService.initialize();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(FavoriteAyah favorite) async {
    await _favoritesService.removeFavorite(favorite.surahId, favorite.ayahId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from favorites'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _shareFavorite(FavoriteAyah favorite) {
    // Convert FavoriteAyah to AyahWithSurah for sharing
    final ayahWithSurah = AyahWithSurah(
      surah: Surah(
        id: favorite.surahId,
        name: favorite.surahName,
        transliteration: favorite.surahName,
        translation: '',
        type: '',
        totalVerses: 0,
        verses: [],
      ),
      ayah: Ayah(
        id: favorite.ayahId,
        text: favorite.arabicText,
        translation: favorite.translation,
      ),
    );

    ShareService.shareAyah(ayahWithSurah);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Favorites',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading)
            ValueListenableBuilder<Box<FavoriteAyah>>(
              valueListenable: _favoritesService.listenable,
              builder: (context, box, _) {
                final count = box.length;
                if (count == 0) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder<Box<FavoriteAyah>>(
              valueListenable: _favoritesService.listenable,
              builder: (context, box, _) {
                final favorites = _favoritesService.getAllFavorites();

                if (favorites.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final favorite = favorites[index];
                    return _FavoriteCard(
                      favorite: favorite,
                      onRemove: () => _removeFavorite(favorite),
                      onShare: () => _shareFavorite(favorite),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Favorites Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save your favorite ayahs to read them later',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final FavoriteAyah favorite;
  final VoidCallback onRemove;
  final VoidCallback onShare;

  const _FavoriteCard({
    required this.favorite,
    required this.onRemove,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Arabic text
            Text(
              favorite.arabicText,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 24,
                height: 2.0,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1B5E20),
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // Translation
            Text(
              favorite.translation,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            // Reference and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Reference
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    favorite.reference,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),

                // Actions
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share, size: 20),
                      color: Colors.blue,
                      onPressed: onShare,
                      tooltip: 'Share',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove Favorite'),
                            content: const Text(
                              'Are you sure you want to remove this ayah from favorites?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  onRemove();
                                },
                                child: const Text(
                                  'Remove',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      tooltip: 'Remove',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
