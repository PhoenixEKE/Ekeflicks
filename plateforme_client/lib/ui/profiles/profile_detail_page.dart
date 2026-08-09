// lib/ui/profiles/profile_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import 'package:app_ekeflicks/widgets/app_bars/simple_app_bar.dart';
import 'package:app_ekeflicks/widgets/keyboards/tv_virtual_keyboard.dart';
import 'package:app_ekeflicks/widgets/dialog/avatar_selector_dialog.dart';
import 'package:app_ekeflicks/widgets/dialog/age_selector_dialog.dart';
import 'package:app_ekeflicks/providers/device_info_provider.dart';
import 'package:app_ekeflicks/providers/locale_provider.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';
import 'package:app_ekeflicks/providers/profile_provider.dart';
import 'package:app_ekeflicks/providers/avatar_provider.dart';
import 'package:app_ekeflicks/src/models/profile.dart';
import 'package:app_ekeflicks/core/api_config.dart';
import 'package:app_ekeflicks/utils/phone_number.dart';
import 'package:app_ekeflicks/services/profile_access_service.dart';

class ProfileDetailPage extends StatefulWidget {
  final Profile profile;

  const ProfileDetailPage({super.key, required this.profile});

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> with SingleTickerProviderStateMixin {
  late Profile _editingProfile;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  bool _showVirtualKeyboard = false;
  bool _avatarHovered = false;
  TextEditingController? _focusedController;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Focus nodes
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _ageFocus = FocusNode();
  final FocusNode _saveFocus = FocusNode();
  final FocusNode _cancelFocus = FocusNode();
  final FocusNode _editFocus = FocusNode();
  final FocusNode _avatarFocus = FocusNode();
  final FocusNode _keyboardFocus = FocusNode();
  final FocusNode _languageFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _editingProfile = widget.profile;
    _nameController.text = widget.profile.name;
    _phoneController.text = widget.profile.phone ?? '';

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();

    _nameFocus.addListener(() => _onFieldFocus(_nameController));
    _phoneFocus.addListener(() => _onFieldFocus(_phoneController));

    // Debug des données du profil
    _debugProfileData();
  }

  void _debugProfileData() {
    debugPrint('🔍 DONNÉES DU PROFIL:');
    debugPrint('🔍 ID: ${_editingProfile.id}');
    debugPrint('🔍 Nom: ${_editingProfile.name}');
    debugPrint('🔍 Avatar: ${_editingProfile.avatar}');
    debugPrint('🔍 AvatarUrl: ${_editingProfile.avatarUrl}');
    debugPrint('🔍 Type: ${_editingProfile.type}');
  }

