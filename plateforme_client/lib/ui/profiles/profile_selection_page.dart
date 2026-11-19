import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:app_ekeflicks/providers/profile_provider.dart';
import 'package:app_ekeflicks/providers/device_info_provider.dart';
import 'package:app_ekeflicks/providers/locale_provider.dart';
import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/ui/users/post_login_page.dart';
import 'package:app_ekeflicks/ui/profiles/profile_detail_page.dart';
import 'package:app_ekeflicks/ui/profiles/create_profile_page.dart';
import 'package:app_ekeflicks/services/profile_access_service.dart';

// OpenAPI models
import 'package:app_ekeflicks/src/models/profile.dart';

class ProfileSelectionPage extends StatefulWidget {
  const ProfileSelectionPage({super.key});

  @override
  State<ProfileSelectionPage> createState() => _ProfileSelectionPageState();
}

class _ProfileSelectionPageState extends State<ProfileSelectionPage>
    with SingleTickerProviderStateMixin {
  List<FocusNode> _profileFocusNodes = [];
  final FocusNode _addProfileFocusNode = FocusNode();
  final FocusNode _languageFocusNode = FocusNode();
  int _currentIndex = -1;
  final ScrollController _scrollController = ScrollController();
  bool _isDesktop = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final Map<int, bool> _hoverStates = {};

  @override
  void initState() {
    super.initState();
    _isDesktop = _checkIfDesktop();

    // Initialisation des animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadProfiles();
      _initializeFocusNodes();
    });
  }

  bool _checkIfDesktop() {
    if (kIsWeb) return true;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  Future<void> _loadProfiles() async {
    final provider = context.read<ProfileProvider>();
    if (provider.availableProfiles.isEmpty) {
      try {
        await provider.loadProfiles();
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des profils: $e'),
            action: SnackBarAction(
              label: 'Réessayer',
              onPressed: () => _loadProfiles(),
            ),
          ),
        );
      }
    }
  }

  void _initializeFocusNodes() {
    final profiles = context.read<ProfileProvider>().availableProfiles;
    _profileFocusNodes = List.generate(
      profiles.length,
      (index) => FocusNode(debugLabel: "Profile $index"),
    );

    final deviceInfo = context.read<DeviceInfoProvider>();
    if (deviceInfo.isTV) {
      for (var node in _profileFocusNodes) {
        node.skipTraversal = false;
      }
      _addProfileFocusNode.skipTraversal = false;
      _languageFocusNode.skipTraversal = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profiles = context.read<ProfileProvider>().availableProfiles;
    if (_profileFocusNodes.length != profiles.length) _initializeFocusNodes();
  }

  @override
  void dispose() {
    for (var node in _profileFocusNodes) {
      node.dispose();
    }
    _addProfileFocusNode.dispose();
    _languageFocusNode.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleProfileSelect(Profile profile) async {
    // Vérifier l'accès au profil (PIN parental si nécessaire)
    if (!await ProfileAccessService.canOpen(context, profile) || !mounted) {
      return;
    }

    context.read<ProfileProvider>().selectProfile(profile);
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const PostLoginPage(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _handleProfileEdit(Profile profile) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => ProfileDetailPage(profile: profile),
        transitionsBuilder: (_, animation, _, child) {
          return ScaleTransition(scale: animation, child: child);
        },
      ),
    ).then((_) => _initializeFocusNodes());
  }

  void _handleAddProfile() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const CreateProfilePage(),
        transitionsBuilder: (_, animation, _, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    ).then((_) {
      _initializeFocusNodes();
      setState(() {});
    });
  }

  // Nouvelle méthode pour supprimer un profil
  Future<void> _handleProfileDelete(Profile profile) async {
    final profileProvider = context.read<ProfileProvider>();
    final loc = AppLocalizations.of(context);

    // Vérifier le nombre de profils
    if (profileProvider.availableProfiles.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc?.impossibleSupprimerDernierProfil ??
                'Impossible de supprimer le dernier profil',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Demande de confirmation
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(loc?.supprimerProfil ?? 'Supprimer le profil'),
          content: Text(
            '${loc?.confirmerSuppressionProfil ?? 'Êtes-vous sûr de vouloir supprimer le profil'} "${profile.name}" ?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(loc?.annuler ?? 'Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                loc?.supprimer ?? 'Supprimer',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await profileProvider.deleteProfile(profile.id!);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${loc?.profilSupprime ?? 'Profil supprimé'} : ${profile.name}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Recharger les profils et mettre à jour l'interface
        await _loadProfiles();

        if (!mounted) return;

        _initializeFocusNodes();
        setState(() {});
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${loc?.erreurSuppressionProfil ?? 'Erreur lors de la suppression'} : $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleLanguageChange() {
    context.read<LocaleProvider>().toggleLocale();
  }

  void _handleBack() => Navigator.pop(context);

  Map<LogicalKeySet, Intent> _getPlatformShortcuts(BuildContext context) {
    final deviceInfo = context.read<DeviceInfoProvider>();
    final Map<LogicalKeySet, Intent> shortcuts = {
      LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
      LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
      LogicalKeySet(LogicalKeyboardKey.escape): const ActivateIntent(),
      LogicalKeySet(LogicalKeyboardKey.goBack): const ActivateIntent(),
    };

    if (deviceInfo.isTV || _isDesktop) {
      shortcuts.addAll({
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const NextFocusIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft):
            const PreviousFocusIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.arrowDown,
        ): const DirectionalFocusIntent(TraversalDirection.down),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const DirectionalFocusIntent(
          TraversalDirection.up,
        ),
      });
    }

    if (_isDesktop) {
      shortcuts.addAll({
        LogicalKeySet(LogicalKeyboardKey.tab): const NextFocusIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.tab):
            const PreviousFocusIntent(),
      });
    }

    return shortcuts;
  }

  Map<Type, Action<Intent>> _getPlatformActions() {
    return {
      NextFocusIntent: CallbackAction<NextFocusIntent>(
        onInvoke: (_) {
          final profiles = context.read<ProfileProvider>().availableProfiles;
          final total = profiles.length + 1;
          _currentIndex = (_currentIndex + 1) % total;

          if (_currentIndex < profiles.length) {
            FocusScope.of(
              context,
            ).requestFocus(_profileFocusNodes[_currentIndex]);
            _scrollToItem(_currentIndex);
          } else {
            FocusScope.of(context).requestFocus(_addProfileFocusNode);
            _scrollToEnd();
          }
          return null;
        },
      ),
      PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
        onInvoke: (_) {
          final profiles = context.read<ProfileProvider>().availableProfiles;
          final total = profiles.length + 1;
          _currentIndex = (_currentIndex - 1 + total) % total;

          if (_currentIndex < profiles.length) {
            FocusScope.of(
              context,
            ).requestFocus(_profileFocusNodes[_currentIndex]);
            _scrollToItem(_currentIndex);
          } else {
            FocusScope.of(context).requestFocus(_addProfileFocusNode);
            _scrollToEnd();
          }
          return null;
        },
      ),
      DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
        onInvoke: (intent) {
          final profiles = context.read<ProfileProvider>().availableProfiles;
          final crossAxisCount = _getCrossAxisCount(
            MediaQuery.of(context).size.width,
          );

          if (intent.direction == TraversalDirection.down) {
            if (_currentIndex + crossAxisCount < profiles.length) {
              _currentIndex += crossAxisCount;
              FocusScope.of(
                context,
              ).requestFocus(_profileFocusNodes[_currentIndex]);
              _scrollToItem(_currentIndex);
            }
          } else if (intent.direction == TraversalDirection.up) {
            if (_currentIndex - crossAxisCount >= 0) {
              _currentIndex -= crossAxisCount;
              FocusScope.of(
                context,
              ).requestFocus(_profileFocusNodes[_currentIndex]);
              _scrollToItem(_currentIndex);
            }
          }
          return null;
        },
      ),
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (_) {
          final profiles = context.read<ProfileProvider>().availableProfiles;

          for (int i = 0; i < _profileFocusNodes.length; i++) {
            if (_profileFocusNodes[i].hasFocus) {
              _handleProfileSelect(profiles[i]);
            }
          }
          if (_addProfileFocusNode.hasFocus) _handleAddProfile();
          if (_languageFocusNode.hasFocus) _handleLanguageChange();

          final keysPressed = HardwareKeyboard.instance.logicalKeysPressed;
          if (keysPressed.contains(LogicalKeyboardKey.escape) ||
              keysPressed.contains(LogicalKeyboardKey.goBack)) {
            _handleBack();
          }
          return null;
        },
      ),
    };
  }

  void _scrollToItem(int index) {
    final deviceInfo = context.read<DeviceInfoProvider>();
    if (!deviceInfo.isTV && !_isDesktop) return;

    final crossAxisCount = _getCrossAxisCount(
      MediaQuery.of(context).size.width,
    );
    final row = index ~/ crossAxisCount;
    const itemHeight = 220.0;
    final scrollPosition = row * itemHeight;

    _scrollController.animateTo(
      scrollPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToEnd() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  int _getCrossAxisCount(double width) {
    if (width > 1200) return 6;
    if (width > 900) return 5;
    if (width > 700) return 4;
    if (width > 500) return 3;
    if (width > 350) return 2;
    return 1;
  }

  double _getChildAspectRatio(double screenWidth) {
    if (screenWidth > 900) return 0.8;
    if (screenWidth > 600) return 0.75;
    if (screenWidth > 400) return 0.7;
    return 0.65;
  }

  // Fonction pour trier les profils par type
  List<Profile> _getSortedProfiles(List<Profile> profiles) {
    // Ordre de priorité: main -> child -> guest -> autres
    final order = {'main': 0, 'child': 1, 'guest': 2};

    return List.of(profiles)..sort((a, b) {
      // Convert enum to string for comparison
      final typeA = a.type?.toString().split('.').last.toLowerCase() ?? '';
      final typeB = b.type?.toString().split('.').last.toLowerCase() ?? '';

      final orderA = order[typeA] ?? 3;
      final orderB = order[typeB] ?? 3;
      return orderA.compareTo(orderB);
    });
  }

  // Fonction pour obtenir la couleur en fonction du type de profil
  Color _getProfileColor(Profile profile) {
    final type = profile.type?.toString().split('.').last.toLowerCase() ?? '';

    switch (type) {
      case 'main':
        return const Color(0xFFFF6B6B); // Rouge orangé
      case 'child':
        return const Color(0xFF4ECDC4); // Turquoise
      case 'guest':
        return const Color(0xFF45B7D1); // Bleu clair
      default:
        return const Color(0xFFF9A826); // Jaune orangé
    }
  }

  // Widget pour construire l'avatar avec gestion d'erreur
  Widget _buildProfileAvatar({
    required String? avatarUrl,
    required Color profileColor,
    required bool isSmallScreen,
    required bool isFocused,
    required bool isHovered,
    required Profile profile,
  }) {
    final resolvedAvatarUrl = avatarUrl ?? '';
    final hasRemoteAvatar =
        resolvedAvatarUrl.isNotEmpty &&
        !resolvedAvatarUrl.contains('/avatars/default-adult.png') &&
        !resolvedAvatarUrl.contains('/avatars/default-child.png');
    final defaultAvatar =
        profile.type?.name == 'child'
            ? 'assets/avatars/child.png'
            : 'assets/avatars/adult.png';

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: profileColor, width: 2),
        boxShadow:
            isFocused || isHovered
                ? [
                  BoxShadow(
                    color: profileColor.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
                : null,
      ),
      child: CircleAvatar(
        radius: isSmallScreen ? 30 : 40,
        backgroundColor: profileColor.withValues(alpha: 0.1),
        backgroundImage:
            hasRemoteAvatar
                ? NetworkImage(resolvedAvatarUrl)
                : AssetImage(defaultAvatar),
        onBackgroundImageError:
            hasRemoteAvatar
                ? (exception, stackTrace) {
                  debugPrint('Erreur de chargement de l\'avatar: $exception');
                }
                : null,
      ),
    );
  }

  Widget _profileCard({
    required Profile profile,
    required FocusNode focusNode,
    required bool isCurrent,
    required VoidCallback onSelect,
    required VoidCallback onEdit,
    required bool isTV,
    required bool isDesktop,
    required bool isSmallScreen,
    required double screenWidth,
    required int index,
  }) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final profileColor = _getProfileColor(profile);
    final isHovered = _hoverStates[index] ?? false;
    final profileProvider = context.read<ProfileProvider>();
    // Un seul canDelete pour vérifier si le profil peut être supprimé
    final canDelete =
        profileProvider.availableProfiles.length > 1 &&
        profile.name != 'Ajouter' &&
        profile.type?.toString().split('.').last.toLowerCase() != 'main';

    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select)) {
          onSelect();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hoverStates[index] = true),
        onExit: (_) => setState(() => _hoverStates[index] = false),
        child: AnimatedBuilder(
          animation: Listenable.merge([focusNode, _animationController]),
          builder: (context, child) {
            final isFocused = focusNode.hasFocus;
            final scale = isFocused || isHovered ? 1.05 : 1.0;

            return AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: Card(
                elevation:
                    isFocused
                        ? 16
                        : isCurrent
                        ? 8
                        : 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side:
                      isCurrent
                          ? BorderSide(color: AppTheme.primaryOrange, width: 3)
                          : BorderSide.none,
                ),
                color: theme.cardColor,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors:
                          isFocused || isHovered
                              ? [
                                profileColor.withValues(alpha: 0.2),
                                profileColor.withValues(alpha: 0.05),
                              ]
                              : [theme.cardColor, theme.cardColor],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Zone principale cliquable
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: Tooltip(
                            message: 'Sélectionner ${profile.name}',
                            child: InkWell(
                              onTap: onSelect,
                              onLongPress: isTV ? null : onEdit,
                              borderRadius: BorderRadius.circular(20),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildProfileAvatar(
                                      avatarUrl: profile.avatarUrl,
                                      profileColor: profileColor,
                                      isSmallScreen: isSmallScreen,
                                      isFocused: isFocused,
                                      isHovered: isHovered,
                                      profile: profile,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      profile.name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: isSmallScreen ? 14 : 16,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (isCurrent) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryOrange
                                              .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          loc?.actuel ?? 'Actuel',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: AppTheme.primaryOrange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Bouton de suppression si autorisé
                      if (canDelete)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Material(
                            color: Colors.transparent,
                            child: Tooltip(
                              message:
                                  loc?.supprimerProfil ?? 'Supprimer le profil',
                              child: IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  size: isSmallScreen ? 16 : 20,
                                  color: Colors.red.withValues(alpha: 0.7),
                                ),
                                onPressed: () => _handleProfileDelete(profile),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ),
                        ),
                      // Bouton d'édition
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.transparent,
                          child: Tooltip(
                            message:
                                loc?.modifierProfil ?? 'Modifier le profil',
                            child: IconButton(
                              icon: Icon(
                                Icons.edit,
                                size: isSmallScreen ? 16 : 20,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              onPressed: onEdit,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _addProfileCard({
    required FocusNode focusNode,
    required VoidCallback onAdd,
    required bool isTV,
    required bool isDesktop,
    required bool isSmallScreen,
    required double screenWidth,
  }) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final isHovered = _hoverStates[-1] ?? false;
    final profileProvider = context.read<ProfileProvider>();
    final isDisabled = profileProvider.availableProfiles.length >= 4;

    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select)) {
          if (!isDisabled) onAdd();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor:
            isDisabled
                ? SystemMouseCursors.forbidden
                : SystemMouseCursors.click,
        onEnter: (_) {
          if (!isDisabled) {
            setState(() => _hoverStates[-1] = true);
          }
        },
        onExit: (_) => setState(() => _hoverStates[-1] = false),
        child: AnimatedBuilder(
          animation: Listenable.merge([focusNode, _animationController]),
          builder: (context, child) {
            final isFocused = focusNode.hasFocus;
            final scale = (isFocused || isHovered) && !isDisabled ? 1.05 : 1.0;

            return AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: Card(
                elevation: isFocused ? 16 : 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color:
                    isDisabled
                        ? Colors.grey.withValues(alpha: 0.3)
                        : theme.cardColor,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient:
                        isDisabled
                            ? null
                            : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors:
                                  isFocused || isHovered
                                      ? [
                                        const Color(
                                          0xFF6A11CB,
                                        ).withValues(alpha: 0.2),
                                        const Color(
                                          0xFF2575FC,
                                        ).withValues(alpha: 0.1),
                                      ]
                                      : [theme.cardColor, theme.cardColor],
                            ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Tooltip(
                      message:
                          isDisabled
                              ? loc?.maximumProfilsAtteint ??
                                  'Maximum de 4 profils atteint'
                              : loc?.ajouterProfil ?? 'Ajouter un profil',
                      child: InkWell(
                        onTap: isDisabled ? null : onAdd,
                        borderRadius: BorderRadius.circular(20),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      isDisabled
                                          ? Colors.grey.withValues(alpha: 0.3)
                                          : const Color(
                                            0xFF6A11CB,
                                          ).withValues(alpha: 0.1),
                                  border: Border.all(
                                    color:
                                        isDisabled
                                            ? Colors.grey
                                            : const Color(0xFF6A11CB),
                                    width: 2,
                                  ),
                                  boxShadow:
                                      (isFocused || isHovered) && !isDisabled
                                          ? [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF6A11CB,
                                              ).withValues(alpha: 0.4),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                          : null,
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: isSmallScreen ? 40 : 50,
                                  color:
                                      isDisabled
                                          ? Colors.grey
                                          : const Color(0xFF6A11CB),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                loc?.ajouterProfil ?? 'Ajouter un profil',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color:
                                      isDisabled
                                          ? Colors.grey
                                          : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.8),
                                  fontSize: isSmallScreen ? 14 : 16,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                              if (isDisabled) ...[
                                const SizedBox(height: 8),
                                Text(
                                  loc?.maximumProfils ?? '(Maximum 4 profils)',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceInfo = Provider.of<DeviceInfoProvider>(context);
    final profileProvider = context.watch<ProfileProvider>();
    final profiles = profileProvider.availableProfiles;
    final currentProfile = profileProvider.currentProfile;
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _getCrossAxisCount(screenWidth);
    final isSmallScreen = screenWidth < 400;

    // Afficher un indicateur de chargement si les profils ne sont pas encore chargés
    if (profiles.isEmpty && profileProvider.isLoading) {
      return Scaffold(
        body: Container(
          decoration: AppTheme.pageDecoration(context, useGradient: true),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  theme.brightness == Brightness.dark
                      ? 'assets/images/logo_dark.png'
                      : 'assets/images/logo_light.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 30),
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  'Chargement des profils...',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Tri des profils par type
    final sortedProfiles = _getSortedProfiles(profiles);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Shortcuts(
              shortcuts: _getPlatformShortcuts(context),
              child: Actions(
                actions: _getPlatformActions(),
                child: FocusScope(
                  child: Scaffold(
                    body: Container(
                      decoration: AppTheme.pageDecoration(
                        context,
                        useGradient: true,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final paddingValue =
                              deviceInfo.isTV
                                  ? 48.0
                                  : constraints.maxWidth > 700
                                  ? 32.0
                                  : constraints.maxWidth > 500
                                  ? 24.0
                                  : 16.0;
                          return Padding(
                            padding: EdgeInsets.all(paddingValue),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 40),

                                // Logo avec animation
                                ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: Image.asset(
                                    theme.brightness == Brightness.dark
                                        ? 'assets/images/logo_dark.png'
                                        : 'assets/images/logo_light.png',
                                    height: 80,
                                    fit: BoxFit.contain,
                                  ),
                                ),

                                const SizedBox(height: 30),
                                FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Text(
                                    loc?.quiRegarde.toUpperCase() ??
                                        'QUI REGARDE ?',
                                    style: theme.textTheme.headlineLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color:
                                              theme.brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                          fontSize:
                                              deviceInfo.isTV
                                                  ? 42
                                                  : (isSmallScreen ? 24 : 32),
                                          letterSpacing: 2.0,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 4.0,
                                              color:
                                                  theme.brightness ==
                                                          Brightness.dark
                                                      ? Colors.black.withValues(
                                                        alpha: 0.5,
                                                      )
                                                      : Colors.grey.withValues(
                                                        alpha: 0.5,
                                                      ),
                                              offset: const Offset(2.0, 2.0),
                                            ),
                                          ],
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                Expanded(
                                  child: GridView.builder(
                                    controller: _scrollController,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing:
                                              deviceInfo.isTV
                                                  ? 40
                                                  : (isSmallScreen ? 16 : 24),
                                          mainAxisSpacing:
                                              deviceInfo.isTV
                                                  ? 40
                                                  : (isSmallScreen ? 16 : 24),
                                          childAspectRatio:
                                              _getChildAspectRatio(screenWidth),
                                        ),
                                    itemCount: sortedProfiles.length + 1,
                                    itemBuilder: (context, index) {
                                      if (index < sortedProfiles.length) {
                                        final profile = sortedProfiles[index];
                                        final isCurrentProfile =
                                            currentProfile?.id == profile.id;
                                        return _profileCard(
                                          profile: profile,
                                          focusNode: _profileFocusNodes[index],
                                          isCurrent: isCurrentProfile,
                                          onSelect:
                                              () =>
                                                  _handleProfileSelect(profile),
                                          onEdit:
                                              () => _handleProfileEdit(profile),
                                          isTV: deviceInfo.isTV,
                                          isDesktop: _isDesktop,
                                          isSmallScreen: isSmallScreen,
                                          screenWidth: screenWidth,
                                          index: index,
                                        );
                                      } else {
                                        return _addProfileCard(
                                          focusNode: _addProfileFocusNode,
                                          onAdd: _handleAddProfile,
                                          isTV: deviceInfo.isTV,
                                          isDesktop: _isDesktop,
                                          isSmallScreen: isSmallScreen,
                                          screenWidth: screenWidth,
                                        );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
