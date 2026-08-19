import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidsnap/core/constants/colors.dart';
import 'package:vidsnap/core/services/whatsapp_status_service.dart';
import 'package:vidsnap/data/models/whatsapp_status.dart';
import 'package:vidsnap/features/whatsapp/status_preview_screen.dart';
import 'package:vidsnap/l10n/gen/app_localizations.dart';

/// State provider for the list of WhatsApp statuses currently displayed.
final whatsappStatusesProvider =
    StateNotifierProvider<WhatsAppStatusNotifier, AsyncValue<List<WhatsAppStatus>>>((ref) {
  return WhatsAppStatusNotifier(ref);
});

class WhatsAppStatusNotifier
    extends StateNotifier<AsyncValue<List<WhatsAppStatus>>> {
  WhatsAppStatusNotifier(this.ref) : super(const AsyncValue.loading());
  final Ref ref;

  Future<void> load({bool business = false}) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(whatsappStatusServiceProvider);
      final hasPermission = await service.hasPermission();
      if (!hasPermission) {
        state = AsyncValue.error('no_permission', StackTrace.current);
        return;
      }
      final list = await service.listStatuses(business: business);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider tracking the WhatsApp Business toggle.
final isBusinessProvider = StateProvider<bool>((ref) => false);

class WhatsAppStatusScreen extends ConsumerStatefulWidget {
  const WhatsAppStatusScreen({super.key});

  @override
  ConsumerState<WhatsAppStatusScreen> createState() => _WhatsAppStatusScreenState();
}

class _WhatsAppStatusScreenState extends ConsumerState<WhatsAppStatusScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _business = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load statuses on first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    await ref.read(whatsappStatusesProvider.notifier).load(business: _business);
  }

  Future<void> _toggleBusiness(bool v) async {
    setState(() => _business = v);
    await _reload();
  }

  Future<void> _requestPermission() async {
    final service = ref.read(whatsappStatusServiceProvider);
    final granted = await service.requestPermission();
    if (!granted) {
      if (mounted) {
        await service.openAppSettings();
      }
      return;
    }
    await _reload();
  }

  Future<void> _saveStatus(WhatsAppStatus status) async {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.read(whatsappStatusServiceProvider);
    final result = await service.saveToGallery(status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result != null ? l10n.whatsappSavedToast : l10n.whatsappSaveFailed),
          backgroundColor: result != null ? VidSnapColors.success : VidSnapColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ext = VidSnapColorsExtension.of(context);
    final async = ref.watch(whatsappStatusesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.whatsappTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.whatsappRefresh,
            onPressed: _reload,
          ),
          Switch(
            value: _business,
            onChanged: _toggleBusiness,
            activeThumbColor: VidSnapColors.accent,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.image_outlined), text: l10n.whatsappTabImages),
            Tab(icon: const Icon(Icons.videocam_outlined), text: l10n.whatsappTabVideos),
          ],
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          if (e.toString().contains('no_permission')) {
            return _PermissionPrompt(
              ext: ext,
              l10n: l10n,
              onRequest: _requestPermission,
              onOpenSettings: () => ref.read(whatsappStatusServiceProvider).openAppSettings(),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                e.toString(),
                style: TextStyle(color: ext.error, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
        data: (statuses) {
          if (statuses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.whatsappNoStatuses,
                  style: TextStyle(color: ext.muted, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final images = statuses.where((s) => !s.isVideo).toList();
          final videos = statuses.where((s) => s.isVideo).toList();
          return TabBarView(
            controller: _tabController,
            children: [
              _StatusGrid(items: images, onSave: _saveStatus, ext: ext),
              _StatusGrid(items: videos, onSave: _saveStatus, ext: ext),
            ],
          );
        },
      ),
    );
  }
}

class _PermissionPrompt extends StatelessWidget {
  const _PermissionPrompt({
    required this.ext,
    required this.l10n,
    required this.onRequest,
    required this.onOpenSettings,
  });

  final VidSnapColorsExtension ext;
  final AppLocalizations l10n;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 64, color: ext.accent),
            const SizedBox(height: 16),
            Text(
              l10n.whatsappPermissionNeeded,
              style: TextStyle(
                color: ext.text,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.whatsappPermissionDesc,
              style: TextStyle(color: ext.muted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRequest,
              icon: const Icon(Icons.security),
              label: Text(l10n.whatsappGrantPermission),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onOpenSettings,
              child: Text(l10n.whatsappOpenSettings),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusGrid extends StatelessWidget {
  const _StatusGrid({
    required this.items,
    required this.onSave,
    required this.ext,
  });

  final List<WhatsAppStatus> items;
  final Future<void> Function(WhatsAppStatus) onSave;
  final VidSnapColorsExtension ext;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final status = items[i];
        return _StatusTile(status: status, onSave: onSave, ext: ext);
      },
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.status,
    required this.onSave,
    required this.ext,
  });

  final WhatsAppStatus status;
  final Future<void> Function(WhatsAppStatus) onSave;
  final VidSnapColorsExtension ext;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StatusPreviewScreen(status: status),
          ),
        );
      },
      onLongPress: () => onSave(status),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Thumbnail(status: status),
            // Save button overlay
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => onSave(status),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.download_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            if (status.isVideo)
              const Center(
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 28),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.status});
  final WhatsAppStatus status;

  @override
  Widget build(BuildContext context) {
    final file = File(status.filePath);
    if (status.isVideo) {
      // For videos, we don't have an easy way to extract a frame without
      // a video thumbnailer package. Show a placeholder with the file icon.
      return Container(
        color: Colors.black26,
        child: const Icon(Icons.video_library, color: Colors.white54, size: 32),
      );
    }
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.black26,
        child: const Icon(Icons.broken_image, color: Colors.white54, size: 32),
      ),
    );
  }
}
