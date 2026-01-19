import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:unified_http_client/error_handeler.dart';
import 'package:unified_http_client/result.dart';

/// This will be used for HTTP Api requests
class PackageHttp {
  PackageHttp._internal();

  static http.Client? _client;
  static String? _host;

  /// '/api/v1/'
  static String? _prefix;

  /// define host and prefix so that
  /// on every request only specify endpoint
  static setup({String? host, String? prefix}) {
    _host = host;
    _prefix = prefix;
  }

  /// it will create uri from given endpoint with including baseurl
  /// baseurl can be setup by calling setup function
  static Uri getUriFromEndpoints({required String endpoint, Map<String, dynamic>? queryParams, bool usePrefix = false, List<String>? pathSeg}) {
    return Uri(
      scheme: 'https',
      host: _host,
      path: '${usePrefix ? _prefix : ''}$endpoint${pathSeg == null ? '' : pathSeg.join('/')}',
      queryParameters: queryParams,
    );
  }

  /// setup http client
  static void setupClient({required http.Client client}) {
    _client = client;
  }

  /// Http get request
  static getRequest({required Uri url, Map<String, String>? headers}) async {
    try {
      debugPrint('requesting on  :$url');
      if (_client != null) {
        return await _client!.get(url, headers: headers);
      } else {
        return await http.get(url, headers: headers);
      }
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

  /// Http post request
  static postRequest({required Uri url, Map<String, String>? headers, required dynamic body}) async {
    try {
      debugPrint('requesting post : $url');
      if (_client != null) {
        return await _client!.post(url, headers: headers, body: json.encode(body));
      } else {
        return await http.post(url, headers: headers, body: json.encode(body));
      }
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

  /// Http get request
  static deleteRequest({required Uri url, Map<String, String>? headers}) async {
    try {
      debugPrint('requesting on  :$url');
      if (_client != null) {
        return await _client!.delete(url, headers: headers);
      } else {
        return await http.delete(url, headers: headers);
      }
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

  /// Http put request
  static putRequest({required Uri url, Map<String, String>? headers, required Map<String, dynamic> body}) async {
    try {
      if (_client != null) {
        return await _client!.put(url, headers: headers, body: json.encode(body));
      } else {
        return await http.put(url, headers: headers, body: body);
      }
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

  /// Http multipart request for file uploads

  /// Example:
  /// ```dart
  /// final result = await PackageHttp.multipartRequest(
  ///   url: uri,
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
  static multipartRequest({
    required Uri url,
    Map<String, String>? headers,
    Map<String, Map<String, dynamic>>? files,
    Map<String, String>? fields,
  }) async {
    try {
      debugPrint('requesting multipart : $url');
      final request = http.MultipartRequest('POST', url);

      // Add headers if provided
      if (headers != null) {
        request.headers.addAll(headers);
      }

      // Add form fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      // Add files
      if (files != null) {
        for (final entry in files.entries) {
          final fieldName = entry.key;
          final fileData = entry.value;

          http.MultipartFile multipartFile;

          if (fileData.containsKey('path')) {
            // File from path
            final filePath = fileData['path'] as String;
            final filename = fileData['filename'] as String? ?? filePath.split('/').last;
            final contentTypeStr = fileData['contentType'] as String?;

            if (contentTypeStr != null) {
              final file = File(filePath);
              final bytes = await file.readAsBytes();
              multipartFile = http.MultipartFile(
                fieldName,
                Stream.value(bytes),
                bytes.length,
                filename: filename,
                contentType: http.MediaType.parse(contentTypeStr),
              );
            } else {
              multipartFile = await http.MultipartFile.fromPath(
                fieldName,
                filePath,
                filename: filename,
              );
            }
          } else if (fileData.containsKey('bytes')) {
            // File from bytes
            final bytesList = fileData['bytes'];
            final bytes = bytesList is Uint8List ? bytesList : Uint8List.fromList(bytesList as List<int>);
            final filename = fileData['filename'] as String? ?? 'file_${DateTime.now().millisecondsSinceEpoch}';
            final contentTypeStr = fileData['contentType'] as String?;

            if (contentTypeStr != null) {
              multipartFile = http.MultipartFile(
                fieldName,
                Stream.value(bytes),
                bytes.length,
                filename: filename,
                contentType: http.MediaType.parse(contentTypeStr),
              );
            } else {
              multipartFile = http.MultipartFile.fromBytes(
                fieldName,
                bytes,
                filename: filename,
              );
            }
          } else {
            return Failure(ErrorResponse(
                unifiedHttpClientEnum: UnifiedHttpClientEnum.badRequestError,
                errorResponseHolder:
                    ErrorResponseHolder(defaultMessage: 'Invalid file data for field "$fieldName". Must provide either "path" or "bytes".')));
          }

          request.files.add(multipartFile);
        }
      }

      // Send request
      final streamedResponse = _client != null ? await _client!.send(request) : await request.send();

      // Convert streamed response to regular response
      final response = await http.Response.fromStream(streamedResponse);
      return response;
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
}
