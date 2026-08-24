import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vidsnap/core/constants/colors.dart';
import 'package:vidsnap/core/providers/app_info_provider.dart';
import 'package:vidsnap/l10n/gen/app_localizations.dart';

/// Hardcoded changelog entries per version, per language.
/// New versions add their entry at the top of the list.
/// This keeps the changelog accessible offline and avoids an extra
/// network call just to show release notes.
const Map<String, Map<String, List<String>>> kChangelog = {
  '1.1.4': {
    'en': [
      'Polished splash screen with multi-stage animation',
      'App restarts when language is changed (proper RTL rebuild)',
      'Smooth page transitions with AnimatedSwitcher',
      'Increased server timeouts for Render cold starts',
      'Visual polish across all screens',
    ],
    'ar': [
      'شاشة بداية مصقولة بأنيميشن متعدد المراحل',
      'إعادة تشغيل التطبيق عند تغيير اللغة (إعادة بناء RTL صحيحة)',
      'انتقالات سلسة بين الصفحات',
      'زيادة مهلة السيرفر لاستيقاظ Render',
      'تحسينات بصرية عبر كل الشاشات',
    ],
  },
  '1.1.3': {
    'en': [
      'Fixed settings not persisting after navigation',
      'Removed Shorebird (was not applying patches reliably)',
      'Added video thumbnails for WhatsApp statuses',
      'Dynamic version display everywhere',
      'RTL layout fixes for Arabic',
    ],
    'ar': [
      'إصلاح مشكلة عدم حفظ الإعدادات بعد التنقل',
      'إزالة Shorebird (لم يكن يطبّق التحديثات بشكل موثوق)',
      'إضافة صور مصغّرة لفيديوهات حالات الواتساب',
      'عرض ديناميكي لرقم النسخة في كل مكان',
      'إصلاحات تخطيط RTL للعربية',
    ],
  },
  '1.1.2': {
    'en': [
      'Added About screen with app info',
      'Added What\'s New changelog',
      'Added Check for Updates feature',
      'Dynamic version display (no more hardcoded 1.0.0)',
    ],
    'ar': [
      'إضافة شاشة "حول" بمعلومات التطبيق',
      'إضافة سجل "ما الجديد"',
      'إضافة ميزة "التحقق من وجود تحديثات"',
      'عرض ديناميكي للإصدار (بدون قيمة ثابتة)',
    ],
  },
  '1.1.1': {
    'en': [
      'Improved stability',
      'Bug fixes',
      'Performance improvements',
    ],
    'ar': [
      'تحسين الاستقرار',
      'إصلاح الأخطاء',
      'تحسينات في الأداء',
    ],
  },
  '1.1.0': {
    'en': [
      'Added WhatsApp status saver',
      'Added dark/light theme support',
      'Added Arabic and English localization',
      'Added FFmpeg-based video + audio merge for HD downloads',
      'Added splash screen',
      'Added cache management in Settings',
    ],
    'ar': [
      'إضافة حفظ حالات الواتساب',
      'دعم الوضع الداكن/الفاتح',
      'دعم اللغتين العربية والإنجليزية',
      'دمج الفيديو والصوت بـ FFmpeg لتنزيلات HD',
      'إضافة شاشة البداية',
      'إدارة التخزين المؤقت في الإعدادات',
    ],
  },
  '1.0.0': {
    'en': [
      'Initial release',
      'Video downloader with link paste',
      'Background downloads with pause/resume',
      'Smart notifications',
    ],
    'ar': [
      'الإصدار الأولي',
      'تنزيل الفيديو عبر لصق الرابط',
      'تنزيلات خلفية مع إيقاف/استئناف',
      'إشعارات ذكية',
    ],
  },
};

/// Returns the changelog entries for [version] in the user's [locale].
/// Falls back to English if the locale's language isn't available.
List<String> changelogForVersion(String version, String locale) {
  final entry = kChangelog[version];
  if (entry == null) return const [];
  return entry[locale] ?? entry['en'] ?? const [];
}

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ext = VidSnapColorsExtension.of(context);
    final version = ref.watch(appVersionProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          _AppHeader(ext: ext, l10n: l10n),
          const SizedBox(height: 24),
          _InfoRow(
            label: l10n.aboutDevelopedBy,
            value: 'mizofly',
            ext: ext,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _InfoRow(
            label: l10n.aboutVersion,
            value: version,
            ext: ext,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.new_releases_outlined),
            title: Text(l10n.aboutWhatsNew),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _WhatsNewScreen(version: version),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.system_update_alt),
            title: Text(l10n.aboutCheckForUpdates),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const _CheckUpdatesScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.ext, required this.l10n});
  final VidSnapColorsExtension ext;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: VidSnapColors.accent.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assets/icons/app_icon.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'VidSnap',
          style: TextStyle(
            color: ext.text,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            l10n.aboutTagline,
            textAlign: TextAlign.center,
            style: TextStyle(color: ext.muted, fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.ext,
  });
  final String label;
  final String value;
  final VidSnapColorsExtension ext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: ext.muted, fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              color: ext.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// What's New screen — shows the changelog for the current version
/// and any newer versions that exist in the changelog map.
class _WhatsNewScreen extends StatelessWidget {
  const _WhatsNewScreen({required this.version});
  final String version;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ext = VidSnapColorsExtension.of(context);
    // Use the current locale's language code to pick the right changelog.
    final locale = l10n.localeName;

