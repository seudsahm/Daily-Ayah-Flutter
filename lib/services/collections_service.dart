import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/collection.dart';

class CollectionsService {
  static const String _boxName = 'collections';
  Box<Collection>? _collectionsBox;

  // Singleton pattern
  static final CollectionsService _instance = CollectionsService._internal();
  factory CollectionsService() => _instance;
  CollectionsService._internal();

  Future<void> initialize() async {
    if (_collectionsBox != null && _collectionsBox!.isOpen) return;

    // Check if box is already open
    if (Hive.isBoxOpen(_boxName)) {
      _collectionsBox = Hive.box<Collection>(_boxName);
    } else {
      _collectionsBox = await Hive.openBox<Collection>(_boxName);
    }
  }

  /// Get all collections
  List<Collection> getAllCollections() {
    if (_collectionsBox == null || !_collectionsBox!.isOpen) return [];
    return _collectionsBox!.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Create a new collection
  Future<void> createCollection(String name) async {
    await initialize();
    final collection = Collection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
    );
    await _collectionsBox!.put(collection.id, collection);
  }

  /// Delete a collection
  Future<void> deleteCollection(String id) async {
    await initialize();
    await _collectionsBox!.delete(id);
  }

  /// Rename a collection
  Future<void> renameCollection(String id, String newName) async {
    await initialize();
    final collection = _collectionsBox!.get(id);
    if (collection != null) {
      collection.name = newName;
      await collection.save();
    }
  }

  /// Add ayah to collection
  Future<void> addAyahToCollection(
    String collectionId,
    int surahId,
    int ayahId,
  ) async {
    await initialize();
    final collection = _collectionsBox!.get(collectionId);
    if (collection != null) {
      final key = '${surahId}_$ayahId';
      if (!collection.ayahKeys.contains(key)) {
        collection.ayahKeys.add(key);
        await collection.save();
      }
    }
  }

  /// Remove ayah from collection
  Future<void> removeAyahFromCollection(
    String collectionId,
    int surahId,
    int ayahId,
  ) async {
    await initialize();
    final collection = _collectionsBox!.get(collectionId);
    if (collection != null) {
      final key = '${surahId}_$ayahId';
      collection.ayahKeys.remove(key);
      await collection.save();
    }
  }

  /// Check if ayah is in collection
  bool isAyahInCollection(String collectionId, int surahId, int ayahId) {
    if (_collectionsBox == null || !_collectionsBox!.isOpen) return false;
    final collection = _collectionsBox!.get(collectionId);
    if (collection == null) return false;
    final key = '${surahId}_$ayahId';
    return collection.ayahKeys.contains(key);
  }

  /// Get collection by ID
  Collection? getCollection(String id) {
    if (_collectionsBox == null || !_collectionsBox!.isOpen) return null;
    return _collectionsBox!.get(id);
  }

  /// Get listenable for reactive UI
  ValueListenable<Box<Collection>> get listenable {
    if (_collectionsBox == null || !_collectionsBox!.isOpen) {
      throw Exception('Box not open');
    }
    return _collectionsBox!.listenable();
  }
}
