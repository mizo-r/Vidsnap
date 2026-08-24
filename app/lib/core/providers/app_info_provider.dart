import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Provides the app's package info (version, build number, app name).
///
/// This is the SINGLE source of truth for the version number.
/// Any widget that needs to display the version should watch this
/// provider instead of hardcoding a version string.
///
/// Usage:
///   final info = ref.watch(packageInfoProvider);
///   Text('Version: ${info.version}');
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

/// Convenience provider that returns just the version string (e.g. "1.1.3").
final appVersionProvider = Provider<String>((ref) {
  final asyncInfo = ref.watch(packageInfoProvider);
  return asyncInfo.when(
    data: (info) => info.version,
    loading: () => '...',
    error: (_, __) => 'unknown',
  );
});
