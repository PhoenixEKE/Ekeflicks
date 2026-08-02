import 'package:app_ekeflicks/services/subscription_progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SubscriptionProgressService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = SubscriptionProgressService();
  });

  test('resumes a newly started subscription at offer selection', () async {
    await service.start(' User@Example.com ');

    final progress = await service.load('user@example.com');

    expect(progress?.step, SubscriptionStep.offerSelection);
  });

  test('resumes payment with the selected offer', () async {
    await service.continueToPayment(
      email: 'user@example.com',
      offerTitle: 'Premium',
      offerPrice: '13.99',
    );

    final progress = await service.load('USER@example.com');

    expect(progress?.step, SubscriptionStep.payment);
    expect(progress?.offerTitle, 'Premium');
    expect(progress?.offerPrice, '13.99');
  });

  test('completed subscriptions are no longer resumed', () async {
    await service.start('user@example.com');
    await service.complete('user@example.com');

    expect(await service.load('user@example.com'), isNull);
  });
}
