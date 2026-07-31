import 'package:flutter/services.dart';

class NativeScreenRetainer {
  static const MethodChannel _channel = 
      MethodChannel('com.ekeflicks/native_screen');

  static Future<void> retainOn() async {
    try {
      await _channel.invokeMethod('retainOn');
    } on PlatformException catch (e) {
      print("Failed to retain screen: ${e.message}");
    }
  }

  static Future<void> release() async {
    try {
      await _channel.invokeMethod('release');
    } on PlatformException catch (e) {
      print("Failed to release screen: ${e.message}");
    }
  }
}