import 'package:vidsnap/core/constants/sources.dart';

/// Validates URLs locally before contacting the server.
class LinkValidatorService {
  LinkValidatorService._();

  static bool isValidUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return false;
    try {
      final uri = Uri.parse(trimmed);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static SourceDef? findSource(String url) => SupportedSources.findByUrl(url);

  static bool isSupported(String url) {
    if (!isValidUrl(url)) return false;
    return findSource(url) != null;
  }

  /// Tries to extract a URL from arbitrary text (e.g., clipboard contents).
  /// Returns the first URL found, or null.
  static String? extractUrlFromText(String text) {
    final regex = RegExp(r'https?://[^\s<>"{}|\\^`\[\]]+', caseSensitive: false);
    final match = regex.firstMatch(text);
    return match?.group(0);
  }
}
