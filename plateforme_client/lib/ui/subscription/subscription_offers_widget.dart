import 'package:flutter/material.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/core/app_theme.dart';


class SubscriptionOffer {
  final String title;
  final String? price;
  final String quality;
  final String resolution;
  final String devicesSupported;
  final int simultaneousDevices;
  final int downloadsAllowed;
  final bool adsIncluded;
  final String planSlug;
  final bool skipsPayment;

  SubscriptionOffer({
    required this.title,
    required this.price,
    required this.quality,
    required this.resolution,
    required this.devicesSupported,
    required this.simultaneousDevices,
    required this.downloadsAllowed,
    required this.adsIncluded,
    required this.planSlug,
    this.skipsPayment = false,
  });
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

  final List<SubscriptionOffer> offers = [
    SubscriptionOffer(
      title: "Free 30 Days",
      price: "0.00",
      quality: "Standard",
      resolution: "720p",
      devicesSupported: "TV, ordinateur, smartphone, tablette",
      simultaneousDevices: 1,
      downloadsAllowed: 0,
      adsIncluded: true,
      planSlug: 'free-30-days',
      skipsPayment: true,
    ),
    SubscriptionOffer(
      title: "Basic",
      price: "5.99",
      quality: "Standard",
      resolution: "720p",
      devicesSupported: "TV, ordinateur, smartphone, tablette",
      simultaneousDevices: 1,
      downloadsAllowed: 1,
      adsIncluded: true,
      planSlug: 'basic',
    ),
    SubscriptionOffer(
      title: "Standard",
      price: "9.99",
      quality: "Good",
      resolution: "1080p",
      devicesSupported: "TV, ordinateur, smartphone, tablette",
      simultaneousDevices: 2,
      downloadsAllowed: 2,
      adsIncluded: false,
      planSlug: 'standard',
    ),
    SubscriptionOffer(
      title: "Premium",
      price: "13.99",
      quality: "High",
      resolution: "4K",
      devicesSupported: "TV, ordinateur, smartphone, tablette",
      simultaneousDevices: 4,
      downloadsAllowed: 4,
      adsIncluded: false,
      planSlug: 'premium',
    ),
    SubscriptionOffer(
      title: "Family",
      price: "17.99",
      quality: "High",
      resolution: "4K",
      devicesSupported: "TV, ordinateur, smartphone, tablette",
      simultaneousDevices: 6,
      downloadsAllowed: 6,
      adsIncluded: false,
      planSlug: 'family',
    ),
    SubscriptionOffer(
      title: "Ad-Supported",
      price: "3.99",
      quality: "Standard",
      resolution: "720p",
      devicesSupported: "TV, ordinateur, smartphone, tablette",
      simultaneousDevices: 1,
      downloadsAllowed: 0,
      adsIncluded: true,
      planSlug: 'ad-supported',
    ),
  ];

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
              final isFree = offer.skipsPayment;

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
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
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
                                "GRATUIT 30 JOURS",
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
                              "0€ / 30 jours",
                              style: AppTheme.offerPriceStyle(context).copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Essai gratuit de 30 jours",
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ] else ...[
                            Text(
                              offer.price != null
                                  ? loc.prixParMois("${offer.price!}€")
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
          if (offer.skipsPayment) ...[
            infoRow(Icons.timer, "Durée", "30 jours"),
            infoRow(Icons.card_giftcard, "Type", "Essai gratuit"),
          ] else ...[
            infoRow(Icons.monetization_on, loc.abonnementMensuel,
                offer.price != null ? "${offer.price}€" : loc.prixNonDisponible),
          ],
          infoRow(Icons.high_quality, loc.qualite, offer.quality),
          infoRow(Icons.tv, loc.resolution, offer.resolution),
          infoRow(Icons.devices, loc.appareilsPrisEnCharge, offer.devicesSupported),
          infoRow(Icons.group, loc.appareilsSimultanes, offer.simultaneousDevices.toString()),
          infoRow(Icons.download, loc.telechargement, offer.downloadsAllowed.toString()),
          infoRow(Icons.ads_click, loc.publicites, offer.adsIncluded ? loc.oui : loc.non),
        ],
      ),
    );
  }
}
