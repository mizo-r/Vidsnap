import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidsnap/core/constants/colors.dart';
import 'package:vidsnap/core/services/download_service.dart';
import 'package:vidsnap/core/utils/format_utils.dart';
import 'package:vidsnap/data/models/extract_response.dart';
import 'package:vidsnap/l10n/gen/app_localizations.dart';

/// Modal bottom sheet that shows video info + quality picker + sticky download button.
/// Implements the design spec from the project plan section 3.2.
class DownloaderSheet extends ConsumerStatefulWidget {
  const DownloaderSheet({super.key, required this.response});

  final ExtractResponse response;

  @override
  ConsumerState<DownloaderSheet> createState() => _DownloaderSheetState();
}

class _DownloaderSheetState extends ConsumerState<DownloaderSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _nameController = TextEditingController();
  FormatOption? _selected;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nameController.text = FormatUtils.sanitizeFileName(widget.response.title);
    // Pre-select the recommended format, or the first muxed format available.
    final formats = widget.response.formats;
    _selected = formats.firstWhere((f) => f.recommended, orElse: () {
      return formats.firstWhere(
        (f) => f.kind == FormatKind.muxed,
        orElse: () => formats.first,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  List<FormatOption> get _videoFormats => widget.response.formats
      .where((f) => f.kind != FormatKind.audio)
      .toList();
  List<FormatOption> get _audioFormats => widget.response.formats
      .where((f) => f.kind == FormatKind.audio)
      .toList();

  Future<void> _startDownload() async {
    if (_selected == null) return;
    final fileName = FormatUtils.sanitizeFileName(_nameController.text);
    await ref.read(downloadServiceProvider).enqueue(
          sourceId: widget.response.sourceId,
          originalUrl: widget.response.originalUrl,
          videoTitle: widget.response.title,
          customFileName: fileName.isEmpty ? widget.response.title : fileName,
          formatId: _selected!.formatId,
          quality: _selected!.label,
          extension: _selected!.extension,
          downloadUrl: _selected!.downloadUrl,
          thumbnailUrl: widget.response.thumbnail,
          totalBytes: _selected!.fileSizeBytes,
        );
    if (mounted) Navigator.of(context).maybePop();
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
          maxHeight: MediaQuery.of(context).size.height * 0.7,
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
                suffixText: '.${_selected?.extension ?? ''}',
              ),
            ),
            const SizedBox(height: 16),
            // Tab bar: Video / Audio
            if (_videoFormats.isNotEmpty && _audioFormats.isNotEmpty)
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: l10n.downloaderVideoTab),
                  Tab(text: l10n.downloaderAudioTab),
                ],
              ),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _FormatList(
                    formats: _videoFormats,
                    selected: _selected,
                    onSelect: (f) => setState(() => _selected = f),
                  ),
                  _FormatList(
                    formats: _audioFormats,
                    selected: _selected,
                    onSelect: (f) => setState(() => _selected = f),
                  ),
                ],
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
                    onPressed: _startDownload,
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

class _FormatList extends StatelessWidget {
  const _FormatList({
    required this.formats,
    required this.selected,
    required this.onSelect,
  });

  final List<FormatOption> formats;
  final FormatOption? selected;
  final ValueChanged<FormatOption> onSelect;

  @override
  Widget build(BuildContext context) {
    final ext = VidSnapColorsExtension.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (formats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.downloaderNoFormats,
            style: TextStyle(color: ext.muted),
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: formats.length,
      itemBuilder: (ctx, i) {
        final f = formats[i];
        final isSelected = selected?.formatId == f.formatId;
        return RadioListTile<String>(
          value: f.formatId,
          groupValue: selected?.formatId,
          onChanged: (_) => onSelect(f),
          activeColor: ext.accent,
          dense: true,
          title: Row(
            children: [
              if (f.recommended)
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
                  f.label,
                  style: TextStyle(
                    color: ext.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            '${FormatUtils.bytes(f.fileSizeBytes)} · ${f.extension.toUpperCase()}',
            style: TextStyle(color: ext.muted, fontSize: 12),
          ),
        );
      },
    );
  }
}
