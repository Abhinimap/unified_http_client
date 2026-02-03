import 'dart:convert';

import 'package:unified_http_client/unified_http_client.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ApiController extends GetxController {
  var responsebody = ''.obs;
  var defMesg = ''.obs;
  var customMesg = ''.obs;

  var errorEnum = ''.obs;
  var result = ''.obs;

  void clear() {
    defMesg.value = '';
    customMesg.value = '';
    errorEnum.value = '';
    result.value = '';
    responsebody.value = '';
  }

  Future<void> callApi() async {
    clear();
    final Result response = await UnifiedHttpClient.get(
      '/data/postdata',
    );
    // await UnifiedHttpClient.post('/data/postdata', body: '');
    switch (response) {
      case Success(value: dynamic data):
        result.value = UnifiedHttpClient.useHttp ? (await json.decode(data.body)).toString() : data.data.toString();
        debugPrint('result  :$data');
        break;
      case Failure():
        // pass through enums of failure to customize uses according to failures
        switch (response.unifiedHttpClientEnum) {
          case UnifiedHttpClientEnum.badRequestError:
            debugPrint('the status is 400 , Bad request from client side :${response.message} ');
            break;
          case UnifiedHttpClientEnum.notFoundError:
            debugPrint('404 , Api endpoint not found');
            break;
          default:
            debugPrint('Not matched in main cases : ${response.message}');
        }
        break;
      default:
        debugPrint('Api Response not matched with any cases ');
    }
  }
}
