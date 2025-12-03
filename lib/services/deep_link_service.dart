import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  // Callback to handle navigation
  Function(int surahId, int ayahId)? onAyahLinkReceived;

  /// Initialize deep link listener
  Future<void> initialize() async {
    // Check initial link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleLink(initialUri);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Listen for incoming links
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleLink(uri);
      },
      onError: (err) {
        debugPrint('Error listening to links: $err');
      },
    );
  }

  /// Handle parsed URI
  void _handleLink(Uri uri) {
    debugPrint('Received deep link: $uri');

    // Scheme: dailyayah://ayah/{surahId}/{ayahId}
    if (uri.scheme == 'dailyayah' && uri.host == 'ayah') {
      final segments = uri.pathSegments;
      if (segments.length >= 2) {
        final surahId = int.tryParse(segments[0]);
        final ayahId = int.tryParse(segments[1]);

        if (surahId != null && ayahId != null && onAyahLinkReceived != null) {
          onAyahLinkReceived!(surahId, ayahId);
        }
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
