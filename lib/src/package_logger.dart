import 'dart:developer' as developper;

class PackageLogger {
  static const String _packageName = 'unified_http_client';

  // ANSI color codes
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';

  static void log(dynamic data) {
    _print(_cyan, 'LOG', data);
  }

  static void warning(dynamic data) {
    _print(_yellow, 'WARNING', data);
  }

  static void error(dynamic data) {
    _print(_red, 'ERROR', data);
  }

  static void success(dynamic data) {
    _print(_green, 'SUCCESS', data);
  }

  static void _print(String color, String tag, dynamic data) {
    final message = data?.toString() ?? '';
    // ignore: avoid_print
    developper.log('$color[$_packageName][$tag] $message$_reset');
  }
}
