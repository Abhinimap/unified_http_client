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
    String? path,
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
  static dioGet(
      {required String urlPath,
      Map<String, dynamic>? queryPara,
      Map<String, dynamic>? headers}) async {
    try {
      final res = await _dio.get(urlPath,
          queryParameters: queryPara, options: Options(headers: headers));
      return res;
    } on PlatformException {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.platformExceptionError,
          errorResponseHolder: ErrorResponseHolder(
              defaultMessage: 'Platform Exception Caught')));
    } on SocketException catch (e) {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.socketExceptionError,
          errorResponseHolder:
              ErrorResponseHolder(defaultMessage: 'Socket Exception:$e')));
    } on FormatException {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.formatExceptionError,
          errorResponseHolder:
              ErrorResponseHolder(defaultMessage: 'format exception Error')));
    } catch (e) {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.undefined,
          errorResponseHolder: ErrorResponseHolder(
              defaultMessage: 'something went Wrong : $e')));
    }
  }

  /// POST request of DIO
  static dioPost(
      {required String urlPath,
      dynamic body,
      Map<String, dynamic>? queryPara,
      Map<String, dynamic>? headers}) async {
    try {
      final res = await _dio.post(urlPath,
          data: body,
          queryParameters: queryPara,
          options: Options(headers: headers));
      return res;
    } on PlatformException {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.platformExceptionError,
          errorResponseHolder: ErrorResponseHolder(
              defaultMessage: 'Platform Exception Caught')));
    } on SocketException catch (e) {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.socketExceptionError,
          errorResponseHolder:
              ErrorResponseHolder(defaultMessage: 'Socket Exception:$e')));
    } on FormatException {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.formatExceptionError,
          errorResponseHolder:
              ErrorResponseHolder(defaultMessage: 'format exception Error')));
    } on DioException catch (e) {
      debugPrint('error of dioexp : ${e.type}');
    } catch (e) {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.undefined,
          errorResponseHolder: ErrorResponseHolder(
              defaultMessage: 'something went Wrong : $e')));
    }
  }

  /// Delete request of DIO
  static dioDelete(
      {required String urlPath,
      Map<String, dynamic>? queryPara,
      Map<String, dynamic>? headers}) async {
    try {
      final res = await _dio.delete(urlPath,
          queryParameters: queryPara, options: Options(headers: headers));
      return res;
    } on PlatformException {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.platformExceptionError,
          errorResponseHolder: ErrorResponseHolder(
              defaultMessage: 'Platform Exception Caught')));
    } on SocketException catch (e) {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.socketExceptionError,
          errorResponseHolder:
              ErrorResponseHolder(defaultMessage: 'Socket Exception:$e')));
    } on FormatException {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.formatExceptionError,
          errorResponseHolder:
              ErrorResponseHolder(defaultMessage: 'format exception Error')));
    } catch (e) {
      return Failure(ErrorResponse(
          unifiedHttpClientEnum: UnifiedHttpClientEnum.undefined,
          errorResponseHolder: ErrorResponseHolder(
              defaultMessage: 'something went Wrong : $e')));
    }
  }
}
