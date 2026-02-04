import 'package:flutter/foundation.dart';
import 'package:unified_http_client/unified_interceptor.dart';

/// Model representing a single network log entry.
/// This is backend-agnostic and works for both http and dio.
class NetworkLogModel {
  final String method;
  final String url;
  final Map<String, dynamic> requestHeaders;
  final dynamic requestBody;
  final Map<String, dynamic> responseHeaders;
  final dynamic responseBody;
  final int statusCode;
  final DateTime timestamp;
  final Duration duration;

  const NetworkLogModel({
    required this.method,
    required this.url,
    required this.requestHeaders,
    this.requestBody,
    required this.responseHeaders,
    this.responseBody,
    required this.statusCode,
    required this.timestamp,
    required this.duration,
  });
}

/// Simple in-memory storage for network logs.
///
/// Your package's http/dio layers write logs here, and the UI reads from it.
/// This keeps the feature self-contained and independent of external
/// state management solutions.
class NetworkLogStorage {
  NetworkLogStorage._internal();

  static final NetworkLogStorage instance = NetworkLogStorage._internal();

  final List<NetworkLogModel> _logs = <NetworkLogModel>[];

  List<NetworkLogModel> getLogs() => List.unmodifiable(_logs);

  void addLog(NetworkLogModel log) {
    _logs.insert(0, log);
    if (kDebugMode) {
      // Optional debug print for quick inspection during development.
      // ignore: avoid_print
      print('[NetworkLog] ${log.method} ${log.url} -> ${log.statusCode} in ${log.duration.inMilliseconds}ms');
    }
  }

  void clear() {
    _logs.clear();
  }
}

/// Unified interceptor that records all HTTP/Dio traffic into [NetworkLogStorage].
///
/// Because it works with [UnifiedRequest]/[UnifiedResponse]/[UnifiedError],
/// it is automatically reused for both http and dio stacks.
class NetworkLogInterceptor extends UnifiedInterceptor {
  @override
  Future<UnifiedRequest> onRequest(UnifiedRequest request) async {
    request.startedAt ??= DateTime.now();
    return request;
  }

  @override
  Future<UnifiedResponse> onResponse(UnifiedResponse response) async {
    final req = response.request;
    if (req != null && response.statusCode != null) {
      final start = req.startedAt ?? DateTime.now();
      final duration = DateTime.now().difference(start);

      NetworkLogStorage.instance.addLog(
        NetworkLogModel(
          method: req.method,
          url: req.uri.toString(),
          requestHeaders: req.headers,
          requestBody: req.body,
          responseHeaders: response.headers,
          responseBody: response.data,
          statusCode: response.statusCode!,
          timestamp: start,
          duration: duration,
        ),
      );
    }
    return response;
  }

  @override
  Future<UnifiedError> onError(UnifiedError error) async {
    final req = error.request;
    final res = error.response;

    if (req != null) {
      final start = req.startedAt ?? DateTime.now();
      final duration = DateTime.now().difference(start);

      NetworkLogStorage.instance.addLog(
        NetworkLogModel(
          method: req.method,
          url: req.uri.toString(),
          requestHeaders: req.headers,
          requestBody: req.body,
          responseHeaders: res?.headers ?? const <String, dynamic>{},
          responseBody: res?.data,
          statusCode: res?.statusCode ?? 0,
          timestamp: start,
          duration: duration,
        ),
      );
    }

    return error;
  }
}


