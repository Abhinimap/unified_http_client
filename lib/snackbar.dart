import 'package:flutter/material.dart';

/// A class to desplay snackbar
/// it uses a singleton instance
class CustomSnackbar {
  CustomSnackbar._internal();
  static CustomSnackbar? _instance;

  /// snackbar Constructor
  factory CustomSnackbar() {
    _instance ??= CustomSnackbar._internal();
    return _instance!;
  }

  BuildContext? _context;

  /// Call this function after initialization of MaterialApp to provide context
  void init(BuildContext context) {
    _context = context;
  }

  /// show No internet Snackbar
  void showNoInternetSnackbar() {
    SnackBar snack = const SnackBar(
      content: Text('No Internet, Kindly check your Internet Connection'),
      backgroundColor: Colors.red,
      elevation: 2,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(),
    );
    if (_context != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(snack);
    }
  }

  /// show Snackbar with Custom Message
  void showCustomSnackbar({String? mesg, Color? bgColor, Color? textColor}) {
    SnackBar snack = SnackBar(
      content: Text(
        mesg ?? '',
        style: TextStyle(color: textColor),
      ),
      backgroundColor: bgColor,
      elevation: 2,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: const RoundedRectangleBorder(),
    );
    if (_context != null) {
      ScaffoldMessenger.of(_context!).showSnackBar(snack);
    }
  }
}
