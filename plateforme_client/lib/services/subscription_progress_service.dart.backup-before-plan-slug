import 'package:shared_preferences/shared_preferences.dart';

enum SubscriptionStep { offerSelection, payment }

class SubscriptionProgress {
  const SubscriptionProgress({
    required this.step,
    this.offerTitle,
    this.offerPrice,
  });

  final SubscriptionStep step;
  final String? offerTitle;
  final String? offerPrice;
}

/// Persists an unfinished subscription journey for each account.
///
/// Progress is deliberately not cleared on logout: the user must be able to
/// sign in again later and continue from the same step.
class SubscriptionProgressService {
  static const _stepSuffix = 'subscription_step';
  static const _offerTitleSuffix = 'subscription_offer_title';
  static const _offerPriceSuffix = 'subscription_offer_price';

  static String _key(String email, String suffix) =>
      '${email.trim().toLowerCase()}:$suffix';

  Future<void> start(String email) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key(email, _stepSuffix),
      SubscriptionStep.offerSelection.name,
    );
  }

  Future<void> continueToPayment({
    required String email,
    required String offerTitle,
    required String offerPrice,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString(
        _key(email, _stepSuffix),
        SubscriptionStep.payment.name,
      ),
      preferences.setString(_key(email, _offerTitleSuffix), offerTitle),
      preferences.setString(_key(email, _offerPriceSuffix), offerPrice),
    ]);
  }

  Future<SubscriptionProgress?> load(String email) async {
    final preferences = await SharedPreferences.getInstance();
    final savedStep = preferences.getString(_key(email, _stepSuffix));

    if (savedStep == SubscriptionStep.offerSelection.name) {
      return const SubscriptionProgress(step: SubscriptionStep.offerSelection);
    }

    if (savedStep == SubscriptionStep.payment.name) {
      final offerTitle = preferences.getString(_key(email, _offerTitleSuffix));
      final offerPrice = preferences.getString(_key(email, _offerPriceSuffix));
      if (offerTitle != null && offerPrice != null) {
        return SubscriptionProgress(
          step: SubscriptionStep.payment,
          offerTitle: offerTitle,
          offerPrice: offerPrice,
        );
      }

      // Corrupt or legacy progress safely resumes at offer selection.
      return const SubscriptionProgress(step: SubscriptionStep.offerSelection);
    }

    return null;
  }

  Future<void> complete(String email) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.remove(_key(email, _stepSuffix)),
      preferences.remove(_key(email, _offerTitleSuffix)),
      preferences.remove(_key(email, _offerPriceSuffix)),
    ]);
  }
}