    final allVersions = kChangelog.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    var visibleVersions =
        allVersions.where((v) => v.compareTo(version) >= 0).toList();
    if (visibleVersions.isEmpty) {
      visibleVersions = allVersions.take(1).toList();
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutWhatsNew)),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: visibleVersions.length,
        itemBuilder: (ctx, i) {
          final v = visibleVersions[i];
          final entries = changelogForVersion(v, locale);
          return _VersionSection(
            version: v,
            entries: entries,
            ext: ext,
            isCurrent: v == version,
          );
        },
      ),
    );
  }
}

class _VersionSection extends StatelessWidget {
  const _VersionSection({
    required this.version,
    required this.entries,
    required this.ext,
    required this.isCurrent,
  });
  final String version;
  final List<String> entries;
  final VidSnapColorsExtension ext;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'v$version',
                style: TextStyle(
                  color: ext.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ext.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.aboutCurrentVersion,
                    style: TextStyle(
                      color: ext.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ...entries.map(
            (e) => Padding(
              padding: const EdgeInsetsDirectional.only(start: 8, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(Icons.fiber_manual_record, size: 8, color: ext.muted),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e,
                      style: TextStyle(color: ext.text, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Check for Updates screen — queries the GitHub Releases API and
/// compares the latest release tag with the currently installed version.
class _CheckUpdatesScreen extends ConsumerStatefulWidget {
  const _CheckUpdatesScreen();

  @override
  ConsumerState<_CheckUpdatesScreen> createState() =>
      _CheckUpdatesScreenState();
}

class _CheckUpdatesScreenState extends ConsumerState<_CheckUpdatesScreen> {
  bool _checking = false;
  String? _latestVersion;
  String? _releaseUrl;
  String? _errorMessage;

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _errorMessage = null;
      _latestVersion = null;
      _releaseUrl = null;
    });

    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      final response = await _dio.get<dynamic>(
        'https://api.github.com/repos/mizo-r/Vidsnap/releases/latest',
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final body = response.data is String
          ? response.data as String
          : jsonEncode(response.data);
      final json = jsonDecode(body) as Map<String, dynamic>;
      final tagName = (json['tag_name'] as String?)?.replaceAll('v', '') ?? '';
      final htmlUrl = json['html_url'] as String? ?? '';

      setState(() {
        _latestVersion = tagName.isEmpty ? null : tagName;
        _releaseUrl = htmlUrl.isEmpty ? null : htmlUrl;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _checking = false;
      });
    }
  }

  /// Returns true if [latest] is a newer version than [current].
  /// Supports "x.y.z" format. Comparison is numeric per part.
  bool _isNewer(String latest, String current) {
    final lParts = latest.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final cParts = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final l = i < lParts.length ? lParts[i] : 0;
      final c = i < cParts.length ? cParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ext = VidSnapColorsExtension.of(context);
    final currentVersion = ref.watch(appVersionProvider);

    final updateAvailable = _latestVersion != null &&
        _isNewer(_latestVersion!, currentVersion);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutCheckForUpdates)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _StatusCard(
              checking: _checking,
              currentVersion: currentVersion,
              latestVersion: _latestVersion,
              updateAvailable: updateAvailable,
              errorMessage: _errorMessage,
              ext: ext,
              l10n: l10n,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _checking ? null : _check,
              icon: _checking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.refresh),
              label: Text(l10n.aboutCheckButton),
            ),
            if (updateAvailable && _releaseUrl != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(_releaseUrl!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.download_rounded),
                label: Text(l10n.aboutDownloadUpdate),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.checking,
    required this.currentVersion,
    required this.latestVersion,
    required this.updateAvailable,
    required this.errorMessage,
    required this.ext,
    required this.l10n,
  });

  final bool checking;
  final String currentVersion;
  final String? latestVersion;
  final bool updateAvailable;
  final String? errorMessage;
  final VidSnapColorsExtension ext;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final IconData statusIcon;
    final String title;
    final String subtitle;

    if (checking) {
      statusColor = ext.accent;
      statusIcon = Icons.hourglass_top;
      title = l10n.aboutChecking;
      subtitle = l10n.aboutCheckingDesc;
    } else if (errorMessage != null) {
      statusColor = ext.error;
      statusIcon = Icons.error_outline;
      title = l10n.aboutCheckFailed;
      subtitle = errorMessage!;
    } else if (latestVersion == null) {
      statusColor = ext.muted;
      statusIcon = Icons.info_outline;
      title = l10n.aboutNotChecked;
      subtitle = l10n.aboutNotCheckedDesc;
    } else if (updateAvailable) {
      statusColor = ext.success;
      statusIcon = Icons.system_update_alt;
      title = l10n.aboutUpdateAvailable;
      subtitle = l10n.aboutUpdateAvailableDesc(latestVersion!);
    } else {
      statusColor = ext.success;
      statusIcon = Icons.check_circle_outline;
      title = l10n.aboutUpToDate;
      subtitle = l10n.aboutUpToDateDesc(currentVersion);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(statusIcon, color: statusColor, size: 48),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: ext.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: ext.muted, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
          if (!checking && latestVersion != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${l10n.aboutCurrentLabel}: v$currentVersion',
                  style: TextStyle(color: ext.muted, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Text(
                  '${l10n.aboutLatestLabel}: v$latestVersion',
                  style: TextStyle(
                    color: updateAvailable ? ext.success : ext.muted,
                    fontSize: 12,
                    fontWeight:
                        updateAvailable ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
