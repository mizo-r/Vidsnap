import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Generates and caches video thumbnails using FFmpeg.
///
/// FFmpeg extracts a single frame at the 1-second mark, scales it to
/// 320px wide (preserving aspect ratio), and saves it as JPEG.
/// Thumbnails are cached in the app's temp directory so they're only
/// generated once per video.
class VideoThumbnailService {
  VideoThumbnailService._();

  static final VideoThumbnailService _instance = VideoThumbnailService._();
  factory VideoThumbnailService() => _instance;

  final Map<String, String?> _cache = {};

  /// Returns the path to a cached thumbnail for [videoPath], or null
  /// if thumbnail generation failed.
  ///
  /// The thumbnail is generated on first call and cached in memory
  /// and on disk for subsequent calls.
  Future<String?> getThumbnail(String videoPath) async {
    // Check in-memory cache first
    if (_cache.containsKey(videoPath)) {
      return _cache[videoPath];
    }

    final tempDir = await getTemporaryDirectory();
    final thumbDir = Directory(p.join(tempDir.path, 'video_thumbnails'));
    if (!thumbDir.existsSync()) {
      thumbDir.createSync(recursive: true);
    }

    // Use a hash of the video path to generate a unique thumbnail filename
    final thumbName = videoPath.hashCode.toString() + '.jpg';
    final thumbPath = p.join(thumbDir.path, thumbName);

    // Check if thumbnail already exists on disk
    final thumbFile = File(thumbPath);
    if (await thumbFile.exists()) {
      _cache[videoPath] = thumbPath;
      return thumbPath;
    }

    // Generate thumbnail using FFmpeg:
    // -ss 00:00:01  : seek to 1 second
    // -vframes 1    : extract only 1 frame
    // -vf scale=320:-1 : scale to 320px wide, preserve aspect ratio
    final cmd = '-i "$videoPath" -ss 00:00:01 -vframes 1 -vf "scale=320:-1" -y "$thumbPath"';
    final session = await FFmpegKit.execute(cmd);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode) && await thumbFile.exists()) {
      _cache[videoPath] = thumbPath;
      return thumbPath;
    }

    // Failed to generate thumbnail
    _cache[videoPath] = null;
    return null;
  }

  /// Clears the in-memory cache. Disk cache is preserved.
  void clearMemoryCache() {
    _cache.clear();
  }
}
