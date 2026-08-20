/// Whitelisted sources for the VidSnap app.
/// Mirrors the server's `sources.ts` exactly.
class SourceDef {
  const SourceDef({
    required this.id,
    required this.label,
    required this.hosts,
    required this.iconAsset,
  });

  final String id;
  final String label;
  final List<String> hosts;
  final String iconAsset;
}

class SupportedSources {
  SupportedSources._();

  static const List<SourceDef> all = [
    SourceDef(
      id: 'youtube',
      label: 'YouTube',
      hosts: ['youtube.com', 'www.youtube.com', 'm.youtube.com', 'youtu.be', 'youtube-nocookie.com'],
      iconAsset: 'assets/icons/youtube.png',
    ),
    SourceDef(
      id: 'tiktok',
      label: 'TikTok',
      hosts: ['tiktok.com', 'www.tiktok.com', 'vm.tiktok.com', 'vt.tiktok.com'],
      iconAsset: 'assets/icons/tiktok.png',
    ),
    SourceDef(
      id: 'instagram',
      label: 'Instagram',
      hosts: ['instagram.com', 'www.instagram.com'],
      iconAsset: 'assets/icons/instagram.png',
    ),
    SourceDef(
      id: 'facebook',
      label: 'Facebook',
      hosts: ['facebook.com', 'www.facebook.com', 'm.facebook.com', 'fb.watch', 'fb.com'],
      iconAsset: 'assets/icons/facebook.png',
    ),
    SourceDef(
      id: 'twitter',
      label: 'X (Twitter)',
      hosts: ['twitter.com', 'www.twitter.com', 'x.com', 'www.x.com', 't.co'],
      iconAsset: 'assets/icons/twitter.png',
    ),
  ];

  static SourceDef? findByUrl(String url) {
    final lower = url.toLowerCase();
    for (final s in all) {
      for (final host in s.hosts) {
        if (lower.contains(host)) return s;
      }
    }
    return null;
  }

  static SourceDef? findById(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}

/// Default placeholder server URL.
/// Replace with your own deployment URL — also configurable in Settings.
const String kDefaultServerUrl = 'https://vidsnap-server.example.com';
