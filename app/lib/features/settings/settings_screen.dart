import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidsnap/core/constants/colors.dart';
import 'package:vidsnap/core/providers/app_info_provider.dart';
import 'package:vidsnap/core/providers/settings_provider.dart';
import 'package:vidsnap/core/services/download_service.dart';
import 'package:vidsnap/core/services/extraction_service.dart';
import 'package:vidsnap/core/utils/format_utils.dart';
import 'package:vidsnap/data/repositories/download_repository.dart';
import 'package:vidsnap/data/repositories/history_repository.dart';
import 'package:vidsnap/features/about/about_screen.dart';
import 'package:vidsnap/l10n/gen/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _testingServer = false;
  String? _serverStatus;
  final _urlController = TextEditingController();
  bool _urlInitialized = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testServer() async {
    setState(() {
      _testingServer = true;
      _serverStatus = null;
    });
    final url = _urlController.text.trim();
    final ok = await ref.read(extractionServiceProvider).ping(url);
    setState(() {
      _testingServer = false;
      _serverStatus = ok ? 'ok' : 'fail';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ext = VidSnapColorsExtension.of(context);
    final settings = ref.watch(settingsProvider);

    // Initialize the URL controller ONCE with the saved value.
    // On subsequent rebuilds (e.g. after pressing "Save" or "Test"),
    // we do NOT overwrite the controller — the user might be mid-edit.
    // When the user navigates away and comes back, the State is recreated,
    // _urlInitialized resets to false, and the controller picks up the
    // latest saved value from settingsProvider.
    if (!_urlInitialized) {
      _urlController.text = settings.serverUrl;
      _urlInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(l10n.settingsGeneral, ext),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            trailing: DropdownButton<String>(
              value: settings.language,
              items: [
                DropdownMenuItem(value: 'system', child: Text(l10n.settingsLanguageSystem)),
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
              ],
              onChanged: (v) async {
                if (v == null) return;
                await ref.read(settingsProvider.notifier).update((s) => s.copyWith(language: v));
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: Text(l10n.settingsTheme),
            trailing: DropdownButton<String>(
              value: settings.themeMode,
              items: [
                DropdownMenuItem(value: 'dark', child: Text(l10n.settingsThemeDark)),
                DropdownMenuItem(value: 'light', child: Text(l10n.settingsThemeLight)),
                DropdownMenuItem(value: 'system', child: Text(l10n.settingsThemeSystem)),
              ],
              onChanged: (v) async {
                if (v == null) return;
                await ref.read(settingsProvider.notifier).update((s) => s.copyWith(themeMode: v));
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(l10n.settingsSaveFolder),
            subtitle: Text(settings.defaultSaveFolder),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () async {
              final picked = await FilePicker.platform.getDirectoryPath();
              if (picked == null) return;
              await ref.read(settingsProvider.notifier).update((s) => s.copyWith(defaultSaveFolder: picked));
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () async {
                  await ref.read(settingsProvider.notifier).update(
                        (s) => s.copyWith(defaultSaveFolder: 'Vidsnap/download'),
                      );
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(l10n.settingsSaveFolderReset),
              ),
            ),
          ),
          _SectionHeader(l10n.settingsDownloads, ext),
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text(l10n.settingsMaxConcurrent),
            trailing: DropdownButton<int>(
              value: settings.maxConcurrentDownloads,
              items: [1, 2, 3, 4]
                  .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                  .toList(),
              onChanged: (v) async {
                if (v == null) return;
                await ref.read(settingsProvider.notifier).update((s) => s.copyWith(maxConcurrentDownloads: v));
              },
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.content_paste),
            title: Text(l10n.settingsClipboardMonitoring),
            subtitle: Text(l10n.settingsClipboardMonitoringDesc),
            value: settings.clipboardMonitoringEnabled,
            onChanged: (v) async {
              await ref.read(settingsProvider.notifier).update((s) => s.copyWith(clipboardMonitoringEnabled: v));
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(l10n.settingsNotifications),
            subtitle: Text(l10n.settingsNotificationsDesc),
            value: settings.notificationsEnabled,
            onChanged: (v) async {
              await ref.read(settingsProvider.notifier).update((s) => s.copyWith(notificationsEnabled: v));
            },
          ),
          _SectionHeader(l10n.settingsServer, ext),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: l10n.settingsServerUrl,
                    hintText: l10n.settingsServerUrlHint,
                    prefixIcon: const Icon(Icons.dns_outlined),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _testingServer ? null : _testServer,
                      icon: _testingServer
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.network_check),
                      label: Text(l10n.settingsServerTest),
                    ),
                    FilledButton.icon(
                      onPressed: () async {
                        final url = _urlController.text.trim();
                        if (url.isEmpty) return;
                        // Persist to Hive AND update state synchronously.
                        await ref.read(settingsProvider.notifier).update(
                              (s) => s.copyWith(serverUrl: url),
                            );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.settingsSaved)),
                          );
                        }
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: Text(l10n.commonSave),
                    ),
                    if (_serverStatus == 'ok')
                      Icon(Icons.check_circle, color: ext.success, size: 20)
                    else if (_serverStatus == 'fail')
                      Icon(Icons.error, color: ext.error, size: 20),
                  ],
                ),
                if (_serverStatus == 'ok')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.settingsServerOk,
                      style: TextStyle(color: ext.success, fontSize: 12),
                    ),
                  )
                else if (_serverStatus == 'fail')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.settingsServerFail,
                      style: TextStyle(color: ext.error, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          _SectionHeader(l10n.settingsStorage, ext),
          FutureBuilder<int>(
            future: ref.watch(downloadServiceProvider).tempFilesSize(),
            builder: (context, snapshot) {
              final size = snapshot.data ?? 0;
              return ListTile(
                leading: const Icon(Icons.cleaning_services_outlined),
                title: Text(l10n.settingsClearCache),
                subtitle: Text(
                  '${l10n.settingsCacheSize}: ${FormatUtils.bytes(size)}',
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.settingsClearCache),
                      content: Text(l10n.settingsClearCacheConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(l10n.commonCancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(l10n.commonConfirm),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  final freed = await ref.read(downloadServiceProvider).clearAllTempFiles();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.settingsCacheCleared(FormatUtils.bytes(freed)),
                        ),
                        backgroundColor: VidSnapColors.success,
                      ),
                    );
                    setState(() {});
                  }
                },
              );
            },
          ),
          _SectionHeader(l10n.settingsAbout, ext),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.aboutTitle),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
          // Version — read dynamically from package_info_plus.
          Consumer(
            builder: (context, ref, _) {
              final version = ref.watch(appVersionProvider);
              return ListTile(
                leading: const Icon(Icons.tag),
                title: Text(l10n.settingsVersion),
                trailing: Text(
                  version,
                  style: TextStyle(color: ext.muted, fontSize: 14),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: VidSnapColors.error),
            title: Text(
              l10n.settingsClearData,
              style: const TextStyle(color: VidSnapColors.error),
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  content: Text(l10n.settingsClearDataConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.commonCancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.commonConfirm),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              await ref.read(downloadRepositoryProvider).clearAll();
              await ref.read(historyRepositoryProvider).clearAll();
              await ref.read(settingsProvider.notifier).reset();
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text, this.ext);
  final String text;
  final VidSnapColorsExtension ext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          color: ext.muted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
