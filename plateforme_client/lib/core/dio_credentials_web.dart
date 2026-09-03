import 'package:dio/dio.dart';
import 'package:dio/browser.dart';

void configureDioCredentials(Dio dio) {
  final adapter = dio.httpClientAdapter;

  if (adapter is BrowserHttpClientAdapter) {
    adapter.withCredentials = true;
  }
}
