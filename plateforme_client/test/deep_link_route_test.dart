import 'package:flutter_test/flutter_test.dart';
import 'package:app_ekeflicks/core/deep_link_route.dart';

void main() {
  test('recognizes password reset links using an action query parameter', () {
    final uri = Uri.parse(
      'http://example.test/?action=reset-password&token=password-token',
    );

    expect(deepLinkRoute(uri), '/reset-password');
  });

  test('recognizes parental PIN links even when they include a fragment', () {
    final uri = Uri.parse(
      'http://example.test/?action=reset-parental-pin&token=pin-token'
      '&profile=profile-id#/reset-parental-pin',
    );

    expect(deepLinkRoute(uri), '/reset-parental-pin');
  });

  test('continues to support reset routes encoded in the path', () {
    expect(
      deepLinkRoute(Uri.parse('http://example.test/password-reset-confirm?token=x')),
      '/reset-password',
    );
    expect(deepLinkRoute(Uri.parse('http://example.test/reset-parental-pin')),
        '/reset-parental-pin');
  });

  test('ignores regular application URLs', () {
    expect(deepLinkRoute(Uri.parse('http://example.test/')), isNull);
  });
}
