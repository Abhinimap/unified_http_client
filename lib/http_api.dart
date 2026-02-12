import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:unified_http_client/unified_http_client_service.dart';
import 'package:unified_http_client/result.dart';
import 'package:unified_http_client/unified_interceptor.dart';

/// This will be used for HTTP Api requests
class PackageHttp {
  PackageHttp._internal();

  static http.Client? _client;
  static String? _host;
  static List<UnifiedInterceptor> _interceptors = <UnifiedInterceptor>[];

  /// '/api/v1/'
  static String? _prefix;

  /// define host and prefix so that
  /// on every request only specify endpoint
  static setup({String? host, String? prefix}) {
    _host = host;
    _prefix = prefix;
  }

  /// Configure unified interceptors (invoked from UnifiedHttpClient.init)
  static void configureInterceptors(List<UnifiedInterceptor> interceptors) {
    _interceptors = interceptors;
  }

  /// it will create uri from given endpoint with including baseurl
  /// baseurl can be setup by calling setup function
  static Uri getUriFromEndpoints({
    required String endpoint,
    Map<String, dynamic>? queryParams,
    bool usePrefix = false,
    List<String>? pathSeg,
  }) {
    String? host = _host?.trim();

    // If host contains scheme, parse it
    String scheme = 'https';
    if (host != null && (host.startsWith('http://') || host.startsWith('https://'))) {
      final parsed = Uri.parse(host);
      scheme = parsed.scheme;
      host = parsed.host;
    }

    final segments = <String>[];

    if (usePrefix && _prefix != null && _prefix!.isNotEmpty) {
      segments.addAll(_prefix!.split('/').where((e) => e.isNotEmpty));
    }

    segments.addAll(endpoint.split('/').where((e) => e.isNotEmpty));

    if (pathSeg != null && pathSeg.isNotEmpty) {
      segments.addAll(pathSeg);
    }

    return Uri(
      scheme: scheme,
      host: host,
      pathSegments: segments,
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
      UnifiedRequest prepared = await UnifiedInterceptorRunner.runOnRequest(
        UnifiedRequest(method: 'GET', uri: url, headers: headers),
        _interceptors,
      );
      final targetUrl = prepared.uri;

      debugPrint('requesting on  :$targetUrl');
      final response =
          _client != null ? await _client!.get(targetUrl, headers: prepared.headers) : await http.get(targetUrl, headers: prepared.headers);

      await UnifiedInterceptorRunner.runOnResponse(
        UnifiedResponse(
          statusCode: response.statusCode,
          data: response.body,
          headers: response.headers,
          request: prepared,
        ),
        _interceptors,
      );
      return response;
    } on PlatformException catch (e, st) {
      await _notifyError(e, st,
          request: UnifiedRequest(
            method: 'POST',
            uri: url,
            headers: headers,
          ));
      return Failure(UnifiedHttpClientEnum.platformExceptionError, 'Platform Exception Caught : $e');
    } on SocketException catch (e, st) {
      await _notifyError(e, st,
          request: UnifiedRequest(
            method: 'POST',
            uri: url,
            headers: headers,
          ));
      return Failure(UnifiedHttpClientEnum.socketExceptionError, 'Socket Exception:$e');
    } on FormatException catch (e, st) {
      await _notifyError(e, st,
          request: UnifiedRequest(
            method: 'POST',
            uri: url,
            headers: headers,
          ));
      return Failure(UnifiedHttpClientEnum.formatExceptionError, 'format exception : $e');
    } catch (e, st) {
      await _notifyError(e, st,
          request: UnifiedRequest(
            method: 'POST',
            uri: url,
            headers: headers,
          ));
      return Failure(UnifiedHttpClientEnum.undefined, 'something went Wrong : $e');
    }
  }

