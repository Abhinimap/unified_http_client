import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A Class to get Information about the Internet and Connection provider

class InternetConnectionChecker {
  final List<AddressCheckOption> _defaultCheckOptions = <AddressCheckOption>[
    AddressCheckOption(
      uri: Uri.parse(
        'https://1.1.1.1',
      ),
    ),
    AddressCheckOption(
      uri: Uri.parse(
        'https://icanhazip.com/',
      ),
    ),
    AddressCheckOption(
      uri: Uri.parse(
        'https://jsonplaceholder.typicode.com/todos/1',
      ),
    ),
    AddressCheckOption(
      uri: Uri.parse(
        'https://reqres.in/api/users/1',
      ),
    ),
  ];

  Future<bool> _hasInternetConnection(AddressCheckOption option) async {
    try {
      final http.Response response = await compute(
        (_) {
          return http
              .head(
                option.uri,
              )
              .timeout(const Duration(seconds: 2));
        },
        null,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// gives True or False whether the device is Connected to Internet and Internet is available or not.
  Future<bool> get hasConnection async {
    final Completer<bool> completer = Completer<bool>();
    int length = _defaultCheckOptions.length;
    if (!await isNetworkConnected()) {
      return false;
    }
    for (final AddressCheckOption option in _defaultCheckOptions) {
      unawaited(
        _hasInternetConnection(option).then((bool result) {
          length -= 1;

          if (completer.isCompleted) return;

          if (result) {
            debugPrint(
                "option checked : ${_defaultCheckOptions.length - length}");
            completer.complete(true);
          } else if (length == 0) {
            completer.complete(false);
          }
        }),
      );
    }

    return completer.future;
  }

  /// Use to get True or false for device is Connected to Internet provider or not
  /// It uses Connectivity_plus to fetch information.
  Future<bool> isNetworkConnected() async {
    final results = await Connectivity().checkConnectivity();

    if (results.isEmpty) {
      return false;
    } else if (results.contains(ConnectivityResult.none)) {
      return false;
    }
    return true;
  }
}

/// Contains URI to test Internet Connection
base class AddressCheckOption {
  /// URI
  Uri uri;

  /// Cosntructor
  AddressCheckOption({required this.uri});
}
