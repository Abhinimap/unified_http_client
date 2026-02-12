class PackageLogger {
  static const String _packageName = 'unified_http_client';

  static void log(dynamic data) {
    final message = data?.toString() ?? '';
    // ignore: avoid_print
    print('[$_packageName] Logger ->  $message');
  }
}
