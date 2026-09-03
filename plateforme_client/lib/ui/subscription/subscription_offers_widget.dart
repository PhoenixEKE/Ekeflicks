import 'package:flutter/material.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';
import 'package:provider/provider.dart';


class SubscriptionOffer {
  final String title;
  final String? price;
  final String currency;
  final String quality;
  final String resolution;
  final String devicesSupported;
  final int simultaneousDevices;
  final bool downloadEnabled;
  final bool adsIncluded;
  final String planSlug;
  final int durationDays;

  SubscriptionOffer({
    required this.title,
    required this.price,
    required this.currency,
    required this.quality,
    required this.resolution,
    required this.devicesSupported,
    required this.simultaneousDevices,
    required this.downloadEnabled,
    required this.adsIncluded,
    required this.planSlug,
    required this.durationDays,
  });
  String get currencyLabel {
    switch (currency.toUpperCase()) {
      case 'XOF':
      case 'XAF':
        return 'FCFA';
      case 'EUR':
        return '€';
      case 'USD':
        return r'$';
      default:
        return currency.toUpperCase();
    }
  }

  String get formattedPrice {
    final rawPrice = price ?? '';
    final parsed = double.tryParse(rawPrice.replaceAll(',', '.'));

    final formatted =
        parsed != null && parsed == parsed.truncateToDouble()
            ? parsed.toInt().toString()
            : rawPrice;

    return '$formatted $currencyLabel';
  }



  bool get isFree {
    final normalizedTitle = title.trim().toLowerCase();
    final parsedPrice = double.tryParse((price ?? '').replaceAll(',', '.'));

    return planSlug == 'free-30-days' ||
        price == null ||
        parsedPrice == 0 ||
        normalizedTitle == 'free' ||
        normalizedTitle == 'gratuit' ||
        normalizedTitle == 'gratuite';
  }
}

class SubscriptionOffersWidget extends StatefulWidget {
  final void Function(SubscriptionOffer offer)? onOfferSelected;

  const SubscriptionOffersWidget({super.key, this.onOfferSelected});

  @override
  State<SubscriptionOffersWidget> createState() => _SubscriptionOffersWidgetState();
}

class _SubscriptionOffersWidgetState extends State<SubscriptionOffersWidget> {
  int? _selectedIndex;
  int? hoveredIndex;

  List<SubscriptionOffer> offers = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    try {
      final userProvider = context.read<UserProvider>();

      final response =
          await userProvider.apiClient.dio.get<Map<String, dynamic>>(
        '/subscription-plans/',
      );

      final payload = response.data;
      final rawPlans = payload?['results'] ?? payload;

      if (rawPlans is! List) {
        throw StateError('Liste des offres indisponible.');
      }

      final loadedOffers = rawPlans
          .whereType<Map>()
          .where((plan) => plan['is_active'] == true)
          .map((plan) {
        final price = plan['price']?.toString();
        final currency =
            plan['currency']?.toString().toUpperCase() ?? 'EUR';
        final maxDevices = (plan['max_devices'] as num?)?.toInt() ?? 1;
        final quality = plan['max_quality']?.toString() ?? 'HD';
        final downloadEnabled = plan['download_enabled'] == true;

        return SubscriptionOffer(
          title: plan['name']?.toString() ?? '',
          price: price,
            currency: currency,
          quality: quality,
          resolution: quality,
          devicesSupported: 'TV, ordinateur, smartphone, tablette',
          simultaneousDevices: maxDevices,
          downloadEnabled: downloadEnabled,
          adsIncluded: plan['ads_included'] == true,
          planSlug: plan['slug']?.toString() ?? '',
          durationDays: (plan['duration_days'] as num?)?.toInt() ?? 30,
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        offers = loadedOffers;
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  void _selectOffer(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (widget.onOfferSelected != null) {
      widget.onOfferSelected!(offers[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40),
              const SizedBox(height: 12),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _loadError = null;
                  });
                  _loadOffers();
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 600;

        final double cardWidth = isDesktop
            ? 200
            : (constraints.maxWidth > 450
                ? (constraints.maxWidth / 2) - 12
                : constraints.maxWidth * 0.9);

        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: List.generate(offers.length, (index) {
              final offer = offers[index];
              final isSelected = _selectedIndex == index;
              final isFree = offer.isFree;

              return InkWell(
                onTap: () => _selectOffer(index),
                child: MouseRegion(
                  onEnter: (_) => setState(() => hoveredIndex = index),
                  onExit: (_) => setState(() => hoveredIndex = null),
                  child: Transform(
                    transform: hoveredIndex == index && isDesktop
                        ? (Matrix4.identity()..scale(1.03))
                        : Matrix4.identity(),
                    alignment: Alignment.center,
                    child: Container(
                      width: cardWidth,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                            : Theme.of(context).cardColor,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : (isFree ? Colors.green : Colors.grey),
                          width: isFree ? 3 : 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Badge "GRATUIT" pour l'offre free
                          if (isFree) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "GRATUIT ${offer.durationDays} JOURS",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Radio<int>(
                            value: index,
                            groupValue: _selectedIndex,
                            onChanged: (value) {
                              if (value != null) _selectOffer(value);
                            },
                          ),
                          Text(
                            offer.title,
                            style: AppTheme.offerTitleStyle(context),
                          ),
                          const SizedBox(height: 8),
                          if (isFree) ...[
                            Text(
                              "GRATUIT / ${offer.durationDays} jours",
                              style: AppTheme.offerPriceStyle(context).copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Essai gratuit de ${offer.durationDays} jours",
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ] else ...[
                            Text(
                              offer.price != null
                                  ? loc.prixParMois(offer.formattedPrice)
                                  : loc.prixNonDisponible,
                              style: AppTheme.offerPriceStyle(context),
                            ),
                          ],
                          if (isDesktop || isSelected) _offerDetails(offer, context),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _offerDetails(SubscriptionOffer offer, BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[850] : Colors.grey[200];

    Widget infoRow(IconData icon, String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTheme.offerDetailLabelStyle(context)),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      value,
                      style: AppTheme.offerDetailValueStyle(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (offer.isFree) ...[
            infoRow(Icons.timer, "Durée", "${offer.durationDays} jours"),
            infoRow(Icons.card_giftcard, "Type", "Essai gratuit"),
          ] else ...[
            infoRow(Icons.monetization_on, loc.abonnementMensuel,
                offer.price != null ? offer.formattedPrice : loc.prixNonDisponible),
          ],
          infoRow(Icons.high_quality, loc.qualite, offer.quality),
          infoRow(Icons.tv, loc.resolution, offer.resolution),
          infoRow(Icons.devices, loc.appareilsPrisEnCharge, offer.devicesSupported),
          infoRow(Icons.group, loc.appareilsSimultanes, offer.simultaneousDevices.toString()),
          infoRow(Icons.download, loc.telechargement, offer.downloadEnabled ? loc.oui : loc.non),
          infoRow(Icons.ads_click, loc.publicites, offer.adsIncluded ? loc.oui : loc.non),
        ],
      ),
    );
  }
}
