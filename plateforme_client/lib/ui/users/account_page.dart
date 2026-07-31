import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';
import 'package:app_ekeflicks/providers/profile_provider.dart';
import 'package:app_ekeflicks/ui/users/change_password_page.dart';
import 'package:app_ekeflicks/src/models/profile.dart';
import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:app_ekeflicks/core/app_decorations.dart';
import 'package:app_ekeflicks/services/geolocation_service.dart';
import 'package:app_ekeflicks/widgets/dialog/country_selection_dialog.dart';

class AccountPage extends StatefulWidget {
  final Profile currentProfile;

  const AccountPage({super.key, required this.currentProfile});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  late TabController _tabController;
  int _currentTabIndex = 0;

  List<Map<String, dynamic>>? _billingHistory;
  List<Map<String, dynamic>>? _favoriteContents;
  List<Map<String, dynamic>>? _downloadedContents;

  int _selectedAge = 13;
  bool _isLoading = false;
  bool _isChildProfile = false;
  bool _isMainProfile = false;
  String? _selectedCountry;
  bool _detectingLocation = false;
  String? _detectedCountry;

  // Animations
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _nameController.text = widget.currentProfile.name ?? '';
    _phoneController.text = widget.currentProfile.phone ?? '';
    _selectedAge = widget.currentProfile.age ?? 13;
    _isChildProfile = widget.currentProfile.type?.name == 'child';
    _isMainProfile = widget.currentProfile.type?.name == 'main';
    
    // Initialiser le pays sélectionné
    _selectedCountry = widget.currentProfile.country?.name ?? 'FR';
    
