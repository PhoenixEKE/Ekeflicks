import 'package:flutter/material.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'subscription_offers_widget.dart';
import 'subscription_step2_page.dart';
import 'package:app_ekeflicks/widgets/footers/reusable_footer.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';
import 'package:app_ekeflicks/providers/profile_provider.dart';
import 'package:app_ekeflicks/services/subscription_progress_service.dart';
import 'package:app_ekeflicks/ui/profiles/profile_selection_page.dart';
import 'package:provider/provider.dart';

class SubscriptionStep1Page extends StatefulWidget {
  const SubscriptionStep1Page({super.key, this.accountEmail});

  final String? accountEmail;

  @override
  State<SubscriptionStep1Page> createState() => _SubscriptionStep1PageState();
}

class _SubscriptionStep1PageState extends State<SubscriptionStep1Page> {
  SubscriptionOffer? _selectedOffer;
  bool _isSubmitting = false;

  void _onOfferSelected(SubscriptionOffer offer) {
    setState(() {
      _selectedOffer = offer;
    });
  }

  Future<void> _continueSubscription() async {
    final offer = _selectedOffer!;
    final userProvider = context.read<UserProvider>();
    final email = widget.accountEmail ?? userProvider.currentUser?.email;

    if (offer.skipsPayment) {
      setState(() => _isSubmitting = true);
      try {
        await userProvider.activateFreeSubscription(offer.planSlug);
        if (email != null) {
          await SubscriptionProgressService().complete(email);
        }
        if (!mounted) return;
        await context.read<ProfileProvider>().loadProfiles();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ProfileSelectionPage()),
          (route) => false,
        );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
        );
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
      return;
    }

    if (email != null) {
      await SubscriptionProgressService().continueToPayment(
        email: email,
        offerTitle: offer.title,
        offerPrice: offer.price ?? '',
      );
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionStep2Page(
          offerTitle: offer.title,
          offerPrice: offer.price ?? '',
          accountEmail: email,
        ),
      ),
    );
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
      onWillPop: () async => false, // Empêche le retour en arrière
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

                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        loc.etape1sur2,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      loc.choisissezVotreOffre,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    SubscriptionOffersWidget(onOfferSelected: _onOfferSelected),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
                      child: Text(
                        loc.texteExplicatifAbonnement,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _selectedOffer == null || _isSubmitting
                              ? null
                              : _continueSubscription,
                          child: Text(
                            _isSubmitting ? 'Activation...' : loc.suivant,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
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
