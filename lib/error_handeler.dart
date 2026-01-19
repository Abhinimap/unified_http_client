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
  static bool showLogs = false;
  static List<UnifiedInterceptor> _interceptors = <UnifiedInterceptor>[];

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
    useHttp = usehttp ?? true;
    showSnackbar = showSnackbar ?? true;
    showLogs = showLogs ?? false;
    _interceptors = <UnifiedInterceptor>[
      ApiInterceptor(showLogs: UnifiedHttpClient.showLogs),
      ...?interceptors,
    ];

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
  static Result mapHttpResponseToResult(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Success(response);
    } else {
      switch (response.statusCode) {
        case >= 200 && < 400:
          return Success(response.body);

        case >= 400 && < 500:
          return _failure400_499(response.statusCode, response);
        case >= 500:
          return _failure500(response.statusCode, response);

        default:
          return Failure(ErrorResponse(
              unifiedHttpClientEnum: UnifiedHttpClientEnum.undefined,
              errorResponseHolder: ErrorResponseHolder(defaultMessage: 'Something went wrong', responseBody: response.body)));
      }
    }
  }

  /// map Dio response into Result
  static Result mapDioResponseToResult(response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Success(response);
    } else {
      switch (response.statusCode) {
        case >= 200 && < 400:
          return Success(response.data);

        case >= 400 && < 500:
          return _failure400_499(response.statusCode, response);
        case >= 500:
          return _failure500(response.statusCode, response);

        default:
          return Failure(ErrorResponse(
              unifiedHttpClientEnum: UnifiedHttpClientEnum.undefined,
              errorResponseHolder: ErrorResponseHolder(defaultMessage: 'Something went wrong', responseBody: response.body)));
      }
    }
  }

  static Failure _failure400_499(int s, res) {
    switch (s) {
      case 400:
        return Failure(
          ErrorResponse(
              unifiedHttpClientEnum: UnifiedHttpClientEnum.badRequestError,
              errorResponseHolder: ErrorResponseHolder(
                  defaultMessage: 'Bad Request..',
                  responseBody: res.body,
                  customMessage: 'Bad Request.. ${res is http.Response ? res.body : res.data}')),
        );
      case 401:
        return Failure(
          ErrorResponse(
              unifiedHttpClientEnum: UnifiedHttpClientEnum.unAuthorizationError,
              errorResponseHolder: ErrorResponseHolder(
                  defaultMessage: 'You are not authorized to access this resources..',
                  responseBody: res.body,
                  customMessage: 'Unauthorized... ${res is http.Response ? res.body : res.data}')),
        );
      case 403:
        return Failure(
          ErrorResponse(
              unifiedHttpClientEnum: UnifiedHttpClientEnum.forbiddenError,
              errorResponseHolder: ErrorResponseHolder(
                  defaultMessage: 'You are restricted to access this resources..',
                  responseBody: res.body,
                  customMessage: 'Forbidden... ${res is http.Response ? res.body : res.data}')),
        );
      case 404:
        return Failure(
          ErrorResponse(
              unifiedHttpClientEnum: UnifiedHttpClientEnum.notFoundError,
              errorResponseHolder: ErrorResponseHolder(
                  defaultMessage: 'Resource want not find at ${res.request?.url}..',
                  responseBody: res.body,
                  customMessage: '404 Not Found... ${res is http.Response ? res.body : res.data}')),
        );
      case 409:
        return Failure(
          ErrorResponse(
              unifiedHttpClientEnum: UnifiedHttpClientEnum.conflictError,
              errorResponseHolder: ErrorResponseHolder(
                  defaultMessage: 'data Conflicted', responseBody: res.body, customMessage: '409... ${res is http.Response ? res.body : res.data}')),
        );
      default:
        return Failure(ErrorResponse(
            errorResponseHolder: ErrorResponseHolder(
              defaultMessage: 'Something went wrong',
              customMessage: 'Error : ${res.body}',
              responseBody: res.body,
            ),
            unifiedHttpClientEnum: UnifiedHttpClientEnum.undefined));
    }
  }

  static Failure _failure500(int s, res) {
    switch (s) {
      case 500:
        return Failure(
          ErrorResponse(
              unifiedHttpClientEnum: UnifiedHttpClientEnum.internalServerError,
              errorResponseHolder: ErrorResponseHolder(
                  defaultMessage: 'Internal Server Error..',
                  responseBody: res.body,
                  customMessage: 'Internal Server Error.. ${res is http.Response ? res.body : res.data}')),
        );
      case 501:
        return Failure(
          ErrorResponse(
              unifiedHttpClientEnum: UnifiedHttpClientEnum.serverNotSupportError,
              errorResponseHolder: ErrorResponseHolder(
                  defaultMessage: 'Server does not support this functionality',
                  responseBody: res.body,
                  customMessage: 'server not supported... ${res is http.Response ? res.body : res.data}')),
        );
      case 503:
        return Failure(
          ErrorResponse(
              unifiedHttpClientEnum: UnifiedHttpClientEnum.serverUnavailableError,
              errorResponseHolder: ErrorResponseHolder(
                  responseBody: res.body,
                  defaultMessage: 'Server Not Available..',
                  customMessage: 'Server Not available... ${res is http.Response ? res.body : res.data}')),
        );
      case 504:
        return Failure(
          ErrorResponse(
              unifiedHttpClientEnum: UnifiedHttpClientEnum.serverGatewayTimeOut,
              errorResponseHolder: ErrorResponseHolder(
                  defaultMessage: 'server time out on ${res.request?.url}..',
                  responseBody: res.body,
                  customMessage: 'server request time out.. ${res is http.Response ? res.body : res.data}')),
        );

      default:
        return Failure(ErrorResponse(
            errorResponseHolder: ErrorResponseHolder(
              defaultMessage: 'Something went wrong',
              customMessage: 'Error on ${res.request?.url}',
              responseBody: res.body,
            ),
            unifiedHttpClientEnum: UnifiedHttpClientEnum.undefined));
    }
  }

  /// get request
  static Future<Result> get(String endpoint, {int timeout = 3, Map<String, dynamic>? queryPara, Map<String, String>? headers}) async {
    if (!await InternetConnectionChecker().hasConnection) {
      CustomSnackbar().showNoInternetSnackbar();
    }
    if (useHttp) {
      final res = await PackageHttp.getRequest(
        url: PackageHttp.getUriFromEndpoints(endpoint: endpoint, queryParams: queryPara),
        headers: headers,
      );

      if (res.runtimeType == Failure) {
        return res as Failure;
      }
      debugPrint("api call was on  : ${(res as http.Response).request?.url}");
      return mapHttpResponseToResult(res);
    } else {
      final res = await PackageDio.dioGet(urlPath: endpoint, headers: headers, queryPara: queryPara);

      if (res.runtimeType == Failure) {
        return res as Failure;
      }
      return mapDioResponseToResult(res);
    }
  }

  /// POST request
  static Future<Result> post(String endpoint, {int timeout = 3, Map<String, dynamic>? queryPara, dynamic body, Map<String, String>? headers}) async {
    if (!await InternetConnectionChecker().hasConnection) {
      CustomSnackbar().showNoInternetSnackbar();
    }
    if (useHttp) {
      final res = await PackageHttp.postRequest(
        url: PackageHttp.getUriFromEndpoints(endpoint: endpoint, queryParams: queryPara),
        headers: headers,
        body: body,
      );

      if (res.runtimeType == Failure) {
        return res as Failure;
      }
      return mapHttpResponseToResult(res);
    } else {
      final res = await PackageDio.dioPost(urlPath: endpoint, headers: headers, queryPara: queryPara);
      debugPrint("response in post request :$res");
      if (res.runtimeType == Failure) {
        return res as Failure;
      }
      return mapDioResponseToResult(res);
    }
  }

  /// Delete request
  static Future<Result> delete(String endpoint,
      {int timeout = 3, Map<String, dynamic>? queryPara, dynamic body, Map<String, String>? headers}) async {
    if (!await InternetConnectionChecker().hasConnection) {
      CustomSnackbar().showNoInternetSnackbar();
    }
    if (useHttp) {
      final res = await PackageHttp.deleteRequest(
        url: PackageHttp.getUriFromEndpoints(endpoint: endpoint, queryParams: queryPara),
        headers: headers,
      );

      if (res.runtimeType == Failure) {
        return res as Failure;
      }
      return mapHttpResponseToResult(res);
    } else {
      final res = await PackageDio.dioDelete(urlPath: endpoint, headers: headers, queryPara: queryPara);
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
  static Future<Result> multipart(
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
    if (useHttp) {
      final res = await PackageHttp.multipartRequest(
        url: PackageHttp.getUriFromEndpoints(endpoint: endpoint, queryParams: queryPara),
        headers: headers,
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
        headers: headers,
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
