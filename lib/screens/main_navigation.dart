import 'package:flutter/material.dart';
import '../services/deep_link_service.dart';
import '../services/badge_service.dart';
import '../widgets/badge_reveal_sheet.dart';
import '../models/badge.dart' as model;
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'collections_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final DeepLinkService _deepLinkService = DeepLinkService();

  final PageController _pageController = PageController();

  // Deep link params
  int? _deepLinkSurahId;
  int? _deepLinkAyahId;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _initBadgeListener();
  }

  void _initBadgeListener() {
    BadgeService().onUnlocks.listen((badges) {
      if (!mounted) return;
      _showBadgeQueue(badges);
    });
  }

  Future<void> _showBadgeQueue(List<model.Badge> badges) async {
    for (var badge in badges) {
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => BadgeRevealSheet(badge: badge),
      );
      // Small delay between badges if multiple unlocked
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  void _initDeepLinks() async {
    _deepLinkService.onAyahLinkReceived = (surahId, ayahId) {
      if (mounted) {
        setState(() {
          _selectedIndex = 0; // Switch to Home tab
          _deepLinkSurahId = surahId;
          _deepLinkAyahId = ayahId;
        });
        _pageController.jumpToPage(0);
      }
    };

    await _deepLinkService.initialize();
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Clear deep link params when manually switching tabs
      if (index != 0) {
        _deepLinkSurahId = null;
        _deepLinkAyahId = null;
      }
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
            // Clear deep link params when switching tabs
            if (index != 0) {
              _deepLinkSurahId = null;
              _deepLinkAyahId = null;
            }
          });
        },
        children: [
          HomeScreen(
            initialSurahId: _deepLinkSurahId,
            initialAyahId: _deepLinkAyahId,
          ),
          const FavoritesScreen(),
          const CollectionsScreen(),
          const ProfileScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(
          context,
        ).bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: Theme.of(
          context,
        ).bottomNavigationBarTheme.unselectedItemColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.collections_bookmark),
            label: 'Collections',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
