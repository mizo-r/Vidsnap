import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidsnap/core/constants/app_constants.dart';
import 'package:vidsnap/core/services/link_validator_service.dart';

/// Monitors the system clipboard for supported URLs and emits a notification
/// when one is detected. Avoids spamming the user — only fires when a NEW
/// supported URL appears.
class ClipboardMonitorService {
  ClipboardMonitorService();

  Timer? _timer;
  String? _lastSeen;
  final _controller = StreamController<String>.broadcast();

  Stream<String> get detectedUrls => _controller.stream;

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(AppConstants.clipboardPollInterval, (_) async {
      try {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        final text = data?.text;
        if (text == null || text.isEmpty || text == _lastSeen) return;
        _lastSeen = text;
        final url = LinkValidatorService.extractUrlFromText(text);
        if (url != null && LinkValidatorService.isSupported(url)) {
          _controller.add(url);
        }
      } on PlatformException {
        // Background clipboard reads may throw on Android 10+. Ignore silently.
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}

final clipboardMonitorProvider = Provider<ClipboardMonitorService>((ref) {
  final service = ClipboardMonitorService();
  ref.onDispose(service.dispose);
  return service;
});