  void _onFieldFocus(TextEditingController controller) {
    if (!mounted) return;
    final deviceInfo = context.read<DeviceInfoProvider>();
    if (!_isEditing || !deviceInfo.isTV) return;
    setState(() {
      _focusedController = controller;
      _showVirtualKeyboard = true;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _ageFocus.dispose();
    _saveFocus.dispose();
    _cancelFocus.dispose();
    _editFocus.dispose();
    _avatarFocus.dispose();
    _keyboardFocus.dispose();
    _languageFocus.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _nameController.text = widget.profile.name;
        _phoneController.text = widget.profile.phone ?? '';
        _nameFocus.unfocus();
        _phoneFocus.unfocus();
        _showVirtualKeyboard = false;
      } else {
        _animationController.forward(from: 0.0);
      }
    });
  }

  Future<void> _saveChanges() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    final userProvider = context.read<UserProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final apiClient = userProvider.apiClient;

    final token = userProvider.accessToken;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Token d\'authentification manquant'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      // Demander le PIN parental pour les profils enfants
      String? parentalPin;
      if (_editingProfile.type?.name == 'child') {
        parentalPin = await ProfileAccessService.askForParentalPin(
          context,
          title: 'Autoriser la modification du profil enfant',
        );
        if (parentalPin == null || parentalPin.isEmpty) return;
      }

      await apiClient.dio.patch<Object>(
        '/profiles/${_editingProfile.id}/',
        data: {
          'name': _nameController.text.trim(),
          'phone': normalizeInternationalPhone(_phoneController.text),
          if (_editingProfile.country != null)
            'country_code': _editingProfile.country!.name,
          'age': _editingProfile.age,
          if (parentalPin != null) 'parental_pin': parentalPin,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (!mounted) return;

      await profileProvider.loadProfiles();

      final updatedProfiles = profileProvider.availableProfiles;
      final updatedProfileData = updatedProfiles.firstWhere((p) => p.id == _editingProfile.id);
      setState(() {
        _isEditing = false;
        _editingProfile = updatedProfileData;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Profil mis à jour avec succès'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
    } on DioException catch (dioError) {
      if (!mounted) return;
      _handleApiError(dioError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateForm() {
    if (_nameController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ Le nom est obligatoire'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
    final phoneError = validateInternationalPhone(_phoneController.text);
    if (phoneError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ $phoneError'), backgroundColor: Colors.orange),
      );
      return false;
    }
    return true;
  }

  void _handleApiError(DioException dioError) {
    String message = 'Erreur inattendue';
    if (dioError.response?.data != null && dioError.response!.data is Map<String, dynamic>) {
      final data = dioError.response!.data as Map<String, dynamic>;
      message = data['detail'] ?? data['message'] ?? message;
      if (data.containsKey('name')) message = data['name'][0] ?? message;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $message'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _changeAvatar() async {
    debugPrint('🔴 Début de _changeAvatar');
    debugPrint('🔴 Avatar actuel: ${_editingProfile.avatarUrl ?? _editingProfile.avatar}');

    final userProvider = context.read<UserProvider>();
    final avatarProvider = context.read<AvatarProvider>();

    if (avatarProvider.avatars.isEmpty && !avatarProvider.isLoading) {
      await avatarProvider.loadAvatars(userProvider.apiClient);
    }

    if (!mounted) return;

    if (avatarProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur chargement avatars: ${avatarProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Stocker la sélection actuelle pour la comparer après
    final previousAvatar = _editingProfile.avatarUrl ?? _editingProfile.avatar;

    final selectedAvatar = await showDialog<String>(
      context: context,
      builder: (ctx) => AvatarSelectorDialog(
        onAvatarSelected: (avatarUrl) => Navigator.of(ctx).pop(avatarUrl),
        selectedAvatar: previousAvatar,
      ),
    );

    debugPrint('🔴 Retour du dialogue, avatar sélectionné: $selectedAvatar');
    debugPrint('🔴 Ancien avatar: $previousAvatar');
    debugPrint('🔴 Nouveau avatar différent: ${selectedAvatar != previousAvatar}');

    // Vérifier si un avatar a été sélectionné et s'il est différent
    if (selectedAvatar != null && selectedAvatar != previousAvatar && mounted) {
      await _updateAvatar(selectedAvatar);
    } else if (selectedAvatar != null && selectedAvatar == previousAvatar && mounted) {
      // Même avatar sélectionné, pas besoin de mise à jour
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Avatar déjà sélectionné'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateAvatar(String avatarUrl) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    final userProvider = context.read<UserProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final apiClient = userProvider.apiClient;

    final token = userProvider.accessToken;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Token d\'authentification manquant'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      // Demander le PIN parental pour les profils enfants
      String? parentalPin;
      if (_editingProfile.type?.name == 'child') {
        parentalPin = await ProfileAccessService.askForParentalPin(
          context,
          title: 'Autoriser la modification de l\'avatar enfant',
        );
        if (parentalPin == null || parentalPin.isEmpty) return;
      }

      await apiClient.dio.patch<Object>(
        '/profiles/${_editingProfile.id}/',
        data: {
          'avatar_url': avatarUrl,
          if (parentalPin != null) 'parental_pin': parentalPin,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (!mounted) return;

      // Recharger les profils depuis l'API
      await profileProvider.loadProfiles();

      // Mettre à jour l'état local avec les nouvelles données
      final updatedProfiles = profileProvider.availableProfiles;
      final updatedProfileData = updatedProfiles.firstWhere(
        (p) => p.id == _editingProfile.id,
        orElse: () => _editingProfile,
      );

      setState(() {
        _editingProfile = updatedProfileData;
        _debugProfileData(); // Debug après mise à jour
      });

      // Afficher le message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Avatar modifié avec succès'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

    } on DioException catch (dioError) {
      if (!mounted) return;

      // Gestion spécifique des erreurs Dio
      String errorMessage = 'Erreur lors de la mise à jour';
      if (dioError.response?.data != null && dioError.response!.data is Map<String, dynamic>) {
        final errorData = dioError.response!.data as Map<String, dynamic>;
        errorMessage = errorData['detail'] ?? errorData['message'] ?? errorMessage;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur inattendue: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _changeAge() async {
    final selectedAge = await showDialog<int>(
      context: context,
      builder: (ctx) => AgeSelectorDialog(
        currentAge: _editingProfile.age,
        profileType: _editingProfile.type,
      ),
    );

    if (selectedAge != null && mounted) {
      await _updateAge(selectedAge);
    }
  }

  Future<void> _updateAge(int age) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final userProvider = context.read<UserProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final apiClient = userProvider.apiClient;

    final token = userProvider.accessToken;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Token d\'authentification manquant'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      // Demander le PIN parental pour les profils enfants
      String? parentalPin;
      if (_editingProfile.type?.name == 'child') {
        parentalPin = await ProfileAccessService.askForParentalPin(
          context,
          title: 'Autoriser la modification de l\'âge',
        );
        if (parentalPin == null || parentalPin.isEmpty) return;
      }

      await apiClient.dio.patch<Object>(
        '/profiles/${_editingProfile.id}/',
        data: {
          'age': age,
          if (parentalPin != null) 'parental_pin': parentalPin,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (!mounted) return;

      await profileProvider.loadProfiles();

      final updatedProfiles = profileProvider.availableProfiles;
      final updatedProfileData = updatedProfiles.firstWhere((p) => p.id == _editingProfile.id);
      setState(() => _editingProfile = updatedProfileData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Âge modifié avec succès'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      );
    } on DioException catch (dioError) {
      if (!mounted) return;
      _handleApiError(dioError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isChildProfile => _editingProfile.type?.toString().contains('child') ?? false;

  Color _getProfileColor() {
    final type = _editingProfile.type?.toString().split('.').last.toLowerCase() ?? '';
    switch (type) {
      case 'main':
        return const Color(0xFFFF6B6B);
      case 'child':
        return const Color(0xFF4ECDC4);
      case 'guest':
        return const Color(0xFF45B7D1);
      default:
        return const Color(0xFFF9A826);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceInfo = context.read<DeviceInfoProvider>();
    final isTV = deviceInfo.isTV;
    final profileColor = _getProfileColor();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Scaffold(
              appBar: SimpleAppBar(
                logoPath: theme.brightness == Brightness.dark
                    ? 'assets/images/logo_dark.png'
                    : 'assets/images/logo_light.png',
                onLanguagePressed: () => context.read<LocaleProvider>().toggleLocale(),
                languageFocusNode: _languageFocus,
              ),
              body: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.2,
                        colors: [
                          profileColor.withOpacity(0.05),
                          theme.colorScheme.background,
                        ],
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            _buildProfileHeader(theme, isTV, profileColor),
                            const SizedBox(height: 40),
                            _buildProfileCard(theme, isTV, profileColor),
                            const SizedBox(height: 32),
                            _buildActionButtons(isTV, profileColor),
                            if (_showVirtualKeyboard && _focusedController != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 24),
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
                                  onEnter: () => setState(() => _showVirtualKeyboard = false),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.4),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(profileColor),
                              strokeWidth: 4,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Mise à jour...',
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
        );
      },
    );
  }

  Widget _buildProfileHeader(ThemeData theme, bool isTV, Color profileColor) {
    return Column(
      children: [
        Focus(
          focusNode: _avatarFocus,
          canRequestFocus: _isEditing,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: _avatarFocus.hasFocus ? const EdgeInsets.all(8) : EdgeInsets.zero,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _avatarFocus.hasFocus
                  ? RadialGradient(
                      colors: [profileColor.withOpacity(0.3), Colors.transparent],
                    )
                  : null,
            ),
            child: MouseRegion(
              cursor: _isEditing ? SystemMouseCursors.click : MouseCursor.defer,
              onEnter: _isEditing ? (_) => setState(() => _avatarHovered = true) : null,
              onExit: (_) => setState(() => _avatarHovered = false),
              child: AnimatedScale(
                scale: _avatarHovered ? 1.08 : 1,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: GestureDetector(
                  onTap: _isEditing ? _changeAvatar : null,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: isTV ? 140 : 120,
                        height: isTV ? 140 : 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: profileColor, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: profileColor.withOpacity(0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _getAvatarImage(profileColor),
                        ),
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: profileColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.edit,
                              size: isTV ? 20 : 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Positioned(
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: profileColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getProfileTypeLabel(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _editingProfile.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        if (_editingProfile.phone != null && _editingProfile.phone!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _editingProfile.phone!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
        if (_isChildProfile && _editingProfile.age != null) ...[
          const SizedBox(height: 8),
          Text(
            '${_editingProfile.age} ans',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _getAvatarImage(Color profileColor) {
    // Priorité à avatarUrl, puis avatar
    String? imageUrl;

    if (_editingProfile.avatarUrl != null && _editingProfile.avatarUrl!.isNotEmpty) {
      imageUrl = _editingProfile.avatarUrl;
      debugPrint('🖼️ Utilisation avatarUrl: $imageUrl');
    } else if (_editingProfile.avatar != null && _editingProfile.avatar!.isNotEmpty) {
      // Si avatar est une URL complète, l'utiliser directement
      if (_editingProfile.avatar!.startsWith('http')) {
        imageUrl = _editingProfile.avatar;
        debugPrint('🖼️ Utilisation avatar (URL complète): $imageUrl');
      } else {
        // Si avatar est un nom de fichier, construire l'URL complète via ApiConfig
        imageUrl = ApiConfig.cdnEndpoint('avatars', _editingProfile.avatar!).toString();
        debugPrint('🖼️ Construction URL depuis nom de fichier: $imageUrl');
      }
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: profileColor.withOpacity(0.1),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(profileColor),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Erreur chargement image: $error');
          debugPrint('❌ URL: $imageUrl');
          return _buildDefaultAvatar(profileColor);
        },
      );
    }

    return _buildDefaultAvatar(profileColor);
  }

  Widget _buildDefaultAvatar(Color profileColor) {
    final assetPath = _editingProfile.type?.name == 'child'
        ? 'assets/avatars/child.png'
        : 'assets/avatars/adult.png';
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: profileColor.withOpacity(0.1),
        child: Icon(
          Icons.person,
          size: 50,
          color: profileColor.withOpacity(0.6),
        ),
      ),
    );
  }

  String _getProfileTypeLabel() {
    final type = _editingProfile.type?.toString().split('.').last.toLowerCase() ?? '';
    switch (type) {
      case 'main':
        return 'Principal';
      case 'child':
        return 'Enfant';
      case 'guest':
        return 'Invité';
      default:
        return '';
    }
  }

  Widget _buildProfileCard(ThemeData theme, bool isTV, Color profileColor) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildTextField('Nom', _nameController, _nameFocus, profileColor),
            const SizedBox(height: 16),
            _buildTextField('Téléphone avec indicatif (+225…)', _phoneController, _phoneFocus, profileColor,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            if (_isChildProfile)
              _buildAgeSelector(profileColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, FocusNode focusNode,
      Color profileColor,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: _isEditing,
      keyboardType: keyboardType,
      style: TextStyle(color: profileColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: profileColor.withOpacity(0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: profileColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildAgeSelector(Color profileColor) {
    return GestureDetector(
      onTap: _isEditing ? _changeAge : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: profileColor, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _editingProfile.age != null ? '${_editingProfile.age} ans' : 'Sélectionner l\'âge',
              style: TextStyle(color: profileColor),
            ),
            Icon(Icons.cake, color: profileColor),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isTV, Color profileColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isEditing)
          ElevatedButton(
            onPressed: _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: profileColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Enregistrer'),
          )
        else
          ElevatedButton(
            onPressed: _toggleEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: profileColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Modifier'),
          ),
        const SizedBox(width: 16),
        if (_isEditing)
          OutlinedButton(
            onPressed: _toggleEdit,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: profileColor, width: 2),
            ),
            child: Text('Annuler', style: TextStyle(color: profileColor)),
          ),
      ],
    );
  }
}
