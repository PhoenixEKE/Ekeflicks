import 'package:web/web.dart' as web;

bool isSafariBrowser() {
  final agent = web.window.navigator.userAgent.toLowerCase();
  return agent.contains('safari') &&
      !agent.contains('chrome') &&
      !agent.contains('chromium') &&
      !agent.contains('android');
}
