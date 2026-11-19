import 'package:shared_preferences/shared_preferences.dart';

enum SubscriptionStep { offerSelection, payment }

class SubscriptionProgress {
  const SubscriptionProgress({
    required this.step,
    this.offerTitle,
    this.offerPrice,
    this.offerCurrency,
    this.offerPlanSlug,
  });

  final SubscriptionStep step;
  final String? offerTitle;
  final String? offerPrice;
  final String? offerCurrency;
  final String? offerPlanSlug;
}

/// Persists an unfinished subscription journey for each account.
///
/// Progress is deliberately not cleared on logout: the user must be able to
/// sign in again later and continue from the same step.
class SubscriptionProgressService {
  static const _stepSuffix = 'subscription_step';
  static const _offerTitleSuffix = 'subscription_offer_title';
  static const _offerPriceSuffix = 'subscription_offer_price';
  static const _offerCurrencySuffix = 'subscription_offer_currency';
  static const _offerPlanSlugSuffix = 'subscription_offer_plan_slug';

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
    required String offerCurrency,
    required String offerPlanSlug,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString(
        _key(email, _stepSuffix),
        SubscriptionStep.payment.name,
      ),
      preferences.setString(_key(email, _offerTitleSuffix), offerTitle),
      preferences.setString(_key(email, _offerPriceSuffix), offerPrice),
      preferences.setString(_key(email, _offerCurrencySuffix), offerCurrency),
      preferences.setString(_key(email, _offerPlanSlugSuffix), offerPlanSlug),
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
      final offerCurrency = preferences.getString(
        _key(email, _offerCurrencySuffix),
      );
      final offerPlanSlug = preferences.getString(
        _key(email, _offerPlanSlugSuffix),
      );

      if (offerTitle != null &&
          offerPrice != null &&
          offerCurrency != null &&
          offerCurrency.isNotEmpty &&
          offerPlanSlug != null &&
          offerPlanSlug.isNotEmpty) {
        return SubscriptionProgress(
          step: SubscriptionStep.payment,
          offerTitle: offerTitle,
          offerPrice: offerPrice,
          offerCurrency: offerCurrency,
          offerPlanSlug: offerPlanSlug,
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
      preferences.remove(_key(email, _offerCurrencySuffix)),
      preferences.remove(_key(email, _offerPlanSlugSuffix)),
    ]);
  }
}
