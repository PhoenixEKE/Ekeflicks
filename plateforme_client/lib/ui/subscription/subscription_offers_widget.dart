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

  SubscriptionOffer({
    required this.title,
    required this.price,
    required this.quality,
    required this.resolution,
    required this.devicesSupported,
    required this.simultaneousDevices,
    required this.downloadsAllowed,
    required this.adsIncluded,
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
      title: "Basic",
      price: "5.99",
      quality: "Standard",
      resolution: "720p",
      devicesSupported: "TV, ordinateur, smartphone, tablette",
      simultaneousDevices: 1,
      downloadsAllowed: 1,
      adsIncluded: true,
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
                              : Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                          Text(
                            offer.price != null
                                ? loc.prixParMois("${offer.price!}€")
                                : loc.prixNonDisponible,
                            style: AppTheme.offerPriceStyle(context),
                          ),
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
          infoRow(Icons.monetization_on, loc.abonnementMensuel,
              offer.price != null ? "${offer.price}€" : loc.prixNonDisponible),
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