  /// Http post request
  static postRequest({required Uri url, Map<String, String>? headers, required dynamic body}) async {
    try {
      UnifiedRequest prepared = await UnifiedInterceptorRunner.runOnRequest(
        UnifiedRequest(method: 'POST', uri: url, headers: headers, body: body),
        _interceptors,
      );

      debugPrint('requesting post : ${prepared.uri}');
      final response = _client != null
          ? await _client!.post(prepared.uri, headers: prepared.headers, body: json.encode(prepared.body))
          : await http.post(prepared.uri, headers: prepared.headers, body: json.encode(prepared.body));

      await UnifiedInterceptorRunner.runOnResponse(
        UnifiedResponse(
          statusCode: response.statusCode,
          data: response.body,
          headers: response.headers,
          request: prepared,
        ),
        _interceptors,
      );
      return response;
    } on PlatformException catch (e, st) {
      await _notifyError(e, st, request: UnifiedRequest(method: 'POST', uri: url, headers: headers, body: body));
      return Failure(UnifiedHttpClientEnum.platformExceptionError, 'Platform Exception Caught : $e');
    } on SocketException catch (e, st) {
      await _notifyError(e, st, request: UnifiedRequest(method: 'POST', uri: url, headers: headers, body: body));
      return Failure(UnifiedHttpClientEnum.socketExceptionError, 'Socket Exception:$e');
    } on FormatException catch (e, st) {
      await _notifyError(e, st, request: UnifiedRequest(method: 'POST', uri: url, headers: headers, body: body));
      return Failure(UnifiedHttpClientEnum.formatExceptionError, 'format exception : $e');
    } catch (e, st) {
      await _notifyError(e, st, request: UnifiedRequest(method: 'POST', uri: url, headers: headers, body: body));
      return Failure(UnifiedHttpClientEnum.undefined, 'something went Wrong : $e');
    }
  }

  /// Http get request
  static deleteRequest({required Uri url, Map<String, String>? headers}) async {
    try {
      final prepared = await UnifiedInterceptorRunner.runOnRequest(
        UnifiedRequest(method: 'DELETE', uri: url, headers: headers),
        _interceptors,
      );
      debugPrint('requesting on  :${prepared.uri}');
      final response = _client != null
          ? await _client!.delete(prepared.uri, headers: prepared.headers)
          : await http.delete(prepared.uri, headers: prepared.headers);

      await UnifiedInterceptorRunner.runOnResponse(
        UnifiedResponse(
          statusCode: response.statusCode,
          data: response.body,
          headers: response.headers,
          request: prepared,
        ),
        _interceptors,
      );
      return response;
    } on PlatformException catch (e, st) {
      await _notifyError(e, st,
          request: UnifiedRequest(
            method: 'POST',
            uri: url,
            headers: headers,
          ));
      return Failure(UnifiedHttpClientEnum.platformExceptionError, 'Platform Exception Caught : $e');
    } on SocketException catch (e, st) {
      await _notifyError(e, st,
          request: UnifiedRequest(
            method: 'POST',
            uri: url,
            headers: headers,
          ));
      return Failure(UnifiedHttpClientEnum.socketExceptionError, 'Socket Exception:$e');
    } on FormatException catch (e, st) {
      await _notifyError(e, st,
          request: UnifiedRequest(
            method: 'POST',
            uri: url,
            headers: headers,
          ));
      return Failure(UnifiedHttpClientEnum.formatExceptionError, 'format exception : $e');
    } catch (e, st) {
      await _notifyError(e, st,
          request: UnifiedRequest(
            method: 'POST',
            uri: url,
            headers: headers,
          ));
      return Failure(UnifiedHttpClientEnum.undefined, 'something went Wrong : $e');
    }
  }

