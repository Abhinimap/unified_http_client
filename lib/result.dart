import 'package:unified_http_client/unified_http_client_service.dart';

/// Result class is a Super class of Success and Failure class
sealed class Result<R> {
  const Result();
}

/// Inherit Result class and contains Successfull response of API Reuest
class Success<R> extends Result<R> {
  /// contains a dynamic Success value
  final R value;

  ///constructor
  const Success(this.value);
}

/// Inherited from Result class
/// This class represent Failed response from the API request
class Failure extends Result<Never> {
  /// check what was the reason behind api failure
  final UnifiedHttpClientEnum unifiedHttpClientEnum;

  /// error message from backend or our standard message as per status code
  final String message;

  /// constructor
  const Failure(this.unifiedHttpClientEnum, this.message);
}
