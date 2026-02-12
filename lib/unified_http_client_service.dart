import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:unified_http_client/dio_api.dart';
import 'package:unified_http_client/http_api.dart';
import 'package:http/http.dart' as http;
import 'package:unified_http_client/internet_checker.dart';
import 'package:unified_http_client/result.dart';
import 'package:unified_http_client/snackbar.dart';
import 'package:unified_http_client/src/package_logger.dart';
import 'package:unified_http_client/unified_interceptor.dart';
import 'package:unified_http_client/unified_options.dart';
import 'package:unified_http_client/network_logger.dart';

/// A class to provide error Handeling functionality
/// This uses Http as default Scheme and showSnackbar is default set to True
/// When APi call through get method of this class and internet is not available , A sncakbar will appear on the screen
/// Call init method of this class after Materialapp is Initialized and pass parameter to configure as per your choice
class UnifiedHttpClient {
  /// default set to True
  static bool useHttp = true;

  /// default set to True
  static bool showSnackbar = true;

  /// enable console logs
  static bool showLogs = false;

  /// Optional endpoint for refresh token
  static String? refreshTokenEndpoint;

  /// Optional list of endpoints to monitor for 401 errors
  static List<String>? refreshWhitelist;

  /// Callback to handle refresh token logic.
  /// Receives a [retryAction] that can be used to retry the original request.
  /// Should return true if refresh was successful and the package should retry the original request.
  static Future<bool> Function(Future<Result<String>> Function() retryAction)? onRefreshToken;

  /// Callback for handling session termination
  static VoidCallback? onLogout;

  static List<UnifiedInterceptor> _interceptors = <UnifiedInterceptor>[];

  /// default headers configured via [init] and merged
  /// into every request for both http and dio.
  /// Per-call headers passed to get/post/delete/multipart
  /// will override these defaults on a key-by-key basis.
  static Map<String, String> defaultHeaders = <String, String>{};

  /// Replace or merge global default headers at runtime.
  /// Useful for things like setting/changing auth tokens after login.
  ///
  /// If [merge] is true (default), the provided [headers] are merged into the
  /// existing [defaultHeaders]. Existing keys are overwritten by the new ones.
  /// If [merge] is false, the previous [defaultHeaders] are discarded.
  static void setDefaultHeaders(Map<String, String> headers, {bool merge = true}) {
    if (merge) {
      defaultHeaders = {
        ...defaultHeaders,
        ...headers,
      };
    } else {
      defaultHeaders = Map<String, String>.from(headers);
    }
  }

  /// Convenience helper to set a single default header key/value at runtime.
  static void setDefaultHeader(String key, String value) {
    defaultHeaders[key] = value;
  }

  /// Remove a single default header key at runtime.
  static void removeDefaultHeader(String key) {
    defaultHeaders.remove(key);
  }

  /// Clear all default headers that were configured via [init] or setters.
  static void clearDefaultHeaders() {
    defaultHeaders.clear();
  }

  /// by default it will use http and show snackbar
  void init({
    bool? usehttp,
    bool? showSnackbar,
    bool? showLogs,
    List<UnifiedInterceptor>? interceptors,
    String? baseUrl,
    Map<String, dynamic>? queryParameters,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Map<String, Object?>? extra,
    Map<String, Object?>? headers,
    UnifiedResponseType? responseType,
    String? contentType,
    bool? followRedirects,
    int? maxRedirects,
    bool? persistentConnection,
    String? refreshTokenEndpoint,
    List<String>? refreshWhitelist,
    Future<bool> Function(Future<Result<String>> Function() retryAction)? onRefreshToken,
    VoidCallback? onLogout,
  }) {
    UnifiedHttpClient.useHttp = usehttp ?? true;
    UnifiedHttpClient.showSnackbar = showSnackbar ?? true;
    UnifiedHttpClient.showLogs = showLogs ?? false;
    UnifiedHttpClient.refreshTokenEndpoint = refreshTokenEndpoint;
    UnifiedHttpClient.refreshWhitelist = refreshWhitelist;
    UnifiedHttpClient.onRefreshToken = onRefreshToken;
    UnifiedHttpClient.onLogout = onLogout;

    UnifiedHttpClient._interceptors = <UnifiedInterceptor>[
      ApiInterceptor(showLogs: UnifiedHttpClient.showLogs),
      ...?interceptors,
      NetworkLogInterceptor(),
    ];

    // Normalize and store default headers (shared by http & dio).
    // Values are converted to String to satisfy both clients.
    UnifiedHttpClient.defaultHeaders = {
      if (headers != null)
        for (final entry in headers.entries)
          if (entry.value != null) entry.key: entry.value.toString(),
    };

    // DIO Setup
    if (!useHttp) {
      PackageDio.addInterceptors(_interceptors);
      PackageDio.setBaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: headers,
        responseType: responseType,
        contentType: contentType,
        extra: extra,
        followRedirects: followRedirects,
        maxRedirects: maxRedirects,
        persistentConnection: persistentConnection,
        queryParameters: queryParameters,
        sendTimeout: sendTimeout,
      );
      PackageDio.setUpDio();
    }

