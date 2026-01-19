/// Minimal response type abstraction so consumers don't import Dio directly.
enum UnifiedResponseType {
  json,
  stream,
  plain,
  bytes,
}

