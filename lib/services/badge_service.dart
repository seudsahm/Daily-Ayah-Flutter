import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/badge.dart';
import 'streak_service.dart';

class BadgeService {
  static final BadgeService _instance = BadgeService._internal();
  factory BadgeService() => _instance;
  BadgeService._internal();

  late Box<Badge> _box;
  static const String _boxName = 'badges';
  final StreakService _streakService = StreakService();

  Future<void> initialize() async {
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(BadgeAdapter());
    }
    _box = await Hive.openBox<Badge>(_boxName);

    // Always check for new badge definitions to ensure updates are applied
    await _initializeBadges();
  }

  List<Badge> getAllBadges() {
    return _box.values.toList();
  }

  List<Badge> getUnlockedBadges() {
    return _box.values.where((b) => b.isUnlocked).toList();
  }

  ValueListenable<Box<Badge>> get listenable => _box.listenable();

  Future<void> _initializeBadges() async {
    final badges = [
      // --- STREAK BADGES (18 badges) ---
      Badge(
        id: 'streak_1',
        name: 'First Step',
        description: 'Open the app for 1 day',
        icon: '🔥',
        category: 'streak',
        requiredValue: 1,
      ),
      Badge(
        id: 'streak_3',
        name: 'Getting Started',
        description: '3 day streak',
        icon: '🌱',
        category: 'streak',
        requiredValue: 3,
      ),
      Badge(
        id: 'streak_7',
        name: 'Week Warrior',
        description: '7 day streak',
        icon: '⚔️',
        category: 'streak',
        requiredValue: 7,
      ),
      Badge(
        id: 'streak_10',
        name: 'Ten Days',
        description: '10 day streak',
        icon: '🔟',
        category: 'streak',
        requiredValue: 10,
      ),
      Badge(
        id: 'streak_14',
        name: 'Two Weeks Strong',
        description: '14 day streak',
        icon: '🚀',
        category: 'streak',
        requiredValue: 14,
      ),
      Badge(
        id: 'streak_21',
        name: 'Habit Former',
        description: '21 day streak',
        icon: '📅',
        category: 'streak',
        requiredValue: 21,
      ),
      Badge(
        id: 'streak_30',
        name: 'Month Master',
        description: '30 day streak',
        icon: '👑',
        category: 'streak',
        requiredValue: 30,
      ),
      Badge(
        id: 'streak_40',
        name: 'Forty Days',
        description: '40 day streak',
        icon: '🕌',
        category: 'streak',
        requiredValue: 40,
      ),
      Badge(
        id: 'streak_50',
        name: 'Half Century',
        description: '50 day streak',
        icon: '🌓',
        category: 'streak',
        requiredValue: 50,
      ),
      Badge(
        id: 'streak_60',
        name: 'Consistency King',
        description: '60 day streak',
        icon: '🏰',
        category: 'streak',
        requiredValue: 60,
      ),
      Badge(
        id: 'streak_90',
        name: 'Quarter Champion',
        description: '90 day streak',
        icon: '🥉',
        category: 'streak',
        requiredValue: 90,
      ),
      Badge(
        id: 'streak_100',
        name: 'Centurion',
        description: '100 day streak',
        icon: '💯',
        category: 'streak',
        requiredValue: 100,
      ),
      Badge(
        id: 'streak_180',
        name: 'Half Year Hero',
        description: '180 day streak',
        icon: '🥈',
        category: 'streak',
        requiredValue: 180,
      ),
      Badge(
        id: 'streak_200',
        name: 'Double Century',
        description: '200 day streak',
        icon: '⚡',
        category: 'streak',
        requiredValue: 200,
      ),
      Badge(
        id: 'streak_300',
        name: 'Spartan',
        description: '300 day streak',
        icon: '🛡️',
        category: 'streak',
        requiredValue: 300,
      ),
      Badge(
        id: 'streak_365',
        name: 'Year Legend',
        description: '365 day streak',
        icon: '🥇',
        category: 'streak',
        requiredValue: 365,
      ),
      Badge(
        id: 'streak_500',
        name: 'Endurance Master',
        description: '500 day streak',
        icon: '🏃',
        category: 'streak',
        requiredValue: 500,
      ),
      Badge(
        id: 'streak_1000',
        name: 'Eternal Flame',
        description: '1000 day streak',
        icon: '💎',
        category: 'streak',
        requiredValue: 1000,
      ),

      // --- COLLECTION BADGES (15 badges) ---
      Badge(
        id: 'col_1',
        name: 'First Favorite',
        description: 'Save 1 ayah to favorites',
        icon: '❤️',
        category: 'collection',
        requiredValue: 1,
      ),
      Badge(
        id: 'col_5',
        name: 'Beginner Collector',
        description: 'Save 5 ayahs',
        icon: '📂',
        category: 'collection',
        requiredValue: 5,
      ),
      Badge(
        id: 'col_10',
        name: 'Collector',
        description: 'Save 10 ayahs',
        icon: '📚',
        category: 'collection',
        requiredValue: 10,
      ),
      Badge(
        id: 'col_20',
        name: 'Enthusiast',
        description: 'Save 20 ayahs',
        icon: '🔖',
        category: 'collection',
        requiredValue: 20,
      ),
      Badge(
        id: 'col_30',
        name: 'Dedicated',
        description: 'Save 30 ayahs',
        icon: '🗂️',
        category: 'collection',
        requiredValue: 30,
      ),
      Badge(
        id: 'col_40',
        name: 'Accumulator',
        description: 'Save 40 ayahs',
        icon: '🧺',
        category: 'collection',
        requiredValue: 40,
      ),
      Badge(
        id: 'col_50',
        name: 'Curator',
        description: 'Save 50 ayahs',
        icon: '🏛️',
        category: 'collection',
        requiredValue: 50,
      ),
      Badge(
        id: 'col_75',
        name: 'Librarian',
        description: 'Save 75 ayahs',
        icon: '📖',
        category: 'collection',
        requiredValue: 75,
      ),
      Badge(
        id: 'col_100',
        name: 'Master Collector',
        description: 'Save 100 ayahs',
        icon: '🏆',
        category: 'collection',
        requiredValue: 100,
      ),
      Badge(
        id: 'col_150',
        name: 'Archivist',
        description: 'Save 150 ayahs',
        icon: '🗄️',
        category: 'collection',
        requiredValue: 150,
      ),
      Badge(
        id: 'col_200',
        name: 'Library Keeper',
        description: 'Save 200 ayahs',
        icon: '🏰',
        category: 'collection',
        requiredValue: 200,
      ),
      Badge(
        id: 'col_300',
        name: 'Museum Owner',
        description: 'Save 300 ayahs',
        icon: '🖼️',
        category: 'collection',
        requiredValue: 300,
      ),
      Badge(
        id: 'col_400',
        name: 'Guardian',
        description: 'Save 400 ayahs',
        icon: '🛡️',
        category: 'collection',
        requiredValue: 400,
      ),
      Badge(
        id: 'col_500',
        name: 'Treasure Hunter',
        description: 'Save 500 ayahs',
        icon: '💰',
        category: 'collection',
        requiredValue: 500,
      ),
      Badge(
        id: 'col_1000',
        name: 'Grand Keeper',
        description: 'Save 1000 ayahs',
        icon: '🗝️',
        category: 'collection',
        requiredValue: 1000,
      ),

      // --- EXPLORER BADGES (19 badges) ---
      Badge(
        id: 'read_1',
        name: 'First Reading',
        description: 'Read 1 unique ayah',
        icon: '📖',
        category: 'explorer',
        requiredValue: 1,
      ),
      Badge(
        id: 'read_10',
        name: 'Curious Soul',
        description: 'Read 10 unique ayahs',
        icon: '🧐',
        category: 'explorer',
        requiredValue: 10,
      ),
      Badge(
        id: 'read_50',
        name: 'Explorer',
        description: 'Read 50 unique ayahs',
        icon: '🧭',
        category: 'explorer',
        requiredValue: 50,
      ),
      Badge(
        id: 'read_100',
        name: 'Seeker of Knowledge',
        description: 'Read 100 unique ayahs',
        icon: '🕯️',
        category: 'explorer',
        requiredValue: 100,
      ),
      Badge(
        id: 'read_200',
        name: 'Student',
        description: 'Read 200 unique ayahs',
        icon: '📝',
        category: 'explorer',
        requiredValue: 200,
      ),
      Badge(
        id: 'read_250',
        name: 'Devoted Reader',
        description: 'Read 250 unique ayahs',
        icon: '📜',
        category: 'explorer',
        requiredValue: 250,
      ),
      Badge(
        id: 'read_300',
        name: 'Scholar in Training',
        description: 'Read 300 unique ayahs',
        icon: '🎓',
        category: 'explorer',
        requiredValue: 300,
      ),
      Badge(
        id: 'read_400',
        name: 'Avid Reader',
        description: 'Read 400 unique ayahs',
        icon: '👓',
        category: 'explorer',
        requiredValue: 400,
      ),
      Badge(
        id: 'read_500',
        name: 'Quran Student',
        description: 'Read 500 unique ayahs',
        icon: '🏫',
        category: 'explorer',
        requiredValue: 500,
      ),
      Badge(
        id: 'read_600',
        name: 'Dedicated Soul',
        description: 'Read 600 unique ayahs',
        icon: '🤲',
        category: 'explorer',
        requiredValue: 600,
      ),
      Badge(
        id: 'read_700',
        name: 'Reflective Heart',
        description: 'Read 700 unique ayahs',
        icon: '💖',
        category: 'explorer',
        requiredValue: 700,
      ),
      Badge(
        id: 'read_800',
        name: 'Wise Mind',
        description: 'Read 800 unique ayahs',
        icon: '🧠',
        category: 'explorer',
        requiredValue: 800,
      ),
      Badge(
        id: 'read_900',
        name: 'Illuminated',
        description: 'Read 900 unique ayahs',
        icon: '💡',
        category: 'explorer',
        requiredValue: 900,
      ),
      Badge(
        id: 'read_1000',
        name: 'Quran Explorer',
        description: 'Read 1000 unique ayahs',
        icon: '🌍',
        category: 'explorer',
        requiredValue: 1000,
      ),
      Badge(
        id: 'read_2000',
        name: 'Deep Diver',
        description: 'Read 2000 unique ayahs',
        icon: '🌊',
        category: 'explorer',
        requiredValue: 2000,
      ),
      Badge(
        id: 'read_3000',
        name: 'Halfway There',
        description: 'Read 3000 unique ayahs',
        icon: '⛰️',
        category: 'explorer',
        requiredValue: 3000,
      ),
      Badge(
        id: 'read_4000',
        name: 'Mountain Climber',
        description: 'Read 4000 unique ayahs',
        icon: '🏔️',
        category: 'explorer',
        requiredValue: 4000,
      ),
      Badge(
        id: 'read_5000',
        name: 'Ocean Crosser',
        description: 'Read 5000 unique ayahs',
        icon: '🚢',
        category: 'explorer',
        requiredValue: 5000,
      ),
      Badge(
        id: 'read_6236',
        name: 'Khatam',
        description: 'Read all 6236 ayahs',
        icon: '🕋',
        category: 'explorer',
        requiredValue: 6236,
      ),

      // --- SOCIAL BADGES (6 badges) ---
      Badge(
        id: 'social_1',
        name: 'First Share',
        description: 'Share an ayah',
        icon: '📤',
        category: 'social',
        requiredValue: 1,
      ),
      Badge(
        id: 'social_5',
        name: 'Messenger',
        description: 'Share 5 ayahs',
        icon: '📨',
        category: 'social',
        requiredValue: 5,
      ),
      Badge(
        id: 'social_10',
        name: 'Sharing is Caring',
        description: 'Share 10 ayahs',
        icon: '🤝',
        category: 'social',
        requiredValue: 10,
      ),
      Badge(
        id: 'social_20',
        name: 'Broadcaster',
        description: 'Share 20 ayahs',
        icon: '📢',
        category: 'social',
        requiredValue: 20,
      ),
      Badge(
        id: 'social_50',
        name: 'Influencer',
        description: 'Share 50 ayahs',
        icon: '🌟',
        category: 'social',
        requiredValue: 50,
      ),
      Badge(
        id: 'social_100',
        name: 'Ambassador',
        description: 'Share 100 ayahs',
        icon: '🕊️',
        category: 'social',
        requiredValue: 100,
      ),

      // --- SPECIAL BADGES (4 badges) ---
      Badge(
        id: 'special_early',
        name: 'Early Bird',
        description: 'Open app before 6 AM',
        icon: '🌅',
        category: 'special',
        requiredValue: 1,
      ),
      Badge(
        id: 'special_night',
        name: 'Night Owl',
        description: 'Open app after 10 PM',
        icon: '🦉',
        category: 'special',
        requiredValue: 1,
      ),
      Badge(
        id: 'special_weekend',
        name: 'Weekend Warrior',
        description: 'Open app on a weekend',
        icon: '🏖️',
        category: 'special',
        requiredValue: 1,
      ),
      Badge(
        id: 'special_pdf',
        name: 'PDF Creator',
        description: 'Generate a Weekly Digest',
        icon: '📄',
        category: 'special',
        requiredValue: 1,
      ),
    ];

    // Clear existing badges to remove duplicates and ensure consistency
    await _box.clear();

    // Add all badges fresh
    for (var badge in badges) {
      await _box.put(badge.id, badge);
    }

    // Re-check unlocks to restore user progress based on stats
    await checkNewUnlocks();
  }

  Future<List<Badge>> checkNewUnlocks() async {
    final stats = _streakService.stats;
    final newUnlocks = <Badge>[];

    for (var badge in _box.values) {
      if (badge.isUnlocked) continue;

      bool unlocked = false;

      switch (badge.category) {
        case 'streak':
          if (stats.currentStreak >= badge.requiredValue) unlocked = true;
          break;
        case 'collection':
          if (stats.totalFavorites >= badge.requiredValue) unlocked = true;
          break;
        case 'explorer':
          if (stats.totalAyahsRead >= badge.requiredValue) unlocked = true;
          break;
        case 'social':
          if (stats.totalShares >= badge.requiredValue) unlocked = true;
          break;
        case 'special':
          if (badge.id == 'special_pdf' && stats.totalPDFsGenerated >= 1)
            unlocked = true;
          // Other special badges (early/night/weekend) are triggered manually
          break;
      }

      if (unlocked) {
        badge.isUnlocked = true;
        badge.unlockedDate = DateTime.now();
        await badge.save();
        newUnlocks.add(badge);
      }
    }

    return newUnlocks;
  }
}