    // HTTP Setup
    else {
      PackageHttp.setup(host: baseUrl ?? '');
      PackageHttp.configureInterceptors(_interceptors);
    }
  }

  /// map response into Result
  static Result<String> mapHttpResponseToResult(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Success(response.body);
    } else {
      switch (response.statusCode) {
        case >= 200 && < 400:
          return Success(response.body);
        case >= 400 && < 500:
          return _failure400_499(response.statusCode, response);
        case >= 500:
          return _failure500(response.statusCode, response);

        default:
          return const Failure(UnifiedHttpClientEnum.undefined, 'Something went wrong');
      }
    }
  }

  /// map Dio response into Result
  static Result<String> mapDioResponseToResult(Response response) {
    PackageLogger.log('handling response of dio : ${response.runtimeType}');
    final statusCode = (response.statusCode ?? 0);
    if (statusCode >= 200 && statusCode < 300) {
      return Success(jsonEncode(response.data));
    } else {
      switch (statusCode) {
        case >= 200 && < 400:
          return Success(jsonEncode(response.data));
        case >= 400 && < 500:
          return _failure400_499(statusCode, response);
        case >= 500:
          return _failure500(statusCode, response);
        default:
          return const Failure(UnifiedHttpClientEnum.undefined, 'Something went wrong');
      }
    }
  }

  static Failure _failure400_499(int s, res) {
    switch (s) {
      case 400:
        return Failure(UnifiedHttpClientEnum.badRequestError, '${res is http.Response ? res.body : res.data}');

      case 401:
        return Failure(UnifiedHttpClientEnum.unAuthorizationError, '${res is http.Response ? res.body : res.data}');
      case 403:
        return Failure(UnifiedHttpClientEnum.forbiddenError, '${res is http.Response ? res.body : res.data}');
      case 404:
        return Failure(UnifiedHttpClientEnum.notFoundError, '${res is http.Response ? res.body : res.data}');
      case 409:
        return Failure(UnifiedHttpClientEnum.conflictError, '${res is http.Response ? res.body : res.data}');
      default:
        return const Failure(UnifiedHttpClientEnum.undefined, 'something went wrong...');
    }
  }

  static Failure _failure500(int s, res) {
    switch (s) {
      case 500:
        return Failure(UnifiedHttpClientEnum.internalServerError, 'Internal Server Error.. ${res is http.Response ? res.body : res.data}');
      case 501:
        return Failure(UnifiedHttpClientEnum.serverNotSupportError, 'server not supported... ${res is http.Response ? res.body : res.data}');
      case 503:
        return Failure(UnifiedHttpClientEnum.serverUnavailableError, 'Server Not available... ${res is http.Response ? res.body : res.data}');
      case 504:
        return Failure(UnifiedHttpClientEnum.serverGatewayTimeOut, 'server request time out.. ${res is http.Response ? res.body : res.data}');

      default:
        return const Failure(UnifiedHttpClientEnum.undefined, 'something went wrong...');
    }
  }

  /// get request
  static Future<Result<String>> get(String endpoint,
      {int timeout = 3, Map<String, dynamic>? queryPara, Map<String, String>? headers, bool isRetry = false}) async {
    if (!await InternetConnectionChecker().hasConnection) {
      CustomSnackbar().showNoInternetSnackbar();
    }

    // Merge headers: init-level defaults + per-call overrides.
    final mergedHeaders = <String, String>{
      ...defaultHeaders,
      if (headers != null) ...headers,
    };

    Result<String> result;
    if (useHttp) {
      final res = await PackageHttp.getRequest(
        url: PackageHttp.getUriFromEndpoints(endpoint: endpoint, queryParams: queryPara),
        headers: mergedHeaders.isEmpty ? null : mergedHeaders,
      );

      if (res.runtimeType == Failure) {
        result = res as Failure;
      } else {
        PackageLogger.log("api call was on  : ${(res as http.Response).request?.url}");
        result = mapHttpResponseToResult(res);
      }
    } else {
      final res = await PackageDio.dioGet(
        urlPath: endpoint,
        headers: mergedHeaders.isEmpty ? null : mergedHeaders,
        queryPara: queryPara,
      );
      result = res.fold((l) {
        return l;
      }, (r) {
        return mapDioResponseToResult(r);
      });
    }

    if (result is Failure && result.unifiedHttpClientEnum == UnifiedHttpClientEnum.unAuthorizationError && !isRetry) {
      return await handle401(
        result,
        () => get(endpoint, timeout: timeout, queryPara: queryPara, headers: headers, isRetry: true),
        endpoint,
      );
    }
    return result;
  }

  /// POST request
  static Future<Result<String>> post(String endpoint,
      {int timeout = 3, Map<String, dynamic>? queryPara, dynamic body, Map<String, String>? headers, bool isRetry = false}) async {
    if (!await InternetConnectionChecker().hasConnection) {
      CustomSnackbar().showNoInternetSnackbar();
    }

    // Merge headers: init-level defaults + per-call overrides.
    final mergedHeaders = <String, String>{
      ...defaultHeaders,
      if (headers != null) ...headers,
    };

    Result<String> result;
    if (useHttp) {
      final res = await PackageHttp.postRequest(
        url: PackageHttp.getUriFromEndpoints(endpoint: endpoint, queryParams: queryPara),
        headers: mergedHeaders.isEmpty ? null : mergedHeaders,
        body: body,
      );

      if (res.runtimeType == Failure) {
        result = res as Failure;
      } else {
        result = mapHttpResponseToResult(res);
      }
    } else {
      final res = await PackageDio.dioPost(
        urlPath: endpoint,
        headers: mergedHeaders.isEmpty ? null : mergedHeaders,
        queryPara: queryPara,
      );
      result = res.fold((l) {
        return l;
      }, (r) {
        return mapDioResponseToResult(r);
      });
    }

    if (result is Failure && result.unifiedHttpClientEnum == UnifiedHttpClientEnum.unAuthorizationError && !isRetry) {
      return await handle401(
        result,
        () => post(endpoint, timeout: timeout, queryPara: queryPara, body: body, headers: headers, isRetry: true),
        endpoint,
      );
    }
    return result;
  }

  /// Delete request
  static Future<Result<String>> delete(String endpoint,
      {int timeout = 3, Map<String, dynamic>? queryPara, dynamic body, Map<String, String>? headers, bool isRetry = false}) async {
    if (!await InternetConnectionChecker().hasConnection) {
      CustomSnackbar().showNoInternetSnackbar();
    }

    // Merge headers: init-level defaults + per-call overrides.
    final mergedHeaders = <String, String>{
      ...defaultHeaders,
      if (headers != null) ...headers,
    };

    Result<String> result;
    if (useHttp) {
      final res = await PackageHttp.deleteRequest(
        url: PackageHttp.getUriFromEndpoints(endpoint: endpoint, queryParams: queryPara),
        headers: mergedHeaders.isEmpty ? null : mergedHeaders,
      );

      if (res.runtimeType == Failure) {
        result = res as Failure;
      } else {
        result = mapHttpResponseToResult(res);
      }
    } else {
      final res = await PackageDio.dioDelete(
        urlPath: endpoint,
        headers: mergedHeaders.isEmpty ? null : mergedHeaders,
        queryPara: queryPara,
      );
      result = res.fold((l) {
        return l;
      }, (r) {
        return mapDioResponseToResult(r);
      });
    }

    if (result is Failure && result.unifiedHttpClientEnum == UnifiedHttpClientEnum.unAuthorizationError && !isRetry) {
      return await handle401(
        result,
        () => delete(endpoint, timeout: timeout, queryPara: queryPara, body: body, headers: headers, isRetry: true),
        endpoint,
      );
    }
    return result;
  }

  /// Multipart request for file uploads
  /// Example:
  /// ```dart
  /// final result = await UnifiedHttpClient.multipart(
  ///   '/upload',
  ///   files: {
  ///     'image': {
  ///       'path': '/path/to/image.jpg',
  ///       'filename': 'image.jpg',
  ///     },
  ///   },
  ///   fields: {
  ///     'title': 'My Image',
  ///     'description': 'Image description',
  ///   },
  /// );
  /// ```
  static Future<Result<String>> multipart(
    String endpoint, {
    int timeout = 3,
    Map<String, dynamic>? queryPara,
    Map<String, String>? headers,
    Map<String, Map<String, dynamic>>? files,
    Map<String, String>? fields,
    bool isRetry = false,
  }) async {
    if (!await InternetConnectionChecker().hasConnection) {
      CustomSnackbar().showNoInternetSnackbar();
    }

    // Merge headers: init-level defaults + per-call overrides.
    final mergedHeaders = <String, String>{
      ...defaultHeaders,
      if (headers != null) ...headers,
    };

    Result<String> result;
    if (useHttp) {
      final res = await PackageHttp.multipartRequest(
        url: PackageHttp.getUriFromEndpoints(endpoint: endpoint, queryParams: queryPara),
        headers: mergedHeaders.isEmpty ? null : mergedHeaders,
        files: files,
        fields: fields,
      );

      if (res.runtimeType == Failure) {
        result = res as Failure;
      } else {
        result = mapHttpResponseToResult(res);
      }
    } else {
      final res = await PackageDio.dioMultipart(
        urlPath: endpoint,
        headers: mergedHeaders.isEmpty ? null : mergedHeaders,
        queryPara: queryPara,
        files: files,
        fields: fields,
      );
      result = res.fold((l) {
        return l;
      }, (r) {
        return mapDioResponseToResult(r);
      });
    }

    if (result is Failure && result.unifiedHttpClientEnum == UnifiedHttpClientEnum.unAuthorizationError && !isRetry) {
      return await handle401(
        result,
        () => multipart(endpoint, timeout: timeout, queryPara: queryPara, headers: headers, files: files, fields: fields, isRetry: true),
        endpoint,
      );
    }
    return result;
  }

  /// Handles 401 UnAuthorization errors by attempting to refresh the token
  /// or calling the logout callback.
  static Future<Result<String>> handle401(
    Failure failure,
    Future<Result<String>> Function() retryAction,
    String endpoint,
  ) async {
    // 1. Intercept 401 status codes before returning error (Already done by caller)

    // 2. Check if we are already on the refresh endpoint to avoid infinite loop
    if (refreshTokenEndpoint != null && (endpoint == refreshTokenEndpoint || endpoint.endsWith(refreshTokenEndpoint!))) {
      onLogout?.call();
      return failure;
    }

    // 3. Check if current endpoint matches the whitelist (if provided)
    // If list is empty/null: Trigger refresh callback for ALL 401 errors
    bool isInWhitelist = refreshWhitelist == null ||
        refreshWhitelist!.isEmpty ||
        refreshWhitelist!.any((e) => endpoint == e || endpoint.endsWith(e));

    // 4. If refresh endpoint is configured
    if (isInWhitelist && refreshTokenEndpoint != null && refreshTokenEndpoint!.isNotEmpty) {
      if (onRefreshToken != null) {
        // Execute refresh token callback
        final success = await onRefreshToken!(retryAction);

        if (success) {
          // If refresh succeeds: Retry the original request with new token
          return await retryAction();
        } else {
          // If refresh fails (and didn't already trigger logout via 401 on refresh endpoint)
          onLogout?.call();
          return failure;
        }
      } else {
        // No callback provided but endpoint configured
        onLogout?.call();
        return failure;
      }
    }

    // 5. If refresh endpoint is empty or not in whitelist: Directly call logout callback
    else {
      onLogout?.call();
      return failure;
    }
  }
}

