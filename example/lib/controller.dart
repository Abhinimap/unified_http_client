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

    response.fold((e) {
      debugPrint('the status is : ${e.unifiedHttpClientEnum} , message : ${e.message}');
    }, (r) {
      final data = r;
      result.value = UnifiedHttpClient.useHttp ? (json.decode(data.body)).toString() : data.data.toString();
      debugPrint('result  :$data');
    });
  }
}
