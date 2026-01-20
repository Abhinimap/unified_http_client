import 'dart:convert';

import 'package:unified_http_client/result.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unified_http_client/unified_http_client_service.dart';

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

      default:
        debugPrint('Api Response not matched with any cases ');
    }
  }
}
