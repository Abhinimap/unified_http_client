import 'package:ansicolor/ansicolor.dart';

class PackageLogger {
  static const String _packageName = 'unified_http_client';

  static bool _ansiEnabled = false;

  static final AnsiPen _logPen = AnsiPen()..rgb(r: 0, g: 200, b: 179);
  static final AnsiPen _warningPen = AnsiPen()..yellow();
  static final AnsiPen _errorPen = AnsiPen()..red();
  static final AnsiPen _successPen = AnsiPen()..green();

  /// Force ANSI colors on. Call once so logs use our colors even when
  /// stdout is not a TTY (e.g. Flutter IDE debug console).
  static void enableAnsiColors() {
    if (_ansiEnabled) return;
    _ansiEnabled = true;
    ansiColorDisabled = false;
  }

  static void log(dynamic data) {
    _print(_logPen, 'LOG', data);
  }

  static void warning(dynamic data) {
    _print(_warningPen, 'WARNING', data);
  }

  static void error(dynamic data) {
    _print(_errorPen, 'ERROR', data);
  }

  static void success(dynamic data) {
    _print(_successPen, 'SUCCESS', data);
  }

  static void _print(AnsiPen pen, String tag, dynamic data) {
    enableAnsiColors();
    final message = data?.toString() ?? '';
    print(
      pen('[$_packageName][$tag] $message'),
    );
  }
}
