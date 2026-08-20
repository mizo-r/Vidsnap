import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidsnap/core/constants/colors.dart';
import 'package:vidsnap/core/services/download_service.dart';
import 'package:vidsnap/core/utils/format_utils.dart';
import 'package:vidsnap/data/models/extract_response.dart';
import 'package:vidsnap/l10n/gen/app_localizations.dart';

/// Modal bottom sheet that shows video info + quality picker + sticky download button.
/// Two sections: Audio (top) and Video (bottom). Each section shows only the
/// qualities that are actually available for this video.
class DownloaderSheet extends ConsumerStatefulWidget {
  const DownloaderSheet({super.key, required this.response});

  final ExtractResponse response;

  @override
  ConsumerState<DownloaderSheet> createState() => _DownloaderSheetState();
}

class _DownloaderSheetState extends ConsumerState<DownloaderSheet> {
  final _nameController = TextEditingController();

  /// Currently selected format. Can be a video FormatOption or an AudioFormat.
  /// `selectedAudioId` is set when an audio option is selected.
  FormatOption? _selectedVideo;
  AudioFormat? _selectedAudio;

  @override
  void initState() {
    super.initState();
    _nameController.text = FormatUtils.sanitizeFileName(widget.response.title);

    // Pre-select recommended video (720p usually), else first available.
    final videos = widget.response.formats;
    if (videos.isNotEmpty) {
      _selectedVideo = videos.firstWhere(
        (f) => f.recommended,
        orElse: () => videos.first,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _startDownload() async {
    final fileName = FormatUtils.sanitizeFileName(_nameController.text);
    final safeName = fileName.isEmpty ? widget.response.title : fileName;

    if (_selectedAudio != null) {
      // Audio-only download
      final a = _selectedAudio!;
      await ref.read(downloadServiceProvider).enqueue(
            sourceId: widget.response.sourceId,
            originalUrl: widget.response.originalUrl,
            videoTitle: widget.response.title,
            customFileName: safeName,
            formatId: a.formatId,
            quality: a.label,
            extension: a.extension,
            downloadUrl: a.downloadUrl,
            thumbnailUrl: widget.response.thumbnail,
            totalBytes: a.fileSizeBytes,
            requiresMerge: false,
          );
    } else if (_selectedVideo != null) {
      final v = _selectedVideo!;
      if (v.requiresMerge) {
        // Merge download — find best audio from response
        final bestAudio = widget.response.audioFormats.isNotEmpty
            ? widget.response.audioFormats.first
            : null;
        if (bestAudio == null) {
          // No audio available — can't merge
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No audio format available for merge'),
                backgroundColor: VidSnapColors.error,
              ),
            );
          }
          return;
        }
        await ref.read(downloadServiceProvider).enqueue(
              sourceId: widget.response.sourceId,
              originalUrl: widget.response.originalUrl,
              videoTitle: widget.response.title,
              customFileName: safeName,
              formatId: v.formatId,
              quality: v.label,
              extension: 'mp4',
              downloadUrl: v.downloadUrl,
              videoUrl: v.videoUrl,
              audioUrl: bestAudio.downloadUrl,
              thumbnailUrl: widget.response.thumbnail,
              totalBytes: v.fileSizeBytes,
              requiresMerge: true,
              videoTotalBytes: v.fileSizeBytes,
              audioTotalBytes: bestAudio.fileSizeBytes,
            );
      } else {
        // Direct muxed download
        await ref.read(downloadServiceProvider).enqueue(
              sourceId: widget.response.sourceId,
              originalUrl: widget.response.originalUrl,
              videoTitle: widget.response.title,
              customFileName: safeName,
              formatId: v.formatId,
              quality: v.label,
              extension: v.extension,
              downloadUrl: v.downloadUrl,
              thumbnailUrl: widget.response.thumbnail,
              totalBytes: v.fileSizeBytes,
              requiresMerge: false,
            );
      }
    } else {
      return;
    }

    if (mounted) Navigator.of(context).maybePop();
  }

  bool get _canDownload => _selectedAudio != null || _selectedVideo != null;

