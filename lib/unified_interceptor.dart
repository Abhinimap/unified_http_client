import 'dart:async';
import 'package:flutter/foundation.dart';

/// Lightweight request model used by unified interceptors.
class UnifiedRequest {
  UnifiedRequest({
    required this.method,
    required this.uri,
    Map<String, String>? headers,
    this.body,
  }) : headers = headers ??
            <String, String>{
              'Content-Type': 'application/json',
              'accept': 'text/plain',
            };

  final String method;
  Uri uri;
  Map<String, String> headers;
  dynamic body;

  /// Optional timestamp that can be used by interceptors
  /// (e.g. for measuring request duration).
  DateTime? startedAt;
}

/// Lightweight response model used by unified interceptors.
class UnifiedResponse {
  UnifiedResponse({
    required this.statusCode,
    this.data,
    Map<String, dynamic>? headers,
    this.request,
  }) : headers = headers ?? <String, dynamic>{};

  final int? statusCode;
  final Map<String, dynamic> headers;
  final UnifiedRequest? request;
  dynamic data;
}

/// Lightweight error model used by unified interceptors.
class UnifiedError {
  UnifiedError({
    required this.error,
    this.stackTrace,
    this.request,
    this.response,
  });

  final Object error;
  final StackTrace? stackTrace;
  final UnifiedRequest? request;
  final UnifiedResponse? response;
}

/// Base contract that mirrors the Dio interceptor shape, usable for both http and dio.
abstract class UnifiedInterceptor {
  FutureOr<UnifiedRequest> onRequest(UnifiedRequest request) => request;

  FutureOr<UnifiedResponse> onResponse(UnifiedResponse response) => response;

  FutureOr<UnifiedError> onError(UnifiedError error) => error;
}

/// Default API interceptor with optional logging and override hooks.
class ApiInterceptor extends UnifiedInterceptor {
  ApiInterceptor({
    this.showLogs = false,
    this.onRequestOverride,
    this.onResponseOverride,
    this.onErrorOverride,
  });

  final bool showLogs;
  final FutureOr<UnifiedRequest> Function(UnifiedRequest)? onRequestOverride;
  final FutureOr<UnifiedResponse> Function(UnifiedResponse)? onResponseOverride;
  final FutureOr<UnifiedError> Function(UnifiedError)? onErrorOverride;

  @override
  FutureOr<UnifiedRequest> onRequest(UnifiedRequest request) async {
    if (showLogs) {
      debugPrint('[UnifiedHttpClient] → ${request.method} ${request.uri}');
      if (request.headers.isNotEmpty) {
        debugPrint('[UnifiedHttpClient] headers: ${request.headers}');
      }
      if (request.body != null) {
        debugPrint('[UnifiedHttpClient] body: ${request.body}');
      }
    }
    return onRequestOverride?.call(request) ?? request;
  }

  @override
  FutureOr<UnifiedResponse> onResponse(UnifiedResponse response) async {
    if (showLogs) {
      debugPrint('[UnifiedHttpClient] ← status ${response.statusCode}');
      if (response.data != null) {
        debugPrint('[UnifiedHttpClient] response: ${response.data}');
      }
    }
    return onResponseOverride?.call(response) ?? response;
  }

  @override
  FutureOr<UnifiedError> onError(UnifiedError error) async {
    if (showLogs) {
      debugPrint('[UnifiedHttpClient] ✕ error: ${error.error}');
      if (error.response != null) {
        debugPrint('[UnifiedHttpClient] error response: ${error.response?.data}');
      }
    }
    return onErrorOverride?.call(error) ?? error;
  }
}

/// Runs interceptor chains sequentially.
class UnifiedInterceptorRunner {
  static Future<UnifiedRequest> runOnRequest(
    UnifiedRequest request,
    List<UnifiedInterceptor> interceptors,
  ) async {
    var current = request;
    for (final interceptor in interceptors) {
      current = await interceptor.onRequest(current);
    }
    return current;
  }

  static Future<UnifiedResponse> runOnResponse(
    UnifiedResponse response,
    List<UnifiedInterceptor> interceptors,
  ) async {
    var current = response;
    for (final interceptor in interceptors) {
      current = await interceptor.onResponse(current);
    }
    return current;
  }

  static Future<UnifiedError> runOnError(
    UnifiedError error,
    List<UnifiedInterceptor> interceptors,
  ) async {
    var current = error;
    for (final interceptor in interceptors) {
      current = await interceptor.onError(current);
    }
    return current;
  }
}
