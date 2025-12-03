import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/ayah_with_surah.dart';

class ShareService {
  static const String _appLink =
      'https://example.com/daily_ayah'; // Replace with actual store link later

  /// Share formatted ayah text
  static Future<void> shareAyah(AyahWithSurah ayah) async {
    final text = _formatAyahText(ayah);
    await Share.share(text);
  }

  /// Copy formatted ayah text to clipboard
  static Future<void> copyToClipboard(AyahWithSurah ayah) async {
    final text = _formatAyahText(ayah);
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Format ayah text for sharing
  static String _formatAyahText(AyahWithSurah ayah) {
    return '''
${ayah.arabicText}

${ayah.translation}

${ayah.reference}

Read more on Daily Ayah app!
$_appLink
''';
  }
}
