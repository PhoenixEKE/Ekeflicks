import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:app_ekeflicks/core/app_decorations.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/widgets/app_bars/simple_app_bar.dart';
import 'package:app_ekeflicks/widgets/keyboards/tv_virtual_keyboard.dart';
import 'package:app_ekeflicks/widgets/dialog/age_selector_dialog.dart';
import 'package:app_ekeflicks/widgets/dialog/avatar_selector_dialog.dart';
import 'package:app_ekeflicks/providers/device_info_provider.dart';
import 'package:app_ekeflicks/providers/locale_provider.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';
import 'package:app_ekeflicks/providers/profile_provider.dart';
import 'package:app_ekeflicks/providers/avatar_provider.dart';

// OpenAPI models
import 'package:app_ekeflicks/src/models/profile_create.dart';
import 'package:app_ekeflicks/src/openapi.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _ageFocus = FocusNode();
  final FocusNode _avatarFocus = FocusNode();
  final FocusNode _typeFocus = FocusNode();
  final FocusNode _createFocus = FocusNode();
  final FocusNode _cancelFocus = FocusNode();
  final FocusNode _languageFocus = FocusNode();
  
  String _selectedType = 'child';
  int? _selectedAge;
  String? _selectedAvatar;
  bool _showVirtualKeyboard = false;
  bool _isLoading = false;
  TextEditingController? _focusedController;

  // Stocker les informations du profil principal de manière simplifiée
  Map<String, dynamic>? _mainProfileData;

  @override
  void initState() {
    super.initState();
    
    // Récupérer le profil principal existant s'il existe
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMainProfile();
      FocusScope.of(context).requestFocus(_nameFocus);
    });

    _nameFocus.addListener(() => _onFieldFocus(_nameController));
    _phoneFocus.addListener(() => _onFieldFocus(_phoneController));
  }

  void _loadMainProfile() {
    final profileProvider = context.read<ProfileProvider>();
    final profiles = profileProvider.availableProfiles;
    
    // Chercher un profil principal existant de manière simplifiée
    try {
      final mainProfile = profiles.firstWhere(
        (profile) => profile.type?.toString().contains('main') ?? false,
      );
      
      // Stocker les données nécessaires dans un Map
      _mainProfileData = {
        'country': mainProfile.country?.toString(),
        'name': mainProfile.name,
      };
    } catch (e) {
      // Aucun profil principal trouvé, c'est normal pour le premier profil
      _mainProfileData = null;
    }
    
    setState(() {});
  }

  void _onFieldFocus(TextEditingController controller) {
    if (!mounted) return;
    final deviceInfo = context.read<DeviceInfoProvider>();
    setState(() {
      _focusedController = controller;
      _showVirtualKeyboard = deviceInfo.isTV;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _ageFocus.dispose();
    _avatarFocus.dispose();
    _typeFocus.dispose();
    _createFocus.dispose();
    _cancelFocus.dispose();
    _languageFocus.dispose();
    super.dispose();
  }

  Future<void> _createProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Le nom du profil est obligatoire');
      return;
    }

    final userProvider = context.read<UserProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final apiClient = userProvider.apiClient;

    if (userProvider.currentUser == null) {
      _showError('Utilisateur non connecté');
      return;
    }

    // Récupérer le token d'authentification
    final token = userProvider.accessToken;
    if (token == null) {
      _showError('Token d\'authentification manquant');
      return;
    }

    // DEBUG: Afficher les informations de la requête
    print('🔐 Token: ${token.substring(0, 20)}...');
    print('👤 Nom du profil: $name');
    print('🎯 Type de profil: $_selectedType');
    print('🖼️ Avatar URL: $_selectedAvatar');
    print('🎂 Âge: $_selectedAge');
    print('📞 Téléphone: ${_phoneController.text}');

    setState(() => _isLoading = true);

    try {
      // EXTRACTION du nom de fichier depuis l'URL
      String? avatarFileName;
      if (_selectedAvatar != null) {
        try {
          final uri = Uri.parse(_selectedAvatar!);
          avatarFileName = uri.pathSegments.last;
          print('📁 Nom de fichier extrait: $avatarFileName');
        } catch (e) {
          print('❌ Erreur extraction nom de fichier: $e');
          avatarFileName = 'adult.png'; // Valeur par défaut
        }
      } else {
        // Avatar par défaut selon le type
        avatarFileName = _selectedType == 'child' ? 'child.png' : 'adult.png';
      }

      // Convertir le pays string en enum si nécessaire
      ProfileCreateCountryEnum? countryEnum;
      final countryCode = _mainProfileData?['country'];
      if (countryCode != null) {
        countryEnum = _parseCountryEnum(countryCode);
        print('🌍 Pays: $countryEnum');
      }

      // Création du profil avec ProfileCreate - utiliser le NOM DE FICHIER seulement
      final profileCreate = ProfileCreate(
        (b) => b
          ..name = name
          ..type = _getProfileTypeEnum()
          ..avatar = avatarFileName // Stocker seulement le nom du fichier
          ..country = countryEnum
          ..age = _selectedAge
          ..phone = _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      );

      print('📤 Envoi de la requête API...');
      print('📤 Avatar (nom fichier): $avatarFileName');

      // Appel à l'API pour créer le profil AVEC LE TOKEN
      await apiClient.getProfilesApi().profilesCreate(
        data: profileCreate,
        headers: {'Authorization': 'Bearer $token'},
      );

      print('✅ Profil créé avec succès');

      // Recharger les profils pour mettre à jour le provider
      await profileProvider.loadProfiles();

      if (mounted) {
        Navigator.pop(context);
        _showSuccess('Profil "$name" créé avec succès !');
      }
    } on DioException catch (dioError) {
      print('❌ Erreur Dio: ${dioError.message}');
      print('❌ Status code: ${dioError.response?.statusCode}');
      print('❌ Response data: ${dioError.response?.data}');
      _handleApiError(dioError);
    } catch (e) {
      print('❌ Erreur générale: $e');
      _showError('Erreur : ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ProfileCreateCountryEnum? _parseCountryEnum(String countryCode) {
    final code = countryCode.replaceAll('ProfileCreateCountryEnum.', '');
    switch (code) {
      case 'FR': return ProfileCreateCountryEnum.FR;
      case 'US': return ProfileCreateCountryEnum.US;
      case 'GB': return ProfileCreateCountryEnum.GB;
      case 'DE': return ProfileCreateCountryEnum.DE;
      case 'ES': return ProfileCreateCountryEnum.ES;
      case 'IT': return ProfileCreateCountryEnum.IT;
      case 'CA': return ProfileCreateCountryEnum.CA;
      case 'BE': return ProfileCreateCountryEnum.BE;
      case 'CH': return ProfileCreateCountryEnum.CH;
      default: return null;
    }
  }

  ProfileCreateTypeEnum _getProfileTypeEnum() {
    switch (_selectedType) {
      case 'main':
        return ProfileCreateTypeEnum.main;
      case 'child':
        return ProfileCreateTypeEnum.child;
      case 'guest':
        return ProfileCreateTypeEnum.guest;
      default:
        return ProfileCreateTypeEnum.child;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleApiError(DioException dioError) {
    String message = 'Erreur lors de la création du profil';
    
    if (dioError.response?.data != null) {
      final data = dioError.response!.data;
      print('📋 Données d\'erreur: $data');
      
      if (data is Map<String, dynamic>) {
        // Essayer différents formats de réponse d'erreur
        message = data['detail'] ?? 
                  data['message'] ?? 
                  data['error'] ?? 
                  message;
        
        // Gestion spécifique des erreurs de validation
        if (data.containsKey('name')) {
          final nameErrors = data['name'];
          if (nameErrors is List && nameErrors.isNotEmpty) {
            message = nameErrors[0] ?? message;
          }
        }
        
        // Vérifier les erreurs de champ
        if (data.containsKey('non_field_errors')) {
          final nonFieldErrors = data['non_field_errors'];
          if (nonFieldErrors is List && nonFieldErrors.isNotEmpty) {
            message = nonFieldErrors[0] ?? message;
          }
        }

        // Erreur spécifique pour l'avatar
        if (data.containsKey('avatar')) {
          final avatarErrors = data['avatar'];
          if (avatarErrors is List && avatarErrors.isNotEmpty) {
            message = avatarErrors[0] ?? message;
          }
        }
      }
    }
    
    // Gestion spécifique par code HTTP
    switch (dioError.response?.statusCode) {
      case 400:
        message = 'Données invalides: $message';
        break;
      case 401:
        message = 'Non autorisé - Token invalide ou expiré';
        break;
      case 403:
        message = 'Accès refusé';
        break;
      case 404:
        message = 'Endpoint non trouvé';
        break;
      case 500:
        message = 'Erreur interne du serveur';
        break;
    }
    
    _showError(message);
  }

  Future<void> _selectAvatar() async {
    final avatarProvider = context.read<AvatarProvider>();
    final userProvider = context.read<UserProvider>();
    
    // Charger les avatars si nécessaire
    if (avatarProvider.avatars.isEmpty && !avatarProvider.isLoading) {
      await avatarProvider.loadAvatars(userProvider.apiClient);
    }

    if (!mounted) return;

    final selectedAvatar = await showDialog<String>(
      context: context,
      builder: (ctx) => AvatarSelectorDialog(
        onAvatarSelected: (avatarUrl) => Navigator.of(ctx).pop(avatarUrl),
        selectedAvatar: _selectedAvatar,
      ),
    );

    if (selectedAvatar != null && mounted) {
      setState(() {
        _selectedAvatar = selectedAvatar;
      });
    }
  }

  Future<void> _selectAge() async {
    final selectedAge = await showDialog<int>(
      context: context,
      builder: (ctx) => AgeSelectorDialog(
        currentAge: _selectedAge,
        profileType: _selectedType,
      ),
    );

    if (selectedAge != null && mounted) {
      setState(() {
        _selectedAge = selectedAge;
      });
    }
  }

  // Raccourcis pour la navigation TV
  final Map<LogicalKeySet, Intent> _shortcuts = {
    LogicalKeySet(LogicalKeyboardKey.arrowDown): const NextFocusIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): const PreviousFocusIntent(),
    LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
    LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final deviceInfo = Provider.of<DeviceInfoProvider>(context);
    final hasMainProfile = _mainProfileData != null;

    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: {
          NextFocusIntent: CallbackAction<NextFocusIntent>(
              onInvoke: (_) => FocusScope.of(context).nextFocus()),
          PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
              onInvoke: (_) => FocusScope.of(context).previousFocus()),
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              if (_createFocus.hasFocus) _createProfile();
              if (_cancelFocus.hasFocus) Navigator.pop(context);
              if (_avatarFocus.hasFocus) _selectAvatar();
              if (_ageFocus.hasFocus && _selectedType == 'child') _selectAge();
              return null;
            },
          ),
        },
        child: FocusScope(
          child: Scaffold(
            appBar: SimpleAppBar(
              logoPath: theme.brightness == Brightness.dark
                  ? 'assets/images/logo_dark.png'
                  : 'assets/images/logo_light.png',
              onLanguagePressed: () {
                context.read<LocaleProvider>().toggleLocale();
              },
              languageFocusNode: _languageFocus,
            ),
            body: Stack(
              children: [
                // Arrière-plan avec dégradé
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: theme.brightness == Brightness.dark
                          ? [const Color(0xFF121212), Colors.black]
                          : [Colors.grey[100]!, Colors.grey[300]!],
                    ),
                  ),
                ),

                // Contenu principal
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      Text(
                        loc?.creerProfil ?? 'Créer un nouveau profil',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Information sur le profil principal
                      if (hasMainProfile) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Pays importé depuis le profil principal: ${_getCountryName(_mainProfileData?['country'] ?? 'Non spécifié')}',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // Sélection d'avatar
                              _buildAvatarSelector(theme, deviceInfo),
                              const SizedBox(height: 24),

                              // Champ nom
                              _buildNameField(theme, deviceInfo, loc),
                              const SizedBox(height: 20),

                              // Champ téléphone
                              _buildPhoneField(theme, deviceInfo, loc),
                              const SizedBox(height: 20),

                              // Sélecteur de type de profil
                              _buildTypeSelector(theme, deviceInfo, loc, hasMainProfile),
                              const SizedBox(height: 16),

                              // Sélecteur d'âge (uniquement pour les enfants)
                              if (_selectedType == 'child') ...[
                                _buildAgeSelector(theme, deviceInfo),
                                const SizedBox(height: 16),
                              ],

                              // Description du type sélectionné
                              _buildTypeDescription(loc),
                              const SizedBox(height: 32),

                              // Boutons d'action
                              _buildActionButtons(theme, deviceInfo, loc),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Clavier virtuel pour TV
                if (_showVirtualKeyboard && _focusedController != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: TvVirtualKeyboard(
                      selectedLanguage: 'fr',
                      onTextInput: (text) {
                        if (_focusedController != null) {
                          _focusedController!.text += text;
                        }
                      },
                      onBackspace: () {
                        if (_focusedController != null && 
                            _focusedController!.text.isNotEmpty) {
                          _focusedController!.text = _focusedController!.text
                              .substring(0, _focusedController!.text.length - 1);
                        }
                      },
                      onEnter: _createProfile,
                      focusNode: _nameFocus,
                    ),
                  ),

                // Overlay de chargement
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(AppTheme.primaryOrange),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Création du profil...',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
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

  String _getCountryName(String countryCode) {
    // Nettoyer le code pays (enlever le préfixe de l'enum si présent)
    final cleanCode = countryCode.replaceAll('ProfileCreateCountryEnum.', '');
    
    final countryMap = {
      'FR': 'France',
      'US': 'États-Unis',
      'GB': 'Royaume-Uni',
      'DE': 'Allemagne',
      'ES': 'Espagne',
      'IT': 'Italie',
      'CA': 'Canada',
      'BE': 'Belgique',
      'CH': 'Suisse',
    };
    return countryMap[cleanCode] ?? cleanCode;
  }

  Widget _buildAvatarSelector(ThemeData theme, DeviceInfoProvider deviceInfo) {
    return Column(
      children: [
        Text(
          'Avatar du profil',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Focus(
          focusNode: _avatarFocus,
          child: GestureDetector(
            onTap: _selectAvatar,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _avatarFocus.hasFocus ? AppTheme.primaryOrange : theme.colorScheme.outline,
                  width: _avatarFocus.hasFocus ? 3 : 2,
                ),
                boxShadow: _avatarFocus.hasFocus
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryOrange.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: ClipOval(
                child: _selectedAvatar != null
                    ? Image.network(
                        _selectedAvatar!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(AppTheme.primaryOrange),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar(theme);
                        },
                      )
                    : _buildDefaultAvatar(theme),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Appuyez pour choisir un avatar',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      child: Icon(
        _selectedType == 'child' ? Icons.child_care : Icons.person,
        size: 50,
        color: theme.colorScheme.onSurface.withOpacity(0.5),
      ),
    );
  }

  Widget _buildNameField(ThemeData theme, DeviceInfoProvider deviceInfo, AppLocalizations? loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc?.nomProfil ?? 'Nom du profil *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          focusNode: _nameFocus,
          child: deviceInfo.isTV
              ? _buildTVNameField(theme)
              : TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: loc?.nomProfil ?? 'Entrez le nom du profil',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.primaryOrange, width: 2),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTVNameField(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        border: Border.all(
          color: _nameFocus.hasFocus ? AppTheme.primaryOrange : theme.colorScheme.outline,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _nameController.text.isEmpty
            ? 'Nom du profil'
            : _nameController.text,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildPhoneField(ThemeData theme, DeviceInfoProvider deviceInfo, AppLocalizations? loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Téléphone',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          focusNode: _phoneFocus,
          child: deviceInfo.isTV
              ? _buildTVPhoneField(theme)
              : TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Optionnel',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.primaryOrange, width: 2),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTVPhoneField(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        border: Border.all(
          color: _phoneFocus.hasFocus ? AppTheme.primaryOrange : theme.colorScheme.outline,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _phoneController.text.isEmpty
            ? 'Téléphone (optionnel)'
            : _phoneController.text,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildTypeSelector(ThemeData theme, DeviceInfoProvider deviceInfo, 
                           AppLocalizations? loc, bool hasMainProfile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc?.typeProfil ?? 'Type de profil *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          focusNode: _typeFocus,
          child: Container(
            decoration: BoxDecoration(
              color: deviceInfo.isTV && _typeFocus.hasFocus
                  ? theme.colorScheme.surfaceVariant.withOpacity(0.6)
                  : theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: deviceInfo.isTV && _typeFocus.hasFocus
                    ? AppTheme.primaryOrange
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                value: _selectedType,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                      // Réinitialiser l'âge si on passe à autre chose qu'enfant
                      if (value != 'child') {
                        _selectedAge = null;
                      }
                    });
                  }
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
                items: [
                  if (!hasMainProfile)
                    DropdownMenuItem(
                      value: 'main',
                      child: Text(loc?.profilPrincipal ?? 'Profil principal'),
                    ),
                  DropdownMenuItem(
                    value: 'child',
                    child: Text(loc?.profilEnfant ?? 'Profil enfant'),
                  ),
                  DropdownMenuItem(
                    value: 'guest',
                    child: Text(loc?.profilInvite ?? 'Profil invité'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeSelector(ThemeData theme, DeviceInfoProvider deviceInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Âge *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          focusNode: _ageFocus,
          child: GestureDetector(
            onTap: _selectAge,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                border: Border.all(
                  color: _ageFocus.hasFocus ? AppTheme.primaryOrange : theme.colorScheme.outline,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedAge != null ? '$_selectedAge ans' : 'Sélectionner l\'âge',
                    style: TextStyle(
                      color: _selectedAge != null 
                          ? theme.colorScheme.onSurface 
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: theme.colorScheme.onSurface,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeDescription(AppLocalizations? loc) {
    String description = '';
    Color color = Colors.grey;

    switch (_selectedType) {
      case 'main':
        description = loc?.descriptionProfilPrincipal ?? 'Accès complet à tous les contenus';
        color = Colors.blue;
        break;
      case 'child':
        description = loc?.descriptionProfilEnfant ?? 'Contenu adapté aux enfants avec restrictions d\'âge';
        color = Colors.green;
        break;
      case 'guest':
        description = loc?.descriptionProfilInvite ?? 'Accès limité temporaire avec restrictions de contenu';
        color = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: color,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, DeviceInfoProvider deviceInfo, AppLocalizations? loc) {
    return Row(
      children: [
        Expanded(
          child: Focus(
            focusNode: _createFocus,
            child: deviceInfo.isTV
                ? ElevatedButton(
                    onPressed: _isLoading ? null : _createProfile,
                    style: AppDecorations.tvButtonStyle(isFocused: _createFocus.hasFocus),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(loc?.creer ?? 'Créer le profil'),
                  )
                : ElevatedButton(
                    onPressed: _isLoading ? null : _createProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(loc?.creer ?? 'Créer le profil'),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Focus(
            focusNode: _cancelFocus,
            child: deviceInfo.isTV
                ? OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: AppDecorations.tvOutlinedButtonStyle(isFocused: _cancelFocus.hasFocus),
                    child: Text(loc?.annuler ?? 'Annuler'),
                  )
                : OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      side: BorderSide(color: theme.colorScheme.outline),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(loc?.annuler ?? 'Annuler'),
                  ),
          ),
        ),
      ],
    );
  }
}