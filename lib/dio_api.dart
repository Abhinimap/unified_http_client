import 'dart:io';

import 'package:dio/dio.dart';
import 'package:unified_http_client/error_handeler.dart';
import 'package:unified_http_client/result.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// use this class to do
/// DIO APi Request
class PackageDio {
  PackageDio._();
  static final Dio _dio = Dio();
  static BaseOptions? _baseOptions = BaseOptions();
  static List<Interceptor>? _interceptors;

  /// setup dio
  static void setUpDio() {
    try {
      _dio.options = _baseOptions!;
      _dio.interceptors.addAll(_interceptors!);
    } catch (e) {
      throw "something went wrong $e";
    }
  }

  /// set interceptors
  static void addInterceptors(List<Interceptor> interceptors) {
    _interceptors = interceptors;
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
    ResponseType? responseType,
    String? contentType,
    bool? followRedirects,
    int? maxRedirects,
    bool? persistentConnection,
    RequestEncoder? requestEncoder,
    ResponseDecoder? responseDecoder,
  }) {
    _baseOptions = BaseOptions(
      baseUrl: baseUrl ?? '',
      headers: headers,
      extra: extra,
      queryParameters: queryParameters,
      sendTimeout: sendTimeout,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      requestEncoder: requestEncoder,
      responseDecoder: responseDecoder,
      contentType: contentType,
      responseType: responseType,
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
    } on PlatformException {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.platformExceptionError,
          errorResponseHolder: ErrorResponseHolder(defaultMessage: 'Platform Exception Caught')));
    } on SocketException catch (e) {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.socketExceptionError,
          errorResponseHolder: ErrorResponseHolder(defaultMessage: 'Socket Exception:$e')));
    } on FormatException {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.formatExceptionError,
          errorResponseHolder: ErrorResponseHolder(defaultMessage: 'format exception Error')));
    } catch (e) {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.undefined,
          errorResponseHolder: ErrorResponseHolder(defaultMessage: 'something went Wrong : $e')));
    }
  }

  /// POST request of DIO
  static dioPost({required String urlPath, dynamic body, Map<String, dynamic>? queryPara, Map<String, dynamic>? headers}) async {
    try {
      final res = await _dio.post(urlPath, data: body, queryParameters: queryPara, options: Options(headers: headers));
      return res;
    } on PlatformException {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.platformExceptionError,
          errorResponseHolder: ErrorResponseHolder(defaultMessage: 'Platform Exception Caught')));
    } on SocketException catch (e) {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.socketExceptionError,
          errorResponseHolder: ErrorResponseHolder(defaultMessage: 'Socket Exception:$e')));
    } on FormatException {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.formatExceptionError,
          errorResponseHolder: ErrorResponseHolder(defaultMessage: 'format exception Error')));
    } on DioException catch (e) {
      debugPrint('error of dioexp : ${e.type}');
    } catch (e) {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.undefined,
          errorResponseHolder: ErrorResponseHolder(defaultMessage: 'something went Wrong : $e')));
    }
  }

  /// Delete request of DIO
  static dioDelete({required String urlPath, Map<String, dynamic>? queryPara, Map<String, dynamic>? headers}) async {
    try {
      final res = await _dio.delete(urlPath, queryParameters: queryPara, options: Options(headers: headers));
      return res;
    } on PlatformException {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.platformExceptionError,
          errorResponseHolder: ErrorResponseHolder(defaultMessage: 'Platform Exception Caught')));
    } on SocketException catch (e) {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.socketExceptionError,
          errorResponseHolder: ErrorResponseHolder(defaultMessage: 'Socket Exception:$e')));
    } on FormatException {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.formatExceptionError,
          errorResponseHolder: ErrorResponseHolder(defaultMessage: 'format exception Error')));
    } catch (e) {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.undefined,
          errorResponseHolder: ErrorResponseHolder(defaultMessage: 'something went Wrong : $e')));
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
            return Failure(ErrorResponse(
                unifiedHttpClientEnum: UnifiedHttpClientEnum.badRequestError,
                errorResponseHolder:
                    ErrorResponseHolder(defaultMessage: 'Invalid file data for field "$fieldName". Must provide either "path" or "bytes".')));
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
    } on PlatformException {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.platformExceptionError,
          errorResponseHolder: ErrorResponseHolder(defaultMessage: 'Platform Exception Caught')));
    } on SocketException catch (e) {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.socketExceptionError,
          errorResponseHolder: ErrorResponseHolder(defaultMessage: 'Socket Exception:$e')));
    } on FormatException {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.formatExceptionError,
          errorResponseHolder: ErrorResponseHolder(defaultMessage: 'format exception Error')));
    } on DioException catch (e) {
      debugPrint('error of dioexp in multipart : ${e.type}');
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.undefined,
          errorResponseHolder: ErrorResponseHolder(defaultMessage: 'Dio Exception in multipart: ${e.message}')));
    } catch (e) {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.undefined,
          errorResponseHolder: ErrorResponseHolder(defaultMessage: 'something went Wrong : $e')));
    }
  }
}
