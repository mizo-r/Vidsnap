import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidsnap/core/providers/settings_provider.dart';
import 'package:vidsnap/data/models/extract_response.dart';
import 'package:vidsnap/data/repositories/settings_repository.dart';

/// Talks to the extraction server's `POST /extract` endpoint.
class ExtractionService {
  ExtractionService(this._dio);

  final Dio _dio;

  Future<ExtractResponse> extract({
    required String serverUrl,
    required String videoUrl,
  }) async {
    final normalizedUrl = serverUrl.replaceAll(RegExp(r'/+$'), '');
    final response = await _dio.post(
      '$normalizedUrl/extract',
      data: {'url': videoUrl},
      options: Options(
        // Render Free Tier sleeps after 15 min of inactivity and takes
        // ~30s to wake up on the first request. Give it plenty of time.
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    if (response.statusCode != 200) {
      throw ExtractionException(
        (response.data is Map ? response.data['error'] : null) as String? ?? 'Extraction failed',
      );
    }
    return ExtractResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<bool> ping(String serverUrl) async {
    try {
      final normalizedUrl = serverUrl.replaceAll(RegExp(r'/+$'), '');
      final response = await _dio.get(
        '$normalizedUrl/health',
        options: Options(
          // Render Free Tier takes ~30s to wake up. Allow 60s to be safe.
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

class ExtractionException implements Exception {
  ExtractionException(this.message);
  final String message;
  @override
  String toString() => message;
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  dio.interceptors.add(LogInterceptor(
    requestBody: false,
    responseBody: false,
    error: true,
  ));
  return dio;
});

final extractionServiceProvider = Provider<ExtractionService>((ref) {
  return ExtractionService(ref.watch(dioProvider));
});

/// Convenience: returns the current server URL from settingsProvider.
final serverUrlProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).serverUrl;
});
