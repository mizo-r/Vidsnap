import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidsnap/core/constants/app_constants.dart';

/// Wraps `flutter_local_notifications` with sensible defaults for download
/// progress, completion, failure, and clipboard-detected URLs.
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onTap,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            AppConstants.notifChannelId,
            AppConstants.notifChannelName,
            description: AppConstants.notifChannelDesc,
            importance: Importance.low,
            showProgress: true,
          ),
        );
    _initialized = true;
  }

  Future<bool?> requestPermissions() async {
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return android?.requestNotificationsPermission();
    }
    if (Platform.isIOS) {
      return _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: false,
      );
    }
    return null;
  }

  /// Updates the progress notification. Called frequently during download.
  Future<void> showProgress({
    required int id,
    required String title,
    required String message,
    required int progress,
    int? totalBytes,
    int? downloadedBytes,
  }) async {
    if (!_initialized) return;
    await _plugin.show(
      id,
      title,
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notifChannelId,
          AppConstants.notifChannelName,
          channelDescription: AppConstants.notifChannelDesc,
          importance: Importance.low,
          priority: Priority.low,
          showProgress: true,
          maxProgress: 100,
          progress: progress,
          onlyAlertOnce: true,
          ongoing: true,
          indeterminate: totalBytes == null,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: 'progress:$id',
    );
  }

  Future<void> showComplete({
    required int id,
    required String title,
    required String message,
  }) async {
    if (!_initialized) return;
    await _plugin.show(
      id,
      title,
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notifChannelId,
          AppConstants.notifChannelName,
          channelDescription: AppConstants.notifChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          showProgress: false,
          ongoing: false,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'complete:$id',
    );
  }

  Future<void> showError({
    required int id,
    required String title,
    required String message,
  }) async {
    if (!_initialized) return;
    await _plugin.show(
      id,
      title,
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notifChannelId,
          AppConstants.notifChannelName,
          channelDescription: AppConstants.notifChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'error:$id',
    );
  }

  Future<void> showClipboardDetected({required String url}) async {
    if (!_initialized) return;
    await _plugin.show(
      9999,
      'Link detected',
      'Tap to open in VidSnap',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notifChannelId,
          AppConstants.notifChannelName,
          channelDescription: AppConstants.notifChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          autoCancel: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: 'clipboard:$url',
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<void> cancelAll() => _plugin.cancelAll();

  void Function(String payload)? onTapPayload;
  void _onTap(NotificationResponse response) {
    onTapPayload?.call(response.payload ?? '');
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
