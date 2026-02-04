import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:unified_http_client/dio_api.dart';
import 'package:unified_http_client/http_api.dart';
import 'package:http/http.dart' as http;
import 'package:unified_http_client/internet_checker.dart';
import 'package:unified_http_client/result.dart';
import 'package:unified_http_client/snackbar.dart';
import 'package:unified_http_client/unified_interceptor.dart';
import 'package:unified_http_client/unified_options.dart';

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
  static List<UnifiedInterceptor> _interceptors = <UnifiedInterceptor>[];

  /// default headers configured via [init] and merged
  /// into every request for both http and dio.
  /// Per-call headers passed to get/post/delete/multipart
  /// will override these defaults on a key-by-key basis.
  static Map<String, String> defaultHeaders = <String, String>{};

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
  }) {
    UnifiedHttpClient.useHttp = usehttp ?? true;
    UnifiedHttpClient.showSnackbar = showSnackbar ?? true;
    UnifiedHttpClient.showLogs = showLogs ?? false;
    UnifiedHttpClient._interceptors = <UnifiedInterceptor>[
      ApiInterceptor(showLogs: UnifiedHttpClient.showLogs),
      ...?interceptors,
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
  static Result<String> mapDioResponseToResult(response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Success(jsonEncode(response.data));
    } else {
      switch (response.statusCode) {
        case >= 200 && < 400:
          return Success(jsonEncode(response.data));

        case >= 400 && < 500:
          return _failure400_499(response.statusCode, response);
        case >= 500:
          return _failure500(response.statusCode, response);

        default:
          return const Failure(UnifiedHttpClientEnum.undefined, 'Something went wrong');
      }
    }
  }

  static Failure _failure400_499(int s, res) {
    switch (s) {
      case 400:
        return Failure(UnifiedHttpClientEnum.badRequestError, 'Bad Request.. ${res is http.Response ? res.body : res.data}');

      case 401:
        return Failure(UnifiedHttpClientEnum.unAuthorizationError, 'Unauthorized... ${res is http.Response ? res.body : res.data}');
      case 403:
        return Failure(UnifiedHttpClientEnum.forbiddenError, 'Forbidden... ${res is http.Response ? res.body : res.data}');
      case 404:
        return Failure(UnifiedHttpClientEnum.notFoundError, '404 Not Found... ${res is http.Response ? res.body : res.data}');
      case 409:
        return Failure(UnifiedHttpClientEnum.conflictError, '409... ${res is http.Response ? res.body : res.data}');
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
  static Future<Result<String>> get(String endpoint, {int timeout = 3, Map<String, dynamic>? queryPara, Map<String, String>? headers}) async {
    if (!await InternetConnectionChecker().hasConnection) {
      CustomSnackbar().showNoInternetSnackbar();
    }

    // Merge headers: init-level defaults + per-call overrides.
    final mergedHeaders = <String, String>{
      ...defaultHeaders,
      if (headers != null) ...headers,
    };

    if (useHttp) {
      final res = await PackageHttp.getRequest(
        url: PackageHttp.getUriFromEndpoints(endpoint: endpoint, queryParams: queryPara),
        headers: mergedHeaders.isEmpty ? null : mergedHeaders,
      );

      if (res.runtimeType == Failure) {
        return res as Failure;
      }
      debugPrint("api call was on  : ${(res as http.Response).request?.url}");
      return mapHttpResponseToResult(res);
    } else {
      final res = await PackageDio.dioGet(
        urlPath: endpoint,
        headers: mergedHeaders.isEmpty ? null : mergedHeaders,
        queryPara: queryPara,
      );

      if (res.runtimeType == Failure) {
        return res as Failure;
      }
      return mapDioResponseToResult(res);
    }
  }

  /// POST request
  static Future<Result<String>> post(String endpoint,
      {int timeout = 3, Map<String, dynamic>? queryPara, dynamic body, Map<String, String>? headers}) async {
    if (!await InternetConnectionChecker().hasConnection) {
      CustomSnackbar().showNoInternetSnackbar();
    }

    // Merge headers: init-level defaults + per-call overrides.
    final mergedHeaders = <String, String>{
      ...defaultHeaders,
      if (headers != null) ...headers,
    };

    if (useHttp) {
      final res = await PackageHttp.postRequest(
        url: PackageHttp.getUriFromEndpoints(endpoint: endpoint, queryParams: queryPara),
        headers: mergedHeaders.isEmpty ? null : mergedHeaders,
        body: body,
      );

      if (res.runtimeType == Failure) {
        return res as Failure;
      }
      return mapHttpResponseToResult(res);
    } else {
      final res = await PackageDio.dioPost(
        urlPath: endpoint,
        headers: mergedHeaders.isEmpty ? null : mergedHeaders,
        queryPara: queryPara,
      );
      debugPrint("response in post request :$res");
      if (res.runtimeType == Failure) {
        return res as Failure;
      }
      return mapDioResponseToResult(res);
    }
  }

  /// Delete request
  static Future<Result<String>> delete(String endpoint,
      {int timeout = 3, Map<String, dynamic>? queryPara, dynamic body, Map<String, String>? headers}) async {
    if (!await InternetConnectionChecker().hasConnection) {
      CustomSnackbar().showNoInternetSnackbar();
    }

    // Merge headers: init-level defaults + per-call overrides.
    final mergedHeaders = <String, String>{
      ...defaultHeaders,
      if (headers != null) ...headers,
    };

    if (useHttp) {
      final res = await PackageHttp.deleteRequest(
        url: PackageHttp.getUriFromEndpoints(endpoint: endpoint, queryParams: queryPara),
        headers: mergedHeaders.isEmpty ? null : mergedHeaders,
      );

      if (res.runtimeType == Failure) {
        return res as Failure;
      }
      return mapHttpResponseToResult(res);
    } else {
      final res = await PackageDio.dioDelete(
        urlPath: endpoint,
        headers: mergedHeaders.isEmpty ? null : mergedHeaders,
        queryPara: queryPara,
      );
      debugPrint("response in post request :$res");
      if (res.runtimeType == Failure) {
        return res as Failure;
      }
      return mapDioResponseToResult(res);
    }
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
  }) async {
    if (!await InternetConnectionChecker().hasConnection) {
      CustomSnackbar().showNoInternetSnackbar();
    }

    // Merge headers: init-level defaults + per-call overrides.
    final mergedHeaders = <String, String>{
      ...defaultHeaders,
      if (headers != null) ...headers,
    };

    if (useHttp) {
      final res = await PackageHttp.multipartRequest(
        url: PackageHttp.getUriFromEndpoints(endpoint: endpoint, queryParams: queryPara),
        headers: mergedHeaders.isEmpty ? null : mergedHeaders,
        files: files,
        fields: fields,
      );

      if (res.runtimeType == Failure) {
        return res as Failure;
      }
      return mapHttpResponseToResult(res);
    } else {
      final res = await PackageDio.dioMultipart(
        urlPath: endpoint,
        headers: mergedHeaders.isEmpty ? null : mergedHeaders,
        queryPara: queryPara,
        files: files,
        fields: fields,
      );

      if (res.runtimeType == Failure) {
        return res as Failure;
      }
      return mapDioResponseToResult(res);
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