    // Initialisation des contrôleurs
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeInOut),
    );

    _loadInitialData();
    _fadeAnimationController.forward();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _fadeAnimationController.reset();
      _fadeAnimationController.forward();
    }
    setState(() {
      _currentTabIndex = _tabController.index;
    });
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    await Future.wait([
      _loadBillingHistory(),
      _loadFavorites(),
      _loadDownloads(),
    ]);
    
    setState(() => _isLoading = false);
  }

  /// Facturation - Simulation
  Future<void> _loadBillingHistory() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    
    setState(() {
      _billingHistory = [
        {
          'date': '15/10/2023', 
          'amount': 9.99, 
          'status': 'Payé',
          'icon': Icons.check_circle,
          'color': Colors.green
        },
        {
          'date': '15/09/2023', 
          'amount': 9.99, 
          'status': 'Payé',
          'icon': Icons.check_circle,
          'color': Colors.green
        },
        {
          'date': '15/08/2023', 
          'amount': 9.99, 
          'status': 'Remboursé',
          'icon': Icons.undo,
          'color': Colors.orange
        },
      ];
    });
  }

  /// Favoris - Simulation
  Future<void> _loadFavorites() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    
    setState(() {
      _favoriteContents = [
        {
          'id': '1',
          'title': 'Interstellar',
          'description': "Film de science-fiction",
          'image': 'https://picsum.photos/100/150?random=1',
          'rating': 4.8,
        },
        {
          'id': '2',
          'title': 'Inception',
          'description': "Film de science-fiction",
          'image': 'https://picsum.photos/100/150?random=2',
          'rating': 4.7,
        },
      ];
    });
  }

  /// Téléchargements - Simulation
  Future<void> _loadDownloads() async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    
    setState(() {
      _downloadedContents = [
        {
          'id': '3',
          'title': 'The Dark Knight',
          'description': "Film Batman",
          'image': 'https://picsum.photos/100/150?random=3',
          'size': '2.4 GB',
          'progress': 100,
        },
        {
          'id': '4',
          'title': 'Pulp Fiction',
          'description': "Film culte",
          'image': 'https://picsum.photos/100/150?random=4',
          'size': '1.8 GB',
          'progress': 75,
        },
      ];
    });
  }

  /// Mise à jour du profil
  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty) {
      _showErrorSnackbar('Veuillez saisir un nom');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final apiClient = profileProvider.apiClient;

      final updatedProfile = Profile(
        (b) => b
          ..id = widget.currentProfile.id
          ..name = _nameController.text
          ..phone = _phoneController.text
          ..age = _isChildProfile ? _selectedAge : null
          ..type = widget.currentProfile.type
          ..country = _getCountryEnum(_selectedCountry)
          ..isActive = widget.currentProfile.isActive
          ..user = widget.currentProfile.user,
      );

      await apiClient.getProfilesApi().profilesUpdate(
        id: widget.currentProfile.id!,
        data: updatedProfile,
      );

      await profileProvider.loadProfiles();

      _showSuccessSnackbar('Profil mis à jour avec succès');
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la mise à jour: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Contrôle parental
  Future<void> _updateParentalControls() async {
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _showSuccessSnackbar('Paramètres parentaux mis à jour');
    } catch (e) {
      _showErrorSnackbar('Erreur lors de la mise à jour: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Détection automatique du pays par IP
  Future<void> _detectCountryByIP() async {
    setState(() => _detectingLocation = true);

    try {
      final locationData = await GeolocationService.detectCountryByIP();
      
      if (locationData != null && mounted) {
        setState(() {
          _detectedCountry = '${locationData['country']} (${locationData['countryCode']})';
          _selectedCountry = locationData['countryCode'];
        });
        
        _showSuccessSnackbar('Pays détecté: ${locationData['country']}');
      } else {
        _showErrorSnackbar('Impossible de détecter votre pays');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Erreur de détection: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _detectingLocation = false);
      }
    }
  }

  /// Afficher le dialogue de sélection de pays
  void _showCountrySelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => CountrySelectionDialog(
        currentCountry: _selectedCountry,
        onCountrySelected: (countryCode) {
          setState(() => _selectedCountry = countryCode);
          Navigator.pop(context);
        },
      ),
    );
  }

  ProfileCountryEnum? _getCountryEnum(String? countryCode) {
    if (countryCode == null) return null;
    try {
      return ProfileCountryEnum.valueOf(countryCode);
    } catch (e) {
      return ProfileCountryEnum.FR;
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AppLocalizations? loc) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;
    final userEmail = currentUser?.email ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryOrange.withOpacity(0.1),
            AppTheme.primaryOrange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (widget.currentProfile.avatarUrl != null && widget.currentProfile.avatarUrl!.isNotEmpty)
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(widget.currentProfile.avatarUrl!),
              onBackgroundImageError: (exception, stackTrace) {
                setState(() {});
              },
            )
          else
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primaryOrange,
              child: Icon(
                _isChildProfile ? Icons.child_care : Icons.person,
                size: 40,
                color: Colors.white,
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.currentProfile.name ?? 'Sans nom',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getProfileTypeDisplayName(widget.currentProfile.type?.name),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                // Afficher l'email UNIQUEMENT pour le profil principal
                if (_isMainProfile && userEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (_isChildProfile && widget.currentProfile.age != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Âge: ${widget.currentProfile.age} ans',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getProfileTypeDisplayName(String? type) {
    switch (type) {
      case 'main':
        return 'Profil Principal';
      case 'child':
        return 'Profil Enfant';
      case 'guest':
        return 'Profil Invité';
      default:
        return 'Profil';
    }
  }

  Widget _buildTabBar(BuildContext context, AppLocalizations? loc) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppTheme.primaryOrange,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        tabs: [
          Tab(icon: Icon(Icons.person), text: loc?.profil ?? 'Profil'),
          Tab(icon: Icon(Icons.history), text: loc?.facturation ?? 'Facturation'),
          Tab(icon: Icon(Icons.favorite), text: loc?.favoris ?? 'Favoris'),
          Tab(icon: Icon(Icons.download), text: loc?.telechargements ?? 'Téléch.'),
        ],
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context, AppLocalizations? loc) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;
    final userEmail = currentUser?.email ?? '';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildSection(
              title: 'Informations du profil',
              icon: Icons.info_outline,
              child: Column(
                children: [
                  // Afficher l'email UNIQUEMENT pour le profil principal
                  if (_isMainProfile) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.email_outlined, size: 20, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  userEmail,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  TextField(
                    controller: _nameController,
                    decoration: AppDecorations.inputDecoration(
                      context,
                      label: 'Nom',
                      icon: Icons.person_outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: _phoneController,
                    decoration: AppDecorations.inputDecoration(
                      context,
                      label: 'Téléphone',
                      icon: Icons.phone,
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  
                  // Sélecteur de pays amélioré
                  _buildCountrySelector(),
                ],
              ),
            ),

            // Modification du mot de passe uniquement pour le profil principal
            if (_isMainProfile) ...[
              const SizedBox(height: 20),
              _buildSection(
                title: 'Sécurité',
                icon: Icons.security,
                child: ListTile(
                  title: Text(
                    'Modifier le mot de passe',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  leading: Icon(Icons.lock, color: AppTheme.primaryOrange),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChangePasswordPage()),
                    );
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  tileColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                ),
              ),
            ],

            // Contrôle parental uniquement pour les profils enfants
            if (_isChildProfile) ...[
              const SizedBox(height: 20),
              _buildSection(
                title: 'Contrôle parental',
                icon: Icons.family_restroom,
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: _selectedAge,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedAge = val);
                      },
                      decoration: AppDecorations.inputDecoration(
                        context,
                        label: 'Âge maximal',
                      ),
                      items: [3, 7, 10, 13, 16, 18]
                          .map((age) => DropdownMenuItem(
                                value: age,
                                child: Text("$age ans"),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],

            // Actions
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('Sauvegarder'),
                  ),
                ),
                if (_isChildProfile) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _updateParentalControls,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Contrôles'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCountrySelector() {
    final currentCountry = _getCountryByCode(_selectedCountry);

    return Column(
      children: [
        // Affichage du pays actuel
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: AppTheme.primaryOrange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pays',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentCountry['name'] ?? 'Non spécifié',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_detectedCountry != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Détecté: $_detectedCountry',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Boutons d'action
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _detectingLocation ? null : _detectCountryByIP,
                icon: _detectingLocation
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.my_location, size: 18),
                label: Text(_detectingLocation ? 'Détection...' : 'Détecter automatiquement'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showCountrySelectionDialog,
                icon: Icon(Icons.flag, size: 18),
                label: Text('Changer manuellement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Map<String, String> _getCountryByCode(String? countryCode) {
    if (countryCode == null) return {'name': 'Non spécifié', 'flag': '🏳️'};
    
    final country = GeolocationService.popularCountries.firstWhere(
      (c) => c['code'] == countryCode,
      orElse: () => {'name': 'Inconnu', 'flag': '🏳️'},
    );
    
    return country;
  }

  Widget _buildBillingTab(BuildContext context, AppLocalizations? loc) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildSection(
        title: loc?.facturation ?? 'Historique de facturation',
        icon: Icons.receipt_long,
        child: _billingHistory == null
            ? _buildLoadingState()
            : _billingHistory!.isEmpty
                ? _buildEmptyState(
                    icon: Icons.receipt,
                    message: loc?.aucuneFacture ?? 'Aucune facture disponible',
                  )
                : Column(
                    children: _billingHistory!.map((item) => _buildBillingItem(item)).toList(),
                  ),
      ),
    );
  }

  Widget _buildFavoritesTab(BuildContext context, AppLocalizations? loc) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildSection(
        title: loc?.favoris ?? 'Contenus favoris',
        icon: Icons.favorite_border,
        child: _favoriteContents == null
            ? _buildLoadingState()
            : _favoriteContents!.isEmpty
                ? _buildEmptyState(
                    icon: Icons.favorite,
                    message: loc?.aucunFavori ?? 'Aucun favori pour le moment',
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: _favoriteContents!.length,
                    itemBuilder: (context, index) => _buildContentCard(_favoriteContents![index]),
                  ),
      ),
    );
  }

  Widget _buildDownloadsTab(BuildContext context, AppLocalizations? loc) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildSection(
        title: loc?.telechargements ?? 'Contenus téléchargés',
        icon: Icons.download_for_offline,
        child: _downloadedContents == null
            ? _buildLoadingState()
            : _downloadedContents!.isEmpty
                ? _buildEmptyState(
                    icon: Icons.download,
                    message: loc?.aucunTelechargement ?? 'Aucun téléchargement',
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: _downloadedContents!.length,
                    itemBuilder: (context, index) => _buildDownloadCard(_downloadedContents![index]),
                  ),
      ),
    );
  }

  Widget _buildSection({required String title, required IconData icon, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryOrange, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildBillingItem(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(item['icon'] as IconData, color: item['color'] as Color),
        title: Text(item['date'].toString()),
        subtitle: Text("${item['amount']}€ - ${item['status']}"),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildContentCard(Map<String, dynamic> content) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.network(
                content['image'].toString(),
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.movie, color: Colors.grey[600]),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content['title'].toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (content['rating'] != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        content['rating'].toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadCard(Map<String, dynamic> content) {
    return Card(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Image.network(
                    content['image'].toString(),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.movie, color: Colors.grey[600]),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content['title'].toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (content['size'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        content['size'].toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (content['progress'] != null && content['progress'] < 100)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${content['progress']}%',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryOrange),
            const SizedBox(height: 8),
            Text(
              'Chargement...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _tabController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc?.compte ?? "Compte"),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navigation vers les paramètres avancés
            },
          ),
        ],
      ),
      body: _isLoading && _billingHistory == null
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange))
          : Column(
              children: [
                // Header du profil
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildProfileHeader(context, loc),
                ),

                // Barre d'onglets
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildTabBar(context, loc),
                ),

                // Contenu des onglets
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProfileTab(context, loc),
                        _buildBillingTab(context, loc),
                        _buildFavoritesTab(context, loc),
                        _buildDownloadsTab(context, loc),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}