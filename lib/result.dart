import 'package:unified_http_client/error_handeler.dart';

/// Result class is a Super class of Success and Failure class
sealed class Result<R> {
  const Result();
}

/// Inherit Result class and contains Successfull response of API Reuest
class Success<R> extends Result {
  /// contains a dynamic Success value
  final R value;

  ///constructor
  const Success(this.value);
}

/// Inherited from Result class
/// This class represent Failed response from the API request
class Failure<E extends ErrorResponse> extends Result {
  /// Contains information about Failure of the APi request
  final ErrorResponse error;

  /// constructor
  const Failure(this.error);
}

/// contains details information about Failure of API Request
class ErrorResponse {
  /// Enum for Error
  UnifiedHttpClientEnum unifiedHttpClientEnum;

  /// Error Response Holder
  ErrorResponseHolder errorResponseHolder;

  /// constructor
  ErrorResponse(
      {required this.unifiedHttpClientEnum, required this.errorResponseHolder});
}
