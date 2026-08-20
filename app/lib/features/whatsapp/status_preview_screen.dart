import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:vidsnap/core/constants/colors.dart';
import 'package:vidsnap/core/services/whatsapp_status_service.dart';
import 'package:vidsnap/core/utils/format_utils.dart';
import 'package:vidsnap/data/models/whatsapp_status.dart';
import 'package:vidsnap/l10n/gen/app_localizations.dart';

/// Full-screen preview of a WhatsApp status with save & share buttons.
class StatusPreviewScreen extends StatefulWidget {
  const StatusPreviewScreen({super.key, required this.status});

  final WhatsAppStatus status;

  @override
  State<StatusPreviewScreen> createState() => _StatusPreviewScreenState();
}

class _StatusPreviewScreenState extends State<StatusPreviewScreen> {
  VideoPlayerController? _videoController;
  bool _initialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.status.isVideo) {
      _videoController = VideoPlayerController.file(File(widget.status.filePath))
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _initialized = true);
            _videoController!.play();
            _videoController!.setLooping(true);
          }
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final service = WhatsAppStatusService();
    final result = await service.saveToGallery(widget.status);
    if (mounted) {
      setState(() => _saving = false);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result != null ? l10n.whatsappSavedToast : l10n.whatsappSaveFailed),
          backgroundColor: result != null ? VidSnapColors.success : VidSnapColors.error,
        ),
      );
    }
  }

  Future<void> _share() async {
    await Share.shareXFiles(
      [XFile(widget.status.filePath)],
      text: widget.status.fileName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          widget.status.fileName,
          style: const TextStyle(fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_rounded),
            tooltip: l10n.whatsappSave,
            onPressed: _saving ? null : _save,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: l10n.commonShare,
            onPressed: _share,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.status.isVideo
                ? (_initialized && _videoController != null
                    ? Center(
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()))
                : InteractiveViewer(
                    child: Center(
                      child: Image.file(
                        File(widget.status.filePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
          ),
          // Footer info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black87,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  FormatUtils.bytes(widget.status.sizeBytes),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  FormatUtils.dateTime(widget.status.modifiedAt),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