  /// Http put request
  static putRequest({required Uri url, Map<String, String>? headers, required Map<String, dynamic> body}) async {
    try {
      final prepared = await UnifiedInterceptorRunner.runOnRequest(
        UnifiedRequest(method: 'PUT', uri: url, headers: headers, body: body),
        _interceptors,
      );

      final response = _client != null
          ? await _client!.put(prepared.uri, headers: prepared.headers, body: json.encode(prepared.body))
          : await http.put(prepared.uri, headers: prepared.headers, body: prepared.body);

      await UnifiedInterceptorRunner.runOnResponse(
        UnifiedResponse(
          statusCode: response.statusCode,
          data: response.body,
          headers: response.headers,
          request: prepared,
        ),
        _interceptors,
      );
      return response;
    } on PlatformException catch (e, st) {
      await _notifyError(e, st, request: UnifiedRequest(method: 'POST', uri: url, headers: headers, body: body));
      return Failure(UnifiedHttpClientEnum.platformExceptionError, 'Platform Exception Caught : $e');
    } on SocketException catch (e, st) {
      await _notifyError(e, st, request: UnifiedRequest(method: 'POST', uri: url, headers: headers, body: body));
      return Failure(UnifiedHttpClientEnum.socketExceptionError, 'Socket Exception:$e');
    } on FormatException catch (e, st) {
      await _notifyError(e, st, request: UnifiedRequest(method: 'POST', uri: url, headers: headers, body: body));
      return Failure(UnifiedHttpClientEnum.formatExceptionError, 'format exception : $e');
    } catch (e, st) {
      await _notifyError(e, st, request: UnifiedRequest(method: 'POST', uri: url, headers: headers, body: body));
      return Failure(UnifiedHttpClientEnum.undefined, 'something went Wrong : $e');
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
      final prepared = await UnifiedInterceptorRunner.runOnRequest(
        UnifiedRequest(method: 'POST', uri: url, headers: headers, body: {'files': files, 'fields': fields}),
        _interceptors,
      );

      debugPrint('requesting multipart : ${prepared.uri}');
      final request = http.MultipartRequest('POST', prepared.uri);

      // Add headers if provided
      if (prepared.headers.isNotEmpty) {
        request.headers.addAll(prepared.headers);
      }

      final processedBody = prepared.body is Map<String, dynamic> ? prepared.body as Map<String, dynamic> : <String, dynamic>{};
      final processedFields = (processedBody['fields'] ?? fields) as Map<String, String>?;
      final processedFiles = (processedBody['files'] ?? files) as Map<String, Map<String, dynamic>>?;

      // Add form fields
      if (processedFields != null) {
        request.fields.addAll(processedFields);
      }

      // Add files
      if (processedFiles != null) {
        for (final entry in processedFiles.entries) {
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
                contentType: MediaType.parse(contentTypeStr),
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
                contentType: MediaType.parse(contentTypeStr),
              );
            } else {
              multipartFile = http.MultipartFile.fromBytes(
                fieldName,
                bytes,
                filename: filename,
              );
            }
          } else {
            return Failure(UnifiedHttpClientEnum.badRequestError, 'Invalid file data for field "$fieldName". Must provide either "path" or "bytes".');
          }

          request.files.add(multipartFile);
        }
      }

      // Send request
      final streamedResponse = _client != null ? await _client!.send(request) : await request.send();

      // Convert streamed response to regular response
      final response = await http.Response.fromStream(streamedResponse);
      await UnifiedInterceptorRunner.runOnResponse(
        UnifiedResponse(
          statusCode: response.statusCode,
          data: response.body,
          headers: response.headers,
          request: prepared,
        ),
        _interceptors,
      );
      return response;
    } on PlatformException catch (e, st) {
      await _notifyError(e, st,
          request: UnifiedRequest(
            method: 'POST',
            uri: url,
            headers: headers,
          ));
      return Failure(UnifiedHttpClientEnum.platformExceptionError, 'Platform Exception Caught : $e');
    } on SocketException catch (e, st) {
      await _notifyError(e, st,
          request: UnifiedRequest(
            method: 'POST',
            uri: url,
            headers: headers,
          ));
      return Failure(UnifiedHttpClientEnum.socketExceptionError, 'Socket Exception:$e');
    } on FormatException catch (e, st) {
      await _notifyError(e, st,
          request: UnifiedRequest(
            method: 'POST',
            uri: url,
            headers: headers,
          ));
      return Failure(UnifiedHttpClientEnum.formatExceptionError, 'format exception : $e');
    } catch (e, st) {
      await _notifyError(e, st,
          request: UnifiedRequest(
            method: 'POST',
            uri: url,
            headers: headers,
          ));
      return Failure(UnifiedHttpClientEnum.undefined, 'something went Wrong : $e');
    }
  }

  static Future<void> _notifyError(Object error, StackTrace stackTrace, {UnifiedRequest? request, UnifiedResponse? response}) async {
    if (_interceptors.isEmpty) return;
    await UnifiedInterceptorRunner.runOnError(
      UnifiedError(error: error, stackTrace: stackTrace, request: request, response: response),
      _interceptors,
    );
  }
}
