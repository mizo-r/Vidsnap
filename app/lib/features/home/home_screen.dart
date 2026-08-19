import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vidsnap/core/constants/colors.dart';
import 'package:vidsnap/core/services/extraction_service.dart';
import 'package:vidsnap/core/services/link_validator_service.dart';
import 'package:vidsnap/core/utils/format_utils.dart';
import 'package:vidsnap/data/models/download_task.dart';
import 'package:vidsnap/data/repositories/download_repository.dart';
import 'package:vidsnap/features/downloader/downloader_sheet.dart';
import 'package:vidsnap/l10n/gen/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _urlController = TextEditingController();
  bool _extracting = false;
  String? _error;
  String? _sharedUrl;

  @override
  void initState() {
    super.initState();
    _maybeReceiveSharedText();
  }

  Future<void> _maybeReceiveSharedText() async {
    // If the app was opened via SEND intent, the URL may be delivered via
    // platform channel. For simplicity we read clipboard on first launch.
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && LinkValidatorService.isSupported(data!.text!)) {
      // Don't auto-fill — just show a hint.
      setState(() {});
    }
  }

  Future<void> _onExtract() async {
    final url = _urlController.text.trim();
    final l10n = AppLocalizations.of(context)!;
    if (url.isEmpty) return;

    if (!LinkValidatorService.isValidUrl(url)) {
      setState(() => _error = l10n.homeExtractError);
      return;
    }
    if (!LinkValidatorService.isSupported(url)) {
      setState(() => _error = l10n.homeUnsupportedSource);
      return;
    }

    setState(() {
      _extracting = true;
      _error = null;
    });

    try {
      final serverUrl = ref.read(serverUrlProvider);
      final result = await ref.read(extractionServiceProvider).extract(
            serverUrl: serverUrl,
            videoUrl: url,
          );
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) => DownloaderSheet(response: result),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _extracting = false);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _urlController.text = data!.text!;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ext = VidSnapColorsExtension.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Hero(ext: ext),
              const SizedBox(height: 24),
              _PasteBar(
                controller: _urlController,
                onPaste: _pasteFromClipboard,
                onSubmit: _onExtract,
                extracting: _extracting,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: ext.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 28),
              _QuickActions(ext: ext),
              const SizedBox(height: 28),
              _RecentDownloads(ext: ext),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.ext});
  final VidSnapColorsExtension ext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: VidSnapColors.accentGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeWelcomeTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.homeWelcomeSubtitle,
            style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _PasteBar extends StatelessWidget {
  const _PasteBar({
    required this.controller,
    required this.onPaste,
    required this.onSubmit,
    required this.extracting,
  });

  final TextEditingController controller;
  final Future<void> Function() onPaste;
  final Future<void> Function() onSubmit;
  final bool extracting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.homePasteHint,
            prefixIcon: const Icon(Icons.link),
            suffixIcon: IconButton(
              icon: const Icon(Icons.content_paste),
              onPressed: onPaste,
            ),
          ),
          keyboardType: TextInputType.url,
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: extracting ? null : onSubmit,
          icon: extracting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.download_rounded),
          label: Text(extracting ? l10n.homeExtracting : l10n.homePasteLink),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.ext});
  final VidSnapColorsExtension ext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = [
      _QuickAction(
        icon: Icons.chat_bubble_rounded,
        label: l10n.homeQuickActionWhatsApp,
        color: const Color(0xFF25D366),
        onTap: () => context.push('/whatsapp'),
      ),
      _QuickAction(
        icon: Icons.download_rounded,
        label: l10n.homeQuickActionDownloads,
        color: ext.accent,
        onTap: () => context.push('/downloads'),
      ),
      _QuickAction(
        icon: Icons.history_rounded,
        label: l10n.homeQuickActionHistory,
        color: const Color(0xFF9B59B6),
        onTap: () => context.push('/history'),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeQuickActions,
          style: TextStyle(
            color: ext.muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: actions
              .map((a) => Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: a,
                  )))
              .toList(),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ext = VidSnapColorsExtension.of(context);
    return Material(
      color: ext.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: ext.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentDownloads extends ConsumerWidget {
  const _RecentDownloads({required this.ext});
  final VidSnapColorsExtension ext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.watch(downloadRepositoryProvider);
    final recent = repo.all.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeRecentDownloads,
          style: TextStyle(
            color: ext.muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                l10n.homeNoDownloads,
                style: TextStyle(color: ext.muted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...recent.map((t) => _DownloadRow(task: t)),
      ],
    );
  }
}

class _DownloadRow extends StatelessWidget {
  const _DownloadRow({required this.task});
  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    final ext = VidSnapColorsExtension.of(context);
    final statusColor = task.isCompleted
        ? ext.success
        : task.isFailed
            ? ext.error
            : ext.accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              task.isCompleted
                  ? Icons.check_circle
                  : task.isFailed
                      ? Icons.error_outline
                      : Icons.downloading,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.customFileName,
                  style: TextStyle(
                    color: ext.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${task.quality} · ${FormatUtils.bytes(task.totalBytes)}',
                  style: TextStyle(color: ext.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (task.isActive)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                value: task.progressPercent / 100,
                strokeWidth: 2,
                color: ext.accent,
              ),
            ),
        ],
      ),
    );
  }
}