  String get _selectedExtension {
    if (_selectedAudio != null) return _selectedAudio!.extension;
    if (_selectedVideo != null) {
      return _selectedVideo!.requiresMerge ? 'mp4' : _selectedVideo!.extension;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ext = VidSnapColorsExtension.of(context);
    final res = widget.response;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ext.muted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Video preview header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: res.thumbnail != null
                      ? Image.network(
                          res.thumbnail!,
                          width: 80,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 56,
                            color: ext.surface,
                            child: Icon(Icons.video_library, color: ext.muted),
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 56,
                          color: ext.surface,
                          child: Icon(Icons.video_library, color: ext.muted),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        res.title,
                        style: TextStyle(
                          color: ext.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          res.sourceLabel,
                          if (res.durationSeconds != null)
                            FormatUtils.duration(res.durationSeconds),
                          if (res.uploader != null) res.uploader,
                        ].join(' · '),
                        style: TextStyle(color: ext.muted, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Editable file name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.downloaderFileName,
                prefixIcon: const Icon(Icons.edit, size: 20),
                suffixText: '.${_selectedExtension}',
              ),
            ),
            const SizedBox(height: 16),
            // Scrollable format list
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // === Audio section ===
                    if (res.audioFormats.isNotEmpty) ...[
                      _SectionHeader(
                        icon: Icons.music_note,
                        title: l10n.downloaderAudioSection,
                        ext: ext,
                      ),
                      ...res.audioFormats.map((a) => _AudioTile(
                            audio: a,
                            isSelected: _selectedAudio?.formatId == a.formatId,
                            onSelect: () {
                              setState(() {
                                _selectedAudio = a;
                                _selectedVideo = null;
                              });
                            },
                          )),
                      const SizedBox(height: 12),
                    ],
                    // === Video section ===
                    if (res.formats.isNotEmpty) ...[
                      _SectionHeader(
                        icon: Icons.videocam,
                        title: l10n.downloaderVideoSection,
                        ext: ext,
                      ),
                      ...res.formats.map((v) => _VideoTile(
                            video: v,
                            isSelected: _selectedVideo?.formatId == v.formatId &&
                                _selectedAudio == null,
                            onSelect: () {
                              setState(() {
                                _selectedVideo = v;
                                _selectedAudio = null;
                              });
                            },
                          )),
                    ],
                    // === No formats at all ===
                    if (res.formats.isEmpty && res.audioFormats.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.downloaderNoFormats,
                          style: TextStyle(color: ext.muted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Sticky action bar
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(l10n.downloaderCancel),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _canDownload ? _startDownload : null,
                    icon: const Icon(Icons.download_rounded),
                    label: Text(l10n.downloaderDownload),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.ext,
  });

  final IconData icon;
  final String title;
  final VidSnapColorsExtension ext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: ext.accent),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              color: ext.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioTile extends StatelessWidget {
  const _AudioTile({
    required this.audio,
    required this.isSelected,
    required this.onSelect,
  });

  final AudioFormat audio;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final ext = VidSnapColorsExtension.of(context);
    return RadioListTile<String>(
      value: audio.formatId,
      groupValue: isSelected ? audio.formatId : null,
      onChanged: (_) => onSelect(),
      activeColor: ext.accent,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(
        audio.label,
        style: TextStyle(
          color: ext.text,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${FormatUtils.bytes(audio.fileSizeBytes)} · ${audio.extension.toUpperCase()}',
        style: TextStyle(color: ext.muted, fontSize: 12),
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({
    required this.video,
    required this.isSelected,
    required this.onSelect,
  });

  final FormatOption video;
  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final ext = VidSnapColorsExtension.of(context);
    final l10n = AppLocalizations.of(context)!;
    return RadioListTile<String>(
      value: video.formatId,
      groupValue: isSelected ? video.formatId : null,
      onChanged: (_) => onSelect(),
      activeColor: ext.accent,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Row(
        children: [
          if (video.recommended)
            Container(
              margin: const EdgeInsetsDirectional.only(end: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ext.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.downloaderRecommended,
                style: TextStyle(
                  color: ext.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Flexible(
            child: Text(
              video.label,
              style: TextStyle(
                color: ext.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (video.requiresMerge) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ext.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.downloaderMergeRequired,
                style: TextStyle(
                  color: ext.warning,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        '${FormatUtils.bytes(video.fileSizeBytes)} · ${video.extension.toUpperCase()}',
        style: TextStyle(color: ext.muted, fontSize: 12),
      ),
    );
  }
}
