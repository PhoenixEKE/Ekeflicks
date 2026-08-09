import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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
import 'package:app_ekeflicks/utils/phone_number.dart';
import 'package:app_ekeflicks/models/content_model.dart';
import 'package:app_ekeflicks/services/content_api_service.dart';
import 'package:app_ekeflicks/widgets/dialog/avatar_selector_dialog.dart';
import 'package:app_ekeflicks/widgets/dialog/account_settings_dialog.dart';
import 'package:app_ekeflicks/providers/avatar_provider.dart';
import 'package:app_ekeflicks/services/profile_access_service.dart';
import 'package:app_ekeflicks/utils/api_error_message.dart';

class AccountPage extends StatefulWidget {
  final Profile currentProfile;

  const AccountPage({super.key, required this.currentProfile});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> with TickerProviderStateMixin {
  late Profile _currentProfile;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  late TabController _tabController;
  int _currentTabIndex = 0;

  List<Map<String, dynamic>>? _billingHistory;
  List<Map<String, dynamic>>? _favoriteContents;
  List<Map<String, dynamic>>? _downloadedContents;

  int _selectedAge = 13;
  RangeValues _allowedAgeRange = const RangeValues(0, 13);
  bool _isLoading = false;
  bool _isChildProfile = false;
  bool _isMainProfile = false;
  bool _isPhoneOnlyAccount = false;
  String? _selectedCountry;
  bool _detectingLocation = false;
  bool _avatarHovered = false;
  String? _detectedCountry;

  // Animations
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.currentProfile;

    _nameController.text = _currentProfile.name ?? '';
    _phoneController.text = _currentProfile.phone ?? '';
    final currentUser = context.read<UserProvider>().currentUser;
    _isPhoneOnlyAccount = currentUser?.email == null || currentUser!.email!.isEmpty;
    _emailController.text = currentUser?.email ?? '';
    const supportedAges = [3, 7, 10, 13, 16, 18];
    final profileAge = _currentProfile.age ?? 13;
    _selectedAge = supportedAges.contains(profileAge) ? profileAge : 13;
    _isChildProfile = _currentProfile.type?.name == 'child';
    _isMainProfile = _currentProfile.type?.name == 'main';

    // Initialiser le pays sélectionné
    _selectedCountry = _currentProfile.country?.name ?? 'FR';

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
      _loadProfileRestrictions(),
      _loadBillingHistory(),
      _loadFavorites(),
      _loadDownloads(),
    ]);

    setState(() => _isLoading = false);
  }

  Future<void> _loadProfileRestrictions() async {
    if (!_isChildProfile || _currentProfile.id == null) return;
    try {
      final response = await context
          .read<ProfileProvider>()
          .apiClient
          .dio
          .get<Object>('/profiles/${_currentProfile.id}/');
      if (response.data is! Map || !mounted) return;
      final data = Map<String, dynamic>.from(response.data! as Map);
      final minimum = (data['allowed_min_age'] as num?)?.toDouble() ?? 0;
      final maximum = (data['allowed_max_age'] as num?)?.toDouble() ?? 13;
      setState(() => _allowedAgeRange = RangeValues(minimum, maximum));
    } catch (error) {
      debugPrint('Account profile restrictions API error: $error');
    }
  }

  List<Map<String, dynamic>> _records(dynamic payload) {
    final data = payload is Map ? (payload['results'] ?? const []) : payload;
    return (data as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  /// Charge les paiements réels du compte.
  Future<void> _loadBillingHistory() async {
    try {
      final dio = context.read<ProfileProvider>().apiClient.dio;
      final response = await dio.get<Object>('/payments/');
      if (mounted) setState(() => _billingHistory = _records(response.data));
    } catch (error) {
      debugPrint('Account billing API error: $error');
      if (mounted) setState(() => _billingHistory = []);
    }
  }

  Map<String, dynamic> _contentCard(Content content) => {
        'id': content.id,
        'title': content.title,
        'description': content.description,
        'image': content.posterUrl.isNotEmpty ? content.posterUrl : content.imageUrl,
        'rating': content.rating,
      };

  /// Charge les favoris du profil actif.
  Future<void> _loadFavorites() async {
    try {
      final dio = context.read<ProfileProvider>().apiClient.dio;
      final contents = await ContentApiService(dio).favorites(
        profileId: _currentProfile.id,
      );
      if (mounted) {
        setState(() => _favoriteContents = contents.map(_contentCard).toList());
      }
    } catch (error) {
      debugPrint('Account favorites API error: $error');
      if (mounted) setState(() => _favoriteContents = []);
    }
  }

  /// Charge les licences de téléchargement hors connexion du profil actif.
  Future<void> _loadDownloads() async {
    try {
      final dio = context.read<ProfileProvider>().apiClient.dio;
      final response = await dio.get<Object>(
        '/offline-licenses/',
        queryParameters: {'profile': _currentProfile.id},
      );
      final downloads = _records(response.data).map((record) {
        final content = record['content'] is Map
            ? Map<String, dynamic>.from(record['content'] as Map)
            : const <String, dynamic>{};
        final asset = record['asset'] is Map
            ? Map<String, dynamic>.from(record['asset'] as Map)
            : const <String, dynamic>{};
        return <String, dynamic>{
          'id': record['id'],
          'title': content['title'] ?? 'Contenu téléchargé',
          'image': content['poster_url'] ?? content['image_url'] ?? '',
          'size': asset['file_size'] == null ? null : '${asset['file_size']} octets',
          'status': record['status'],
          'progress': record['status'] == 'active' ? 100 : 0,
        };
      }).toList(growable: false);
      if (mounted) setState(() => _downloadedContents = downloads);
    } catch (error) {
      debugPrint('Account downloads API error: $error');
      if (mounted) setState(() => _downloadedContents = []);
    }
  }

  /// Mise à jour du profil
  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty) {
      _showErrorSnackbar('Veuillez saisir un nom');
      return;
    }
    final phoneError = _isMainProfile
        ? validateInternationalPhone(_phoneController.text)
        : null;
    if (phoneError != null) {
      _showErrorSnackbar(phoneError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? parentalPin;
      if (_isChildProfile) {
        parentalPin = await ProfileAccessService.askForParentalPin(
          context,
          title: 'Autoriser la modification du profil enfant',
        );
        if (parentalPin == null || parentalPin.isEmpty) return;
      }
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final userProvider = context.read<UserProvider>();
      final apiClient = profileProvider.apiClient;

      if (_isMainProfile && _isPhoneOnlyAccount) {
        if (_emailController.text.trim().isEmpty ||
            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                .hasMatch(_emailController.text.trim())) {
          throw const FormatException('Veuillez saisir une adresse e-mail valide.');
        }
        await userProvider.updatePersonalInfo(
          email: _emailController.text,
          phone: userProvider.accountPhone,
          countryCode: _selectedCountry,
        );
        if (mounted) setState(() => _isPhoneOnlyAccount = false);
      }

      await apiClient.dio.patch<Object>(
        '/profiles/${_currentProfile.id}/',
        data: {
          'name': _nameController.text.trim(),
          'phone': normalizeInternationalPhone(_phoneController.text),
          if (_isChildProfile) 'age': _selectedAge,
          if (_isChildProfile) 'allowed_min_age': _allowedAgeRange.start.round(),
          if (_isChildProfile) 'allowed_max_age': _allowedAgeRange.end.round(),
          if (_isChildProfile) 'parental_pin': parentalPin,
          if (_selectedCountry != null) 'country_code': _selectedCountry,
        },
      );

      await profileProvider.loadProfiles();

      _showSuccessSnackbar('Profil mis à jour avec succès');
    } on DioException catch (error) {
      _showErrorSnackbar(
        firstApiErrorMessage(error.response?.data) ??
            'Impossible d’enregistrer le profil. Vérifiez les informations saisies.',
      );
    } catch (_) {
      _showErrorSnackbar('Impossible d’enregistrer le profil. Veuillez réessayer.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteManagedProfile(Profile profile) async {
    if (profile.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer ce profil ?'),
        content: Text('Le profil « ${profile.name} » sera supprimé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final pin = await ProfileAccessService.askForParentalPin(
      context,
      title: 'Autoriser la suppression du profil',
    );
    if (pin == null || pin.isEmpty || !mounted) return;
    setState(() => _isLoading = true);
    try {
      final provider = context.read<ProfileProvider>();
      await provider.apiClient.dio.delete<Object>(
        '/profiles/${profile.id}/',
        data: {'parental_pin': pin},
        options: Options(headers: {'x-profile-id': _currentProfile.id}),
      );
      await provider.loadProfiles();
      if (mounted) _showSuccessSnackbar('Profil supprimé.');
    } on DioException catch (error) {
      if (mounted) {
        _showErrorSnackbar(
          firstApiErrorMessage(error.response?.data) ??
              'Suppression impossible. Vérifiez le PIN parental puis réessayez.',
        );
      }
    } catch (_) {
      if (mounted) _showErrorSnackbar('Suppression impossible. Veuillez réessayer.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 7),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  Future<void> _changeAvatar() async {
    final avatarProvider = context.read<AvatarProvider>();
    if (avatarProvider.avatars.isEmpty) {
      await avatarProvider.loadAvatars(context.read<UserProvider>().apiClient);
    }
    if (!mounted || avatarProvider.error != null) return;
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AvatarSelectorDialog(
        selectedAvatar: _currentProfile.avatarUrl,
        onAvatarSelected: (url) => Navigator.pop(dialogContext, url),
      ),
    );
    if (selected == null || selected == _currentProfile.avatarUrl || !mounted) return;
    String? parentalPin;
    if (_isChildProfile) {
      parentalPin = await ProfileAccessService.askForParentalPin(
        context,
        title: 'Autoriser la modification de l\'avatar enfant',
      );
      if (parentalPin == null || parentalPin.isEmpty || !mounted) return;
    }
    setState(() => _isLoading = true);
    try {
      final provider = context.read<ProfileProvider>();
      await provider.apiClient.dio.patch<Object>(
        '/profiles/${_currentProfile.id}/',
        data: {
          'avatar_url': selected,
          if (_isChildProfile) 'parental_pin': parentalPin,
        },
      );
      await provider.loadProfiles();
      final refreshed = provider.getProfileById(_currentProfile.id!);
      if (mounted && refreshed != null) setState(() => _currentProfile = refreshed);
      _showSuccessSnackbar('Avatar modifié avec succès');
    } catch (error) {
      _showErrorSnackbar('Impossible de modifier l\'avatar : $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _avatarHovered = true),
            onExit: (_) => setState(() => _avatarHovered = false),
            child: AnimatedScale(
              scale: _avatarHovered ? 1.08 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: Tooltip(
                message: 'Modifier l\'avatar',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _changeAvatar,
                  child: ClipOval(
                    child: _currentProfile.avatarUrl?.isNotEmpty == true
                    ? Image.network(
                        _currentProfile.avatarUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                      )
                    : _buildDefaultAvatar(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentProfile.name ?? 'Sans nom',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getProfileTypeDisplayName(_currentProfile.type?.name),
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
                if (_isChildProfile && _currentProfile.age != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Âge: ${_currentProfile.age} ans',
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

  Widget _buildDefaultAvatar() => Image.asset(
        _isChildProfile
            ? 'assets/avatars/child.png'
            : 'assets/avatars/adult.png',
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 80,
          height: 80,
          color: AppTheme.primaryOrange,
          child: const Icon(Icons.person, size: 40, color: Colors.white),
        ),
      );

  Widget _buildTabBar(BuildContext context, AppLocalizations? loc) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppTheme.primaryOrange,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        tabs: [
          const Tab(icon: Icon(Icons.person), text: 'Profil'),
          const Tab(icon: Icon(Icons.history), text: 'Facturation'),
          const Tab(icon: Icon(Icons.favorite), text: 'Favoris'),
          const Tab(icon: Icon(Icons.download), text: 'Téléch.'),
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

                  if (_isMainProfile) ...[
                    if (!_isPhoneOnlyAccount)
                      TextField(
                        controller: _phoneController,
                        decoration: AppDecorations.inputDecoration(
                          context,
                          label: 'Téléphone avec indicatif (+225…)',
                          icon: Icons.phone,
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    if (_isPhoneOnlyAccount)
                      TextField(
                        controller: _emailController,
                        decoration: AppDecorations.inputDecoration(
                          context,
                          label: 'Adresse e-mail du compte principal',
                          icon: Icons.email_outlined,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                  ],
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
                    const SizedBox(height: 16),
                    Text(
                      'Films autorisés : ${_allowedAgeRange.start.round()} à ${_allowedAgeRange.end.round()} ans',
                    ),
                    RangeSlider(
                      values: _allowedAgeRange,
                      min: 0,
                      max: 18,
                      divisions: 18,
                      labels: RangeLabels(
                        '${_allowedAgeRange.start.round()} ans',
                        '${_allowedAgeRange.end.round()} ans',
                      ),
                      onChanged: (values) =>
                          setState(() => _allowedAgeRange = values),
                    ),
                  ],
                ),
              ),
            ],

            if (_isMainProfile) ...[
              const SizedBox(height: 20),
              _buildSection(
                title: 'Profils du compte',
                icon: Icons.manage_accounts,
                child: Consumer<ProfileProvider>(
                  builder: (context, provider, _) => Column(
                    children: provider.availableProfiles
                        .where((profile) => profile.type?.name != 'main')
                        .map(
                          (profile) => ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text(profile.name),
                            subtitle: Text(
                              profile.type?.name == 'child'
                                  ? 'Profil enfant'
                                  : 'Profil créé',
                            ),
                            trailing: IconButton(
                              tooltip: 'Supprimer le profil',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: _isLoading
                                  ? null
                                  : () => _deleteManagedProfile(profile),
                            ),
                          ),
                        )
                        .toList(),
                  ),
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
      child: SingleChildScrollView(
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
      ),
    );
  }

  Widget _buildFavoritesTab(BuildContext context, AppLocalizations? loc) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
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
      ),
    );
  }

  Widget _buildDownloadsTab(BuildContext context, AppLocalizations? loc) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
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
    final status = item['status']?.toString() ?? 'pending';
    final isPaid = status == 'succeeded' || status == 'paid';
    final rawDate = item['paid_at'] ?? item['created_at'];
    final parsedDate = rawDate == null ? null : DateTime.tryParse(rawDate.toString());
    final date = parsedDate == null
        ? 'Date indisponible'
        : '${parsedDate.day.toString().padLeft(2, '0')}/'
            '${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isPaid ? Icons.check_circle : Icons.schedule,
          color: isPaid ? Colors.green : Colors.orange,
        ),
        title: Text(date),
        subtitle: Text(
          '${item['amount'] ?? '—'} ${item['currency'] ?? ''} · '
          '${isPaid ? 'Payé' : status}',
        ),
        trailing: const Icon(Icons.receipt_long, size: 18),
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
    return SizedBox(
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
    return SizedBox(
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
    _emailController.dispose();
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
          if (_isMainProfile) IconButton(
            icon: Icon(Icons.settings),
            tooltip: loc?.parametres ?? 'Paramètres',
            onPressed: () async {
              final saved = await showDialog<bool>(
                context: context,
                builder: (_) => AccountSettingsDialog(profile: _currentProfile),
              );
              if (saved == true && mounted) {
                await context.read<ProfileProvider>().loadProfiles();
                _showSuccessSnackbar('Paramètres enregistrés');
              }
            },
          ),
        ],
      ),
      body: _isLoading && _billingHistory == null
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange))
          : SafeArea(
              child: Column(
                children: [
                  // Header du profil
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildProfileHeader(context, loc),
                  ),

                  // Barre d'onglets
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildTabBar(context, loc),
                    ),
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
            ),
    );
  }
}
