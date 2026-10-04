import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_ekeflicks/core/app_responsive.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';
import 'package:app_ekeflicks/ui/subscription/subscription_step2_page.dart';

/// Displays the account's current plan and the next server-priced tier.
class SubscriptionManagementCard extends StatefulWidget {
  const SubscriptionManagementCard({super.key});

  @override
  State<SubscriptionManagementCard> createState() =>
      _SubscriptionManagementCardState();
}

class _SubscriptionManagementCardState
    extends State<SubscriptionManagementCard> {
  Map<String, dynamic>? _subscription;
  List<Map<String, dynamic>> _plans = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<Map<String, dynamic>> _records(dynamic payload) {
    final raw = payload is Map ? (payload['results'] ?? const []) : payload;
    return (raw as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = context.read<UserProvider>().apiClient.dio;
      final subscriptionResponse = await dio.get<Object>('/subscriptions/');
      final plansResponse = await dio.get<Object>('/subscription-plans/');
      final subscriptions = _records(subscriptionResponse.data);
      final plans = _records(plansResponse.data)
          .where((plan) => plan['is_active'] != false)
          .toList()
        ..sort((a, b) => _order(a).compareTo(_order(b)));

      subscriptions.sort((a, b) {
        final aDate = DateTime.tryParse(a['created_at']?.toString() ?? '');
        final bDate = DateTime.tryParse(b['created_at']?.toString() ?? '');
        return (bDate ?? DateTime(1970)).compareTo(aDate ?? DateTime(1970));
      });
      final now = DateTime.now();
      final active = subscriptions.where((item) {
        if (item['status'] != 'active') return false;
        final expiry = DateTime.tryParse(item['expires_at']?.toString() ?? '');
        return expiry == null || expiry.isAfter(now);
      });
      final selected =
          active.isNotEmpty ? active.first : (subscriptions.isEmpty ? null : subscriptions.first);

      if (!mounted) return;
      setState(() {
        _subscription = selected;
        _plans = plans;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = _copy(
          context,
          'Impossible de charger votre abonnement.',
          'Your subscription could not be loaded.',
        );
      });
    }
  }

  Future<void> _setRenewal(bool enabled) async {
    final subscriptionId = _subscription?['id']?.toString();
    if (subscriptionId == null || subscriptionId.isEmpty) return;
    try {
      await context.read<UserProvider>().apiClient.dio.post<Object>(
        '/subscriptions/$subscriptionId/${enabled ? 'enable-renewal' : 'cancel-renewal'}/',
        data: enabled ? {'consent': true} : <String, dynamic>{},
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_copy(
            context,
            enabled ? 'Le prélèvement mensuel est réactivé.' : 'Le renouvellement est arrêté à l’échéance.',
            enabled ? 'Monthly billing is enabled again.' : 'Renewal will stop at expiry.',
          )),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_copy(
            context,
            'Impossible de modifier le renouvellement.',
            'Could not update renewal.',
          )),
        ),
      );
    }
  }

  int _order(Map<String, dynamic> plan) =>
      (plan['display_order'] as num?)?.toInt() ?? 0;

  double _amount(dynamic value) =>
      double.tryParse((value ?? '').toString().replaceAll(',', '.')) ?? 0;

  Map<String, dynamic>? get _currentPlan {
    final plan = _subscription?['plan'];
    return plan is Map ? Map<String, dynamic>.from(plan) : null;
  }

  bool get _isCurrentActive {
    if (_subscription?['status'] != 'active') return false;
    final expiry =
        DateTime.tryParse(_subscription?['expires_at']?.toString() ?? '');
    return expiry == null || expiry.isAfter(DateTime.now());
  }

  Map<String, dynamic>? get _recommendedPlan {
    final paid = _plans.where((plan) => _amount(plan['price']) > 0).toList();
    if (paid.isEmpty) return null;
    final current = _currentPlan;
    if (current == null) return paid.first;

    final currentIndex = _plans.indexWhere(
      (plan) => plan['slug'] == current['slug'],
    );
    if (currentIndex >= 0) {
      final nextTier = _plans
          .skip(currentIndex + 1)
          .where((plan) => _amount(plan['price']) > 0);
      if (nextTier.isNotEmpty) return nextTier.first;
    }

    final higher = paid.where((plan) => _order(plan) > _order(current));
    if (higher.isNotEmpty) return higher.first;
    if (!_isCurrentActive) {
      final same = paid.where((plan) => plan['slug'] == current['slug']);
      if (same.isNotEmpty) return same.first;
    }
    return null;
  }

  String _copy(BuildContext context, String fr, String en) =>
      Localizations.localeOf(context).languageCode == 'fr' ? fr : en;

  String _currencyLabel(String value) {
    switch (value.toUpperCase()) {
      case 'XOF':
      case 'XAF':
        return 'FCFA';
      case 'EUR':
        return '€';
      case 'USD':
        return r'$';
      default:
        return value.toUpperCase();
    }
  }

  String _price(Map<String, dynamic> plan) {
    final raw = (plan['price'] ?? '').toString();
    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    final amount = parsed == null
        ? raw
        : (parsed == parsed.truncateToDouble()
            ? parsed.toInt().toString()
            : raw);
    final currency = (plan['currency'] ?? 'EUR').toString();
    return amount + ' ' + _currencyLabel(currency);
  }

  String _period(Map<String, dynamic> plan) {
    final days = (plan['duration_days'] as num?)?.toInt() ?? 30;
    if (days >= 28 && days <= 31) {
      return _copy(context, 'par mois', 'per month');
    }
    if (days == 1) return _copy(context, 'pour 1 jour', 'for 1 day');
    return _copy(context, 'pour ' + days.toString() + ' jours',
        'for ' + days.toString() + ' days');
  }

  String _dateLabel(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return '';
    final local = date.toLocal();
    return [
      local.day.toString().padLeft(2, '0'),
      local.month.toString().padLeft(2, '0'),
      local.year.toString(),
    ].join('/');
  }

  void _openCheckout(Map<String, dynamic> plan) {
    final slug = plan['slug']?.toString();
    if (slug == null || slug.isEmpty) return;
    final user = context.read<UserProvider>().currentUser;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubscriptionStep2Page(
          offerTitle: plan['name']?.toString() ?? slug,
          offerPrice: plan['price']?.toString() ?? '',
          offerCurrency: plan['currency']?.toString() ?? 'EUR',
          planSlug: slug,
          durationDays: (plan['duration_days'] as num?)?.toInt() ?? 30,
          accountEmail: user?.email,
        ),
      ),
    );
  }

  Widget _panel(
    BuildContext context, {
    required bool tv,
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      color: color,
      child: Padding(
        padding: EdgeInsets.all(tv ? 24 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _currentPlanCard(BuildContext context, bool tv) {
    final plan = _currentPlan;
    final sub = _subscription;
    final title = plan?['name']?.toString() ??
        _copy(context, 'Aucun forfait actif', 'No active plan');
    final expiry = _dateLabel(sub?['expires_at']?.toString() ?? '');
    final amount = sub?['price_at_purchase'] ?? plan?['price'];
    final purchasedCurrency =
        sub == null ? null : sub['currency_at_purchase']?.toString();
    final currency = purchasedCurrency == null || purchasedCurrency.isEmpty
        ? (plan == null ? null : plan['currency']?.toString())
        : purchasedCurrency;
    final periodDays =
        sub?['duration_days_at_purchase'] ?? plan?['duration_days'] ?? 30;
    final priceText = amount == null
        ? null
        : (_amount(amount) == 0
            ? _copy(context, 'Gratuit', 'Free')
            : _price({'price': amount, 'currency': currency ?? 'EUR'}) +
                ' / ' +
                _period({'duration_days': periodDays}));

    return _panel(
      context,
      tv: tv,
      icon: Icons.verified_outlined,
      title: _copy(context, 'Mon abonnement', 'My subscription'),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        if (expiry.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _isCurrentActive
                ? _copy(context, 'Valable jusqu’au ' + expiry,
                    'Valid until ' + expiry)
                : _copy(context, 'Échéance : ' + expiry, 'Ended: ' + expiry),
          ),
        ],
        if (priceText != null) ...[
          const SizedBox(height: 6),
          Text(priceText),
        ],
        if (_isCurrentActive && sub?['auto_renew'] == true) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.autorenew, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_copy(context, 'Prélèvement mensuel activé', 'Monthly billing is active')),
              ),
            ],
          ),
          TextButton(
            onPressed: () => _setRenewal(false),
            child: Text(_copy(context, 'Arrêter le renouvellement à l’échéance', 'Stop renewal at expiry')),
          ),
        ] else if (_isCurrentActive && sub?['cancel_at_period_end'] == true) ...[
          const SizedBox(height: 10),
          Text(_copy(context, 'Le renouvellement est arrêté. Votre accès reste actif jusqu’à l’échéance.', 'Renewal is off. Access stays active through expiry.')),
          TextButton(
            onPressed: () => _setRenewal(true),
            child: Text(_copy(context, 'Réactiver le prélèvement mensuel', 'Resume monthly billing')),
          ),
        ],
        if (!_isCurrentActive && plan != null && _amount(plan['price']) > 0) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _openCheckout(plan),
            icon: const Icon(Icons.refresh),
            label: Text(_copy(context, 'Renouveler ce forfait',
                'Renew this plan')),
          ),
        ],
      ],
    );
  }

  Widget _recommendationCard(
    BuildContext context,
    bool tv,
    Map<String, dynamic>? plan,
  ) {
    if (plan == null) {
      return _panel(
        context,
        tv: tv,
        icon: Icons.workspace_premium_outlined,
        title: _copy(context, 'Votre forfait', 'Your plan'),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        children: [
          Text(_copy(
            context,
            'Vous profitez déjà du forfait le plus complet.',
            'You already have the highest available plan.',
          )),
        ],
      );
    }

    final current = _currentPlan;
    final currentIndex = current == null
        ? -1
        : _plans.indexWhere((item) => item['slug'] == current['slug']);
    final recommendedIndex =
        _plans.indexWhere((item) => item['slug'] == plan['slug']);
    final upgrade = current != null &&
        ((currentIndex >= 0 && recommendedIndex > currentIndex) ||
            _order(plan) > _order(current));
    final title = plan['name']?.toString() ?? '';
    final benefits = <Widget>[];
    final maxDevices = (plan['max_devices'] as num?)?.toInt();
    final quality = plan['max_quality']?.toString();
    if (maxDevices != null) {
      benefits.add(Chip(
        avatar: const Icon(Icons.devices, size: 18),
        label: Text(_copy(
          context,
          maxDevices.toString() + ' écrans simultanés',
          maxDevices.toString() + ' simultaneous screens',
        )),
      ));
    }
    if (quality != null && quality.isNotEmpty) {
      benefits.add(Chip(
        avatar: const Icon(Icons.high_quality, size: 18),
        label: Text(_copy(context, 'Qualité ' + quality, 'Quality ' + quality)),
      ));
    }
    if (plan['download_enabled'] == true) {
      benefits.add(Chip(
        avatar: const Icon(Icons.download_outlined, size: 18),
        label: Text(_copy(context, 'Téléchargement hors ligne', 'Offline downloads')),
      ));
    }
    if (plan['tv_enabled'] == true) {
      benefits.add(Chip(
        avatar: const Icon(Icons.tv, size: 18),
        label: Text(_copy(context, 'Compatible TV', 'TV support')),
      ));
    }
    if (plan['ads_included'] is bool) {
      final includesAds = plan['ads_included'] == true;
      benefits.add(Chip(
        avatar: Icon(
          includesAds ? Icons.ads_click : Icons.do_not_disturb_on_outlined,
          size: 18,
        ),
        label: Text(includesAds
            ? _copy(context, 'Avec publicité', 'Includes ads')
            : _copy(context, 'Sans publicité', 'Ad-free')),
      ));
    }
    return _panel(
      context,
      tv: tv,
      icon: Icons.auto_awesome,
      title: upgrade
          ? _copy(context, 'Passez au niveau supérieur', 'Upgrade your plan')
          : _copy(context, 'Découvrez nos forfaits', 'Explore our plans'),
      color: Theme.of(context).colorScheme.primaryContainer,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          _price(plan) + ' / ' + _period(plan),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (benefits.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: benefits,
          ),
          const SizedBox(height: 8),
        ],
        Text(
          upgrade
              ? _copy(
                  context,
                  'Comparez les avantages de cette formule avant de confirmer le paiement.',
                  'Review this plan’s benefits before confirming payment.',
                )
              : _copy(
                  context,
                  'Choisissez une formule adaptée à votre usage et à vos appareils.',
                  'Choose the plan that fits your viewing habits and devices.',
                ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _openCheckout(plan),
          icon: const Icon(Icons.arrow_upward),
          label: Text(
            upgrade
                ? _copy(context, 'Passer à ' + title, 'Upgrade to ' + title)
                : _copy(context, 'Choisir ' + title, 'Choose ' + title),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_error!),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: Text(_copy(context, 'Réessayer', 'Try again')),
              ),
            ],
          ),
        ),
      );
    }

    final recommended = _recommendedPlan;
    final tv = AppResponsive.isTVSize(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final current = _subscription == null
                ? null
                : _currentPlanCard(context, tv);
            final next = _recommendationCard(context, tv, recommended);
            if (current == null || !wide) {
              return Column(
                children: [
                  if (current != null) current,
                  if (current != null) const SizedBox(height: 12),
                  next,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: current),
                const SizedBox(width: 16),
                Expanded(child: next),
              ],
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            _copy(
              context,
              'Les tarifs et la durée affichés proviennent des offres disponibles dans votre région.',
              'Prices and billing periods come from the offers available in your region.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
