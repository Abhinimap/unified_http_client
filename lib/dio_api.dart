import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:unified_http_client/unified_http_client_service.dart';
import 'package:unified_http_client/result.dart';
import 'package:unified_http_client/unified_interceptor.dart';
import 'package:unified_http_client/unified_options.dart';

/// use this class to do
/// DIO APi Request
class PackageDio {
  PackageDio._();
  static final Dio _dio = Dio();
  static BaseOptions? _baseOptions = BaseOptions();
  static List<UnifiedInterceptor> _unifiedInterceptors = <UnifiedInterceptor>[];

  /// setup dio
  static void setUpDio() {
    try {
      _dio.options = _baseOptions!;
      _dio.interceptors.clear();
      if (_unifiedInterceptors.isNotEmpty) {
        _dio.interceptors.add(_UnifiedDioInterceptor(_unifiedInterceptors));
      }
    } catch (e) {
      throw "something went wrong $e";
    }
  }

  /// set unified interceptors
  static void addInterceptors(List<UnifiedInterceptor> interceptors) {
    _unifiedInterceptors = interceptors;
  }

  /// call this function to set base options of Dio client
  static void setBaseOptions({
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
    _baseOptions = BaseOptions(
      baseUrl: baseUrl ?? '',
      headers: headers,
      extra: extra,
      queryParameters: queryParameters,
      sendTimeout: sendTimeout,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      contentType: contentType,
      responseType: _mapResponseType(responseType),
      maxRedirects: maxRedirects,
      followRedirects: followRedirects,
      persistentConnection: persistentConnection,
    );
  }

  /// GET request of DIO
  static dioGet({required String urlPath, Map<String, dynamic>? queryPara, Map<String, dynamic>? headers}) async {
    try {
      final res = await _dio.get(urlPath, queryParameters: queryPara, options: Options(headers: headers));
      return res;
    } on PlatformException catch (e) {
      return Failure(UnifiedHttpClientEnum.platformExceptionError, 'Platform Exception Caught :$e');
    } on SocketException catch (e) {
      return Failure(UnifiedHttpClientEnum.socketExceptionError, 'Socket Exception:$e');
    } on FormatException catch (e) {
      return Failure(UnifiedHttpClientEnum.formatExceptionError, 'format exception Error : $e');
    } on DioException catch (e) {
      return Failure(UnifiedHttpClientEnum.undefined, 'Dio Exception in multipart: ${e.message}');
    } catch (e) {
      return Failure(UnifiedHttpClientEnum.undefined, 'something went Wrong : $e');
    }
  }

  /// POST request of DIO
  static dioPost({required String urlPath, dynamic body, Map<String, dynamic>? queryPara, Map<String, dynamic>? headers}) async {
    try {
      final res = await _dio.post(urlPath, data: body, queryParameters: queryPara, options: Options(headers: headers));
      return res;
    } on PlatformException catch (e) {
      return Failure(UnifiedHttpClientEnum.platformExceptionError, 'Platform Exception Caught :$e');
    } on SocketException catch (e) {
      return Failure(UnifiedHttpClientEnum.socketExceptionError, 'Socket Exception:$e');
    } on FormatException catch (e) {
      return Failure(UnifiedHttpClientEnum.formatExceptionError, 'format exception Error : $e');
    } on DioException catch (e) {
      return Failure(UnifiedHttpClientEnum.undefined, 'Dio Exception in multipart: ${e.message}');
    } catch (e) {
      return Failure(UnifiedHttpClientEnum.undefined, 'something went Wrong : $e');
    }
  }

  /// Delete request of DIO
  static dioDelete({required String urlPath, Map<String, dynamic>? queryPara, Map<String, dynamic>? headers}) async {
    try {
      final res = await _dio.delete(urlPath, queryParameters: queryPara, options: Options(headers: headers));
      return res;
    } on PlatformException catch (e) {
      return Failure(UnifiedHttpClientEnum.platformExceptionError, 'Platform Exception Caught :$e');
    } on SocketException catch (e) {
      return Failure(UnifiedHttpClientEnum.socketExceptionError, 'Socket Exception:$e');
    } on FormatException catch (e) {
      return Failure(UnifiedHttpClientEnum.formatExceptionError, 'format exception Error : $e');
    } on DioException catch (e) {
      return Failure(UnifiedHttpClientEnum.undefined, 'Dio Exception in multipart: ${e.message}');
    } catch (e) {
      return Failure(UnifiedHttpClientEnum.undefined, 'something went Wrong : $e');
    }
  }

  /// Multipart request of DIO for file uploads
  /// Example:
  /// ```dart
  /// final result = await PackageDio.dioMultipart(
  ///   urlPath: '/upload',
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
  static dioMultipart({
    required String urlPath,
    Map<String, dynamic>? queryPara,
    Map<String, dynamic>? headers,
    Map<String, Map<String, dynamic>>? files,
    Map<String, String>? fields,
  }) async {
    try {
      final formData = FormData();

      // Add form fields
      if (fields != null) {
        for (final entry in fields.entries) {
          formData.fields.add(MapEntry(entry.key, entry.value));
        }
      }

      // Add files
      if (files != null) {
        for (final entry in files.entries) {
          final fieldName = entry.key;
          final fileData = entry.value;

          MultipartFile multipartFile;

          if (fileData.containsKey('path')) {
            // File from path
            final filePath = fileData['path'] as String;
            final filename = fileData['filename'] as String? ?? filePath.split('/').last;

            multipartFile = await MultipartFile.fromFile(
              filePath,
              filename: filename,
            );
          } else if (fileData.containsKey('bytes')) {
            // File from bytes
            final bytesList = fileData['bytes'];
            final bytes = bytesList is List<int> ? bytesList : (bytesList as Uint8List).toList();
            final filename = fileData['filename'] as String? ?? 'file_${DateTime.now().millisecondsSinceEpoch}';

            multipartFile = MultipartFile.fromBytes(
              bytes,
              filename: filename,
            );
          } else {
            return Failure(UnifiedHttpClientEnum.badRequestError, 'Invalid file data for field "$fieldName". Must provide either "path" or "bytes".');
          }

          formData.files.add(MapEntry(fieldName, multipartFile));
        }
      }

      final res = await _dio.post(
        urlPath,
        data: formData,
        queryParameters: queryPara,
        options: Options(headers: headers),
      );
      return res;
    } on PlatformException catch (e) {
      return Failure(UnifiedHttpClientEnum.platformExceptionError, 'Platform Exception Caught :$e');
    } on SocketException catch (e) {
      return Failure(UnifiedHttpClientEnum.socketExceptionError, 'Socket Exception:$e');
    } on FormatException catch (e) {
      return Failure(UnifiedHttpClientEnum.formatExceptionError, 'format exception Error : $e');
    } on DioException catch (e) {
      return Failure(UnifiedHttpClientEnum.undefined, 'Dio Exception in multipart: ${e.message}');
    } catch (e) {
      return Failure(UnifiedHttpClientEnum.undefined, 'something went Wrong : $e');
    }
  }
}

ResponseType? _mapResponseType(UnifiedResponseType? type) {
  switch (type) {
    case UnifiedResponseType.json:
      return ResponseType.json;
    case UnifiedResponseType.stream:
      return ResponseType.stream;
    case UnifiedResponseType.plain:
      return ResponseType.plain;
    case UnifiedResponseType.bytes:
      return ResponseType.bytes;
    case null:
      return null;
  }
}

class _UnifiedDioInterceptor extends Interceptor {
  _UnifiedDioInterceptor(this.interceptors);

  final List<UnifiedInterceptor> interceptors;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final unifiedRequest = await UnifiedInterceptorRunner.runOnRequest(
        UnifiedRequest(
          method: options.method,
          uri: options.uri,
          headers: options.headers.map((k, v) => MapEntry(k, v.toString())),
          body: options.data,
        ),
        interceptors,
      );

      // Persist the unified request so interceptors like NetworkLogInterceptor
      // can access timing information later on response/error.
      options.extra['unifiedRequest'] = unifiedRequest;

      options
        ..headers = unifiedRequest.headers
        ..data = unifiedRequest.body;

      final overrideUri = unifiedRequest.uri;
      if (overrideUri.hasScheme && overrideUri.hasAuthority) {
        options.baseUrl = '${overrideUri.scheme}://${overrideUri.authority}';
      }
      if (overrideUri.path.isNotEmpty) {
        options.path = overrideUri.path;
      }
      if (overrideUri.queryParameters.isNotEmpty) {
        options.queryParameters = overrideUri.queryParameters;
      }

      return handler.next(options);
    } catch (e, st) {
      final error = await UnifiedInterceptorRunner.runOnError(
        UnifiedError(error: e, stackTrace: st),
        interceptors,
      );
      return handler.reject(
        DioException(requestOptions: options, error: error.error, stackTrace: error.stackTrace),
      );
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    try {
      final storedRequest = response.requestOptions.extra['unifiedRequest'] as UnifiedRequest?;
      final unifiedResponse = await UnifiedInterceptorRunner.runOnResponse(
        UnifiedResponse(
          statusCode: response.statusCode,
          data: response.data,
          headers: response.headers.map,
          request: storedRequest ??
              UnifiedRequest(
                method: response.requestOptions.method,
                uri: response.requestOptions.uri,
                headers: response.requestOptions.headers.map((k, v) => MapEntry(k, v.toString())),
                body: response.requestOptions.data,
              ),
        ),
        interceptors,
      );
      response.data = unifiedResponse.data;
      return handler.next(response);
    } catch (e, st) {
      final error = await UnifiedInterceptorRunner.runOnError(
        UnifiedError(error: e, stackTrace: st),
        interceptors,
      );
      return handler.reject(
        DioException(requestOptions: response.requestOptions, error: error.error, stackTrace: error.stackTrace),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final storedRequest = err.requestOptions.extra['unifiedRequest'] as UnifiedRequest?;
    final request = storedRequest ??
        UnifiedRequest(
          method: err.requestOptions.method,
          uri: err.requestOptions.uri,
          headers: err.requestOptions.headers.map((k, v) => MapEntry(k, v.toString())),
          body: err.requestOptions.data,
        );
    final response = err.response == null
        ? null
        : UnifiedResponse(
            statusCode: err.response?.statusCode,
            data: err.response?.data,
            headers: err.response?.headers.map,
            request: request,
          );
    final processedError = await UnifiedInterceptorRunner.runOnError(
      UnifiedError(
        error: err.error ?? err,
        stackTrace: err.stackTrace,
        request: request,
        response: response,
      ),
      interceptors,
    );
    return handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        error: processedError.error,
        stackTrace: processedError.stackTrace,
        type: err.type,
      ),
    );
  }
}
