import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vidsnap/core/constants/colors.dart';
import 'package:vidsnap/core/utils/format_utils.dart';
import 'package:vidsnap/data/repositories/history_repository.dart';
import 'package:vidsnap/l10n/gen/app_localizations.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ext = VidSnapColorsExtension.of(context);
    final repo = ref.watch(historyRepositoryProvider);
    final items = repo.all;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: l10n.historyClearAll,
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    content: Text(l10n.historyClearConfirm),
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
                if (confirmed == true) await repo.clearAll();
              },
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Text(
                l10n.historyEmpty,
                style: TextStyle(color: ext.muted, fontSize: 14),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (ctx, i) {
                final item = items[i];
                final fileExists = File(item.filePath).existsSync();
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ext.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_circle, color: VidSnapColors.success, size: 22),
                  ),
                  title: Text(
                    item.fileName,
                    style: TextStyle(
                      color: ext.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [
                      item.sourceId,
                      item.quality,
                      FormatUtils.bytes(item.fileSizeBytes),
                      FormatUtils.dateTime(item.downloadedAt),
                    ].join(' · '),
                    style: TextStyle(color: ext.muted, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: ext.muted),
                    onSelected: (v) async {
                      switch (v) {
                        case 'open':
                          if (fileExists) await OpenFilex.open(item.filePath);
                          break;
                        case 'share':
                          if (fileExists) {
                            await Share.shareXFiles(
                              [XFile(item.filePath)],
                              text: item.fileName,
                            );
                          }
                          break;
                        case 'delete':
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              content: Text(l10n.historyDeleteFileConfirm),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(l10n.commonCancel),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(l10n.commonDelete),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            if (fileExists) {
                              try {
                                await File(item.filePath).delete();
                              } catch (_) {}
                            }
                            await repo.delete(item.id);
                          }
                          break;
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(value: 'open', child: Text(l10n.commonOpen)),
                      PopupMenuItem(value: 'share', child: Text(l10n.commonShare)),
                      PopupMenuItem(value: 'delete', child: Text(l10n.historyDeleteFile)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
