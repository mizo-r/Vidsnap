/// Small helpers used across the app.
class FormatUtils {
  FormatUtils._();

  /// Pretty-prints a byte count as B/KB/MB/GB.
  static String bytes(int? bytes, {int decimals = 1}) {
    if (bytes == null || bytes == 0) return '—';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return unit == 0
        ? '${size.toInt()} ${units[unit]}'
        : '${size.toStringAsFixed(decimals)} ${units[unit]}';
  }

  /// Formats a duration as `m:ss` or `h:mm:ss`.
  static String duration(int? seconds) {
    if (seconds == null || seconds <= 0) return '—';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Formats a DateTime as `yyyy-MM-dd HH:mm`.
  static String dateTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  /// Sanitizes a string for use as a file name.
  static String sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[\\/:*?"<>|\n\r\t]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
