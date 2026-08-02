import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/widgets/app_bars/simple_app_bar.dart';
import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:app_ekeflicks/core/app_decorations.dart';
import 'package:app_ekeflicks/providers/locale_provider.dart';
import 'package:app_ekeflicks/providers/device_info_provider.dart';

class FaqItem {
  final String question;
  final String answer;
  final String category;
  final IconData icon;

  FaqItem({
    required this.question,
    required this.answer,
    required this.category,
    required this.icon,
  });
}

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  late List<FaqItem> faqItems;
  final Map<String, bool> _expandedState = {};
  final _scrollController = ScrollController();
  bool _isLoading = true;
  String _selectedCategory = 'Toutes';

  @override
  void initState() {
    super.initState();
    _loadFaqItems();
  }

  Future<void> _loadFaqItems() async {
    // Simuler un chargement
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    final loc = AppLocalizations.of(context)!;

    setState(() {
      faqItems = [
        // 🔄 CATÉGORIE : Compte et Profil
        FaqItem(
          question: loc.faqQuestion1,
          answer: loc.faqAnswer1,
          category: loc.faqCategoryAccount,
          icon: Icons.account_circle,
        ),
        FaqItem(
          question: loc.faqQuestion2,
          answer: loc.faqAnswer2,
          category: loc.faqCategoryAccount,
          icon: Icons.person_add,
        ),
        FaqItem(
          question: loc.faqQuestion3,
          answer: loc.faqAnswer3,
          category: loc.faqCategoryAccount,
          icon: Icons.family_restroom,
        ),

        // 🔄 CATÉGORIE : Abonnement et Paiement
        FaqItem(
          question: loc.faqQuestion4,
          answer: loc.faqAnswer4,
          category: loc.faqCategorySubscription,
          icon: Icons.payment,
        ),
        FaqItem(
          question: loc.faqQuestion5,
          answer: loc.faqAnswer5,
          category: loc.faqCategorySubscription,
          icon: Icons.cancel,
        ),
        FaqItem(
          question: loc.faqQuestion6,
          answer: loc.faqAnswer6,
          category: loc.faqCategorySubscription,
          icon: Icons.currency_exchange,
        ),

        // 🔄 CATÉGORIE : Contenu et Streaming
        FaqItem(
          question: loc.faqQuestion7,
          answer: loc.faqAnswer7,
          category: loc.faqCategoryContent,
          icon: Icons.movie,
        ),
        FaqItem(
          question: loc.faqQuestion8,
          answer: loc.faqAnswer8,
          category: loc.faqCategoryContent,
          icon: Icons.download,
        ),
        FaqItem(
          question: loc.faqQuestion9,
          answer: loc.faqAnswer9,
          category: loc.faqCategoryContent,
          icon: Icons.language,
        ),

        // 🔄 CATÉGORIE : Technique
        FaqItem(
          question: loc.faqQuestion10,
          answer: loc.faqAnswer10,
          category: loc.faqCategoryTechnical,
          icon: Icons.devices,
        ),
        FaqItem(
          question: loc.faqQuestion11,
          answer: loc.faqAnswer11,
          category: loc.faqCategoryTechnical,
          icon: Icons.wifi,
        ),
        FaqItem(
          question: loc.faqQuestion12,
          answer: loc.faqAnswer12,
          category: loc.faqCategoryTechnical,
          icon: Icons.support_agent,
        ),
      ];

      // Initialiser l'état d'expansion
      for (var item in faqItems) {
        _expandedState[item.question] = false;
      }

      _isLoading = false;
    });
  }

  List<String> get categories {
    final allCategories = faqItems.map((item) => item.category).toSet().toList();
    allCategories.insert(0, 'Toutes');
    return allCategories;
  }

  List<FaqItem> get filteredFaqItems {
    if (_selectedCategory == 'Toutes') {
      return faqItems;
    }
    return faqItems.where((item) => item.category == _selectedCategory).toList();
  }

  void _toggleExpansion(String question) {
    setState(() {
      _expandedState[question] = !(_expandedState[question] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceInfo = Provider.of<DeviceInfoProvider>(context);
    final theme = Theme.of(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: SimpleAppBar(
        logoPath: theme.brightness == Brightness.dark
            ? 'assets/images/logo_dark.png'
            : 'assets/images/logo_light.png',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.brightness == Brightness.dark
                ? [const Color(0xFF121212), Colors.black]
                : [Colors.grey[100]!, Colors.grey[300]!],
          ),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : deviceInfo.isTV
                    ? _buildTVLayout(theme)
                    : isLargeScreen
                        ? _buildDesktopLayout(theme)
                        : _buildMobileLayout(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildTVLayout(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.faq,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 24),
          _buildCategoryFilter(theme, true),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: filteredFaqItems.length,
              itemBuilder: (context, index) {
                final faq = filteredFaqItems[index];
                final isExpanded = _expandedState[faq.question] ?? false;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ExpansionTile(
                      leading: Icon(faq.icon, size: 32, color: AppTheme.primaryOrange),
                      title: Text(
                        faq.question,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            faq.answer,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                              color: theme.colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                      initiallyExpanded: isExpanded,
                      onExpansionChanged: (expanded) => _toggleExpansion(faq.question),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(ThemeData theme) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtres par catégorie - VERTICAL
          Container(
            width: 280, // Largeur augmentée pour les catégories verticales
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.05),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppTheme.borderRadius),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.faq,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Catégories',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildCategoryFilter(theme, false),
                ),
              ],
            ),
          ),

          // Liste des FAQ
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${filteredFaqItems.length} questions',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: filteredFaqItems.length,
                      itemBuilder: (context, index) {
                        final faq = filteredFaqItems[index];
                        final isExpanded = _expandedState[faq.question] ?? false;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: theme.cardColor,
                          elevation: 2,
                          shadowColor: theme.shadowColor.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ExpansionTile(
                            leading: Icon(faq.icon, color: AppTheme.primaryOrange),
                            title: Text(
                              faq.question,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              faq.category,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  faq.answer,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    height: 1.6,
                                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                            initiallyExpanded: isExpanded,
                            onExpansionChanged: (expanded) => _toggleExpansion(faq.question),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context)!.faq,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Catégories',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 12),
              // Sur mobile, on garde un conteneur de hauteur fixe pour les catégories
              Container(
                height: 200, // Hauteur fixe avec défilement
                child: _buildCategoryFilter(theme, false),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: filteredFaqItems.length,
            itemBuilder: (context, index) {
              final faq = filteredFaqItems[index];
              final isExpanded = _expandedState[faq.question] ?? false;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    leading: Icon(faq.icon, color: AppTheme.primaryOrange),
                    title: Text(
                      faq.question,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      faq.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          faq.answer,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                    initiallyExpanded: isExpanded,
                    onExpansionChanged: (expanded) => _toggleExpansion(faq.question),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(ThemeData theme, bool isTV) {
    if (isTV) {
      // Version TV - reste horizontal
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) {
            final isSelected = category == _selectedCategory;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(
                  category,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                backgroundColor: theme.cardColor,
                selectedColor: AppTheme.primaryOrange,
                checkmarkColor: Colors.white,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: isSelected ? AppTheme.primaryOrange : theme.dividerColor,
                    width: 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    } else {
      // Version Desktop/Mobile - catégories verticales
      return Container(
        width: isTV ? null : double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: categories.map((category) {
            final isSelected = category == _selectedCategory;

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: isSelected ? AppTheme.primaryOrange : theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          size: 20,
                          color: isSelected ? Colors.white : AppTheme.primaryOrange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }
  }

  // Méthode pour obtenir l'icône correspondante à chaque catégorie
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Toutes':
      case 'All':
        return Icons.all_inclusive;
      case 'Compte et Profil':
      case 'Account & Profile':
        return Icons.account_circle;
      case 'Abonnement et Paiement':
      case 'Subscription & Payment':
        return Icons.payment;
      case 'Contenu et Streaming':
      case 'Content & Streaming':
        return Icons.movie;
      case 'Support Technique':
      case 'Technical Support':
        return Icons.support_agent;
      default:
        return Icons.help_outline;
    }
  }
}
