import 'package:flutter/material.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/widgets/footers/reusable_footer.dart';
import 'subscription_step1_page.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionStep2Page extends StatefulWidget {
  final String offerTitle;
  final String offerPrice;
  final String offerCurrency;
  final String planSlug;
  final String? accountEmail;

  const SubscriptionStep2Page({
    super.key,
    required this.offerTitle,
    required this.offerPrice,
    required this.offerCurrency,
    required this.planSlug,
    this.accountEmail,
  });

  @override
  State<SubscriptionStep2Page> createState() => _SubscriptionStep2PageState();
}

class _SubscriptionStep2PageState extends State<SubscriptionStep2Page>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _fadeAnimations;
  bool _isProcessingPayment = false;

  final List<PaymentMethod> paymentMethods = [
    PaymentMethod(key: 'visaMaster', label: 'Visa/Mastercard', iconPath: 'assets/payments/visamaster.png'),
    PaymentMethod(key: 'wave', label: 'Wave', iconPath: 'assets/payments/wave.png'),
    PaymentMethod(key: 'orangeMoney', label: 'Orange Money', iconPath: 'assets/payments/orange.png'),
    PaymentMethod(key: 'mtnMoney', label: 'MTN Money', iconPath: 'assets/payments/mtn.png'),
    PaymentMethod(key: 'moovMoney', label: 'Moov Money', iconPath: 'assets/payments/moov.png'),
    PaymentMethod(key: 'paypal', label: 'PayPal', iconPath: 'assets/payments/paypal.png'),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimations = List.generate(paymentMethods.length, (index) {
      final start = index * 0.1;
      final end = start + 0.5;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeIn),
        ),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePaymentTap(String methodKey) async {
    if (_isProcessingPayment) return;

    // Stripe currently handles Visa/Mastercard.
    if (methodKey != 'visaMaster') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(
            AppLocalizations.of(context)!.paymentPageComingSoon,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      final checkoutUrl = await context
          .read<UserProvider>()
          .startStripeCheckout(widget.planSlug);

      final uri = Uri.parse(checkoutUrl);

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_self',
      );

      if (!launched) {
        throw StateError('Impossible d\'ouvrir Stripe Checkout.');
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Bad state: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  String get _formattedOfferPrice {
    final parsed =
        double.tryParse(widget.offerPrice.replaceAll(',', '.'));

    final price =
        parsed != null && parsed == parsed.truncateToDouble()
            ? parsed.toInt().toString()
            : widget.offerPrice;

    switch (widget.offerCurrency.toUpperCase()) {
      case 'XOF':
      case 'XAF':
        return '$price FCFA';
      case 'EUR':
        return '$price €';
      case 'USD':
        return '$price ${r'$'}';
      default:
        return '$price ${widget.offerCurrency.toUpperCase()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final logoPath = isDarkMode
        ? 'assets/images/logo_dark.png'
        : 'assets/images/logo_light.png';

    return WillPopScope(
      onWillPop: () async => false, // Empêche le retour matériel
      child: Scaffold(
        // SUPPRIMÉ: l'AppBar
        body: Container(
          decoration: BoxDecoration(
            gradient: isDarkMode
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.grey.shade900,
                      Colors.black,
                      Colors.grey.shade900,
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.grey.shade100,
                      Colors.white,
                      Colors.grey.shade100,
                    ],
                  ),
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.8)
                        : Colors.grey.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40), // Espacement accru en haut

                    // AJOUT: Logo centré
                    Image.asset(
                      logoPath,
                      height: 60, // Taille réduite pour s'intégrer mieux
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SubscriptionStep1Page(
                                    accountEmail: widget.accountEmail,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            loc.step2of2,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        loc.chooseYourPaymentMethodForOffer(
                            widget.offerTitle,
                            _formattedOfferPrice,
                          ),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        loc.paymentSecureInfo,
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: List.generate(paymentMethods.length, (index) {
                          final method = paymentMethods[index];
                          return FadeTransition(
                            opacity: _fadeAnimations[index],
                            child: _PaymentCard(
                              iconPath: method.iconPath,
                              label: method.label,
                              onTap: () => _handlePaymentTap(method.key),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const ReusableFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentMethod {
  final String key;
  final String label;
  final String iconPath;

  PaymentMethod({
    required this.key,
    required this.label,
    required this.iconPath,
  });
}

class _PaymentCard extends StatefulWidget {
  final String iconPath;
  final String label;
  final VoidCallback onTap;

  const _PaymentCard({
    required this.iconPath,
    required this.label,
    required this.onTap,
  });

  @override
  State<_PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<_PaymentCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDarkMode = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 160,
          height: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  ]
                : [
                    BoxShadow(
                      color: isDarkMode
                        ? Colors.black.withOpacity(0.6)
                        : Colors.grey.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
            border: Border.all(
              color: _isHovered ? primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(widget.iconPath, height: 48),
              const SizedBox(height: 12),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