/// A Class to Hold Error response in Structured manner
class ErrorResponseHolder {
  /// Message pre-defined in package
  String defaultMessage;

  /// Message provided by user in init method
  String? customMessage;

  /// contains response recieved from server
  String? responseBody;

  /// constructor
  ErrorResponseHolder({required this.defaultMessage, this.responseBody, this.customMessage = ''});
}

/// Enum class for all the exceptions and statusCodes
enum UnifiedHttpClientEnum {
  /// 400
  badRequestError,

  /// TimeOut exception
  timeOutError,

  /// 403
  forbiddenError,

  /// 409
  conflictError,

  /// 500
  internalServerError,

  /// 501
  serverNotSupportError,

  /// 503
  serverUnavailableError,

  /// server Gateway TimeOut
  /// The server, acting as a gateway or proxy, did not receive a timely response from an upstream server
  serverGatewayTimeOut,

  /// 401
  unAuthorizationError,

  /// 404
  notFoundError,

  /// When Internet is not available
  noInternetError,

  /// Platform Exception
  platformExceptionError,

  /// SocketException  ( When base Url is no longer active or Internet issue)
  socketExceptionError,

  /// useually thrown when exception caught in Catch block or statusCode/Exception not defined in enum or Unkown to the package
  undefined,

  /// Format Exception
  formatExceptionError,
}
