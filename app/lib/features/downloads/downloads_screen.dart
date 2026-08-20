import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vidsnap/core/constants/colors.dart';
import 'package:vidsnap/core/services/download_service.dart';
import 'package:vidsnap/core/utils/format_utils.dart';
import 'package:vidsnap/data/models/download_task.dart';
import 'package:vidsnap/data/repositories/download_repository.dart';
import 'package:vidsnap/l10n/gen/app_localizations.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.watch(downloadRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navDownloads),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.downloadsActive),
            Tab(text: l10n.downloadsCompleted),
            Tab(text: l10n.downloadsFailed),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TaskList(
            tasks: repo.active,
            emptyText: l10n.downloadsEmpty,
          ),
          _TaskList(
            tasks: repo.completed,
            emptyText: l10n.downloadsEmpty,
            onClearCompleted: () => repo.deleteCompleted(),
          ),
          _TaskList(
            tasks: repo.failed,
            emptyText: l10n.downloadsEmpty,
          ),
        ],
      ),
    );
  }
}

class _TaskList extends ConsumerWidget {
  const _TaskList({
    required this.tasks,
    required this.emptyText,
    this.onClearCompleted,
  });

  final List<DownloadTask> tasks;
  final String emptyText;
  final Future<void> Function()? onClearCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = VidSnapColorsExtension.of(context);
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(color: ext.muted, fontSize: 14),
        ),
      );
    }
    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) => _TaskCard(task: tasks[i]),
        ),
        if (onClearCompleted != null)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: onClearCompleted,
              icon: const Icon(Icons.clear_all),
              label: Text(AppLocalizations.of(context)!.downloadsClearCompleted),
            ),
          ),
      ],
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task});
  final DownloadTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ext = VidSnapColorsExtension.of(context);
    final l10n = AppLocalizations.of(context)!;
    final statusColor = task.isCompleted
        ? ext.success
        : task.isFailed
            ? ext.error
            : ext.accent;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.customFileName,
                  style: TextStyle(
                    color: ext.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                task.quality,
                style: TextStyle(color: ext.muted, fontSize: 12),
              ),
            ],
          ),
          if (task.isActive) ...[
            const SizedBox(height: 8),
            if (task.mergePhase) ...[
              // Merge phase — show spinner + label
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ext.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.downloadsMerging,
                    style: TextStyle(
                      color: ext.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ] else ...[
              LinearProgressIndicator(
                value: task.progressPercent / 100,
                minHeight: 6,
                backgroundColor: ext.muted.withOpacity(0.2),
                color: ext.accent,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${task.progressPercent}%',
                    style: TextStyle(color: ext.muted, fontSize: 12),
                  ),
                  Text(
                    '${FormatUtils.bytes(task.downloadedBytes)} / ${FormatUtils.bytes(task.totalBytes)}',
                    style: TextStyle(color: ext.muted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ] else if (task.isFailed && task.errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              task.errorMessage!,
              style: TextStyle(color: ext.error, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ] else if (task.isCompleted) ...[
            const SizedBox(height: 4),
            Text(
              FormatUtils.bytes(task.totalBytes),
              style: TextStyle(color: ext.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (task.canPause)
                _IconBtn(
                  icon: Icons.pause,
                  label: l10n.downloadsPause,
                  onTap: () => ref.read(downloadServiceProvider).pause(task.id),
                ),
              if (task.canResume)
                _IconBtn(
                  icon: Icons.play_arrow,
                  label: l10n.downloadsResume,
                  onTap: () => ref.read(downloadServiceProvider).resume(task.id),
                ),
              if (task.canRetry)
                _IconBtn(
                  icon: Icons.refresh,
                  label: l10n.downloadsRetry,
                  onTap: () => ref.read(downloadServiceProvider).retry(task.id),
                ),
              if (task.isActive)
                _IconBtn(
                  icon: Icons.close,
                  label: l10n.downloadsCancel,
                  onTap: () => ref.read(downloadServiceProvider).cancel(task.id),
                  color: ext.error,
                ),
              if (task.isCompleted && task.filePath != null) ...[
                _IconBtn(
                  icon: Icons.open_in_new,
                  label: l10n.downloadsOpen,
                  onTap: () => OpenFilex.open(task.filePath!),
                ),
                _IconBtn(
                  icon: Icons.share,
                  label: l10n.downloadsShare,
                  onTap: () => Share.shareXFiles(
                    [XFile(task.filePath!)],
                    text: task.customFileName,
                  ),
                ),
              ],
              _IconBtn(
                icon: Icons.delete_outline,
                label: l10n.downloadsDelete,
                color: ext.error,
                onTap: () => ref.read(downloadRepositoryProvider).delete(task.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: color,
      tooltip: label,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}
