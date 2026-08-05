import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/models/content_model.dart';
import 'package:app_ekeflicks/providers/content_provider.dart';
import 'package:app_ekeflicks/providers/locale_provider.dart';
import 'package:app_ekeflicks/providers/profile_provider.dart';
import 'package:app_ekeflicks/widgets/banner/hero_banner.dart';
import 'package:app_ekeflicks/widgets/footers/main_footer.dart';
import 'package:app_ekeflicks/widgets/app_bars/home_app_bar.dart';
import 'package:app_ekeflicks/widgets/dialog/info_dialog.dart';
import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:app_ekeflicks/core/app_decorations.dart';
import 'package:app_ekeflicks/core/api_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _homeFallbackImage = 'assets/images/streaming.webp';
  bool _popupShown = false;
  bool? _isMobile;
  String _priceWithCurrency = "5 €"; // valeur par défaut
  String? _popupText;
  String? _popupTitle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _isMobile = MediaQuery.of(context).size.width < 600;
      await _fetchBestPrice();
      await _loadContent();
      _checkPopupAlreadyShown();
    });
  }

  Future<void> _loadContent() async {
    final loc = AppLocalizations.of(context)!;
    final provider = Provider.of<ContentProvider>(context, listen: false);
    provider.profileId = Provider.of<ProfileProvider>(context, listen: false).currentProfile?.id;
    await provider.loadInitialContent(loc);
  }

  Future<void> _fetchBestPrice() async {
    try {
      final bestPriceData = await _loadBestPriceData();

      if (bestPriceData != null) {
        final price = bestPriceData['best_price'].toString();
        final currency = bestPriceData['currency'] ?? "€";
        final region = bestPriceData['region'];

        final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
        if (region == 'Africa' || region == 'Europe') {
          await localeProvider.setLocale(const Locale('fr'));
        } else {
          await localeProvider.setLocale(const Locale('en'));
        }

        // Attendre la prochaine frame pour que la locale soit appliquée
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final loc = AppLocalizations.of(context)!;
          setState(() {
            _priceWithCurrency = "$price $currency";
            _popupTitle = loc.popupTitreAccueil;
            _popupText = loc.popupTexteAccueil(_priceWithCurrency);
          });
        });
      } else {
        _setDefaultPopupText();
      }
    } catch (e) {
      debugPrint("Erreur récupération prix: $e");
      _setDefaultPopupText();
    }
  }

  Future<Map<String, dynamic>?> _loadBestPriceData() async {
    // Avoid calling action-style best-price endpoints here: some deployed API
    // versions return 404 for them, which creates noisy browser-console XHR
    // errors. The public plans list is the stable endpoint, so derive the best
    // price from the active plans returned by that response.
    final plansResponse = await http.get(ApiConfig.endpoint('subscription-plans'));
    if (plansResponse.statusCode != 200) {
      debugPrint(
        'Subscription plans endpoint failed with status ${plansResponse.statusCode}',
      );
      return null;
    }

    final decoded = json.decode(plansResponse.body);
    final plans = decoded is Map<String, dynamic> && decoded['results'] is List
        ? decoded['results'] as List<dynamic>
        : decoded is List
            ? decoded
            : const [];
    final activePlans = plans.whereType<Map<String, dynamic>>().where(
          (plan) => plan['is_active'] != false && plan['price'] != null,
        );
    Map<String, dynamic>? cheapestPlan;
    double? cheapestPrice;
    for (final plan in activePlans) {
      final price = double.tryParse(plan['price'].toString());
      if (price == null) continue;
      if (cheapestPrice == null || price < cheapestPrice) {
        cheapestPrice = price;
        cheapestPlan = plan;
      }
    }

    if (cheapestPlan == null) return null;
    return {
      'best_price': cheapestPlan['price'],
      'currency': cheapestPlan['currency'] ?? '€',
    };
  }

  void _setDefaultPopupText() {
    final loc = AppLocalizations.of(context)!;
    setState(() {
      _popupTitle = loc.popupTitreAccueil;
      _popupText = loc.popupTexteAccueil("5 €");
    });
  }

  Future<void> _checkPopupAlreadyShown() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyShown = prefs.getBool('welcome_popup_shown') ?? false;

    if (!alreadyShown && _isMobile == false) {
      _showAnimatedWelcomeDialog();
      await prefs.setBool('welcome_popup_shown', true);
    }
  }

  void _showAnimatedWelcomeDialog() {
    final theme = Theme.of(context);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "WelcomePopup",
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: _buildWelcomeDialog(theme),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeDialog(ThemeData theme) {
    final loc = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        decoration: AppDecorations.dialogDecoration(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildWelcomeAvatar(),
            const SizedBox(height: 20),
            Text(
              _popupTitle ?? loc.popupTitreAccueil,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _popupText ?? loc.popupTexteAccueil(_priceWithCurrency),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildWelcomeButton(context, loc, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeAvatar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(60),
      child: Image.asset(
        'assets/avatars/default-profil.webp',
        height: 100,
        width: 100,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildWelcomeButton(BuildContext context, AppLocalizations loc, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: AppDecorations.primaryButtonStyle(context),
        child: Text(loc.fermer),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, Content content) {
    final provider = Provider.of<ContentProvider>(context, listen: false);
    final similarContent = provider.getSimilarContent(content);

    showDialog(
      context: context,
      builder: (context) => InfoDialog(
        content: content,
        similarContent: similarContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final contentProvider = Provider.of<ContentProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Container(
        decoration: AppTheme.pageDecoration(context),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            decoration: AppDecorations.contentContainerDecoration(context),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    child: Column(
                      children: [
                        HeroBanner(
                          contents: contentProvider.featuredContent,
                          onPlayPressed: (content) {
                            if (content.videoUrl.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Aucune URL vidéo disponible')),
                              );
                              return;
                            }
                            Navigator.pushNamed(
                              context,
                              '/player',
                              arguments: {
                                'videoUrl': content.videoUrl,
                                'title': content.title,
                                'imageUrl': content.posterUrl,
                                'contentId': content.id,
                                'resumePosition': content.progress == null
                                    ? null
                                    : Duration(milliseconds: (content.duration.inMilliseconds * content.progress!).round()),
                                'nextEpisode': content.nextEpisode,
                              },
                            );
                          },
                          onInfoPressed: (content) {
                            _showInfoDialog(context, content);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSliderSection(loc.nouveautes, contentProvider.newReleases, context),
                              const SizedBox(height: 20),
                              _buildFeatureBlocks(_generateFeatures(loc), context, _isMobile ?? false),
                              const SizedBox(height: 20),
                              _buildSliderSection(loc.populaires, contentProvider.popularContent, context),
                            ],
                          ),
                        ),
                        MainFooter(isMobile: _isMobile ?? false),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, String>> _generateFeatures(AppLocalizations loc) {
    return [
      {'title': loc.featureTvTitle, 'desc': loc.featureTvDesc, 'image': 'assets/images/tv.webp'},
      {'title': loc.featureAnywhereTitle, 'desc': loc.featureAnywhereDesc, 'image': 'assets/images/anywhere.webp'},
      {'title': loc.featureOfflineTitle, 'desc': loc.featureOfflineDesc, 'image': 'assets/images/offline.webp'},
      {'title': loc.featureStreamingTitle, 'desc': loc.featureStreamingDesc, 'image': 'assets/images/streaming.webp'},
    ];
  }

  Widget _buildSliderSection(String title, List<Content> items, BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 10),
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildCarouselSlider(items, context),
      ],
    );
  }

  Widget _buildCarouselSlider(List<Content> items, BuildContext context) {
    if (items.isEmpty) {
      return SizedBox(
        height: 240,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final itemsPerView = _calculateItemsPerView(width);
            final cardWidth = width / itemsPerView;

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemsPerView,
              itemBuilder: (context, index) => SizedBox(
                width: cardWidth,
                child: _buildFallbackCarouselItem(context),
              ),
            );
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int itemsPerView = _calculateItemsPerView(width);
        itemsPerView = itemsPerView.clamp(1, items.length);
        double viewportFraction = (1 / itemsPerView).clamp(0.2, 1.0);

        return CarouselSlider.builder(
          itemCount: items.length,
          options: CarouselOptions(
            height: 240,
            viewportFraction: viewportFraction,
            enableInfiniteScroll: false,
            enlargeCenterPage: false,
          ),
          itemBuilder: (context, index, _) => _buildCarouselItem(items[index], context),
        );
      },
    );
  }

  int _calculateItemsPerView(double width) {
    if (width < 400) return 1;
    if (width < 600) return 2;
    if (width < 800) return 3;
    return 4;
  }

  Widget _buildFallbackCarouselItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Image.asset(
          _homeFallbackImage,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildCarouselItem(Content item, BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            child: CachedNetworkImage(
              imageUrl: item.posterUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 180,
                decoration: AppDecorations.imagePlaceholderDecoration(context),
              ),
              errorWidget: (context, url, error) => Container(
                height: 180,
                decoration: AppDecorations.imagePlaceholderDecoration(context),
                child: Icon(
                  Icons.broken_image,
                  color: Colors.grey[400],
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBlocks(List<Map<String, String>> features, BuildContext context, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 40),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          runSpacing: 24,
          children: features.map((feature) => _buildFeatureItem(feature, context, isMobile)).toList(),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(Map<String, String> feature, BuildContext context, bool isMobile) {
    final theme = Theme.of(context);
    return Container(
      width: isMobile ? (MediaQuery.of(context).size.width / 2) - 32 : 220,
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.featureItemDecoration(context),
      child: Column(
        children: [
          Image.asset(feature['image']!, height: 80),
          const SizedBox(height: 12),
          Text(
            feature['title']!,
            style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.primaryOrange),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            feature['desc']!,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
