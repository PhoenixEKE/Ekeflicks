import 'package:app_ekeflicks/core/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds canonical v1 endpoints without duplicate slashes', () {
    expect(
      ApiConfig.endpoint('/contents//home/').path,
      '/api/v1/contents/home/',
    );
    expect(ApiConfig.endpoint('auth/register').path, '/api/v1/auth/register/');
  });
}
