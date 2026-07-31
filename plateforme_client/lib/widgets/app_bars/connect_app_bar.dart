import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/providers/theme_provider.dart';
import 'package:app_ekeflicks/providers/locale_provider.dart';
import 'package:app_ekeflicks/providers/profile_provider.dart';
import 'package:app_ekeflicks/providers/device_info_provider.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';
import 'package:app_ekeflicks/widgets/search/ia_search_delegate.dart';
import 'package:app_ekeflicks/ui/pages/genre_page.dart';
import 'package:app_ekeflicks/models/content_model.dart';
import 'package:app_ekeflicks/ui/users/profile_switcher.dart';
import 'package:app_ekeflicks/ui/users/account_page.dart';
import 'package:app_ekeflicks/core/app_theme.dart';
import 'base_app_bar.dart';
import 'package:dio/dio.dart';
import 'package:app_ekeflicks/src/models/profile.dart' as api_profile;
import 'package:app_ekeflicks/ui/users/account_page.dart';

class ConnectAppBar extends BaseAppBar implements PreferredSizeWidget {
  final double scrollOffset;
  final double scrollThreshold;

  const ConnectAppBar({
    super.key,
    this.scrollOffset = 0.0,
    this.scrollThreshold = 100.0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // Configuration pour ProfileSwitcher
  ProfileConfig get _profileConfig => ProfileConfig(
        adultAvatars: [
          'assets/avatars/adult.png',
        ],
        childAvatars: [
          'assets/avatars/child.png',
        ],
        defaultAdultAvatar: 'assets/avatars/adult.png',
        defaultChildAvatar: 'assets/avatars/child.png',
        gridColumns: 4,
        gridSpacing: 12,
        gridChildAspectRatio: 0.75,
        profileTypes: {
          'main': 'Adult',
          'child': 'Child',
          'guest': 'Guest',
        },
      );

  bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;

  // 🔄 REMPLACÉ : Tutoriels → FAQ
  Widget buildFaqIcon(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(Icons.help_outline, color: theme.iconTheme.color),
      tooltip: loc.faq, // Assurez-vous d'ajouter cette clé dans vos fichiers ARB
      onPressed: () => Navigator.of(context).pushNamed('/faq'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceInfoProvider = Provider.of<DeviceInfoProvider>(context, listen: false);
    final bool isTV = deviceInfoProvider.isTV;
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final isMobileView = isMobile(context);

    final double opacity = _calculateOpacity();
    final Color backgroundColor = _calculateBackgroundColor(theme, opacity);
    final double elevation = _calculateElevation();
    final double titleOpacity = _calculateTitleOpacity();

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor,
      elevation: elevation,
      titleSpacing: isMobileView ? 4 : 12,
      title: AnimatedOpacity(
        opacity: titleOpacity,
        duration: const Duration(milliseconds: 200),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            buildLogo(context, height: 38),
            if (!isMobileView && !isTV) _buildDesktopMenu(context, loc, theme),
            _buildActionIcons(context, isMobileView, isTV, loc, theme),
          ],
        ),
      ),
    );
  }

  double _calculateOpacity() => (scrollOffset.clamp(0, scrollThreshold) / scrollThreshold);

  Color _calculateBackgroundColor(ThemeData theme, double opacity) =>
      Color.lerp(Colors.transparent, theme.appBarTheme.backgroundColor ?? AppTheme.primaryOrange, opacity)!;

  double _calculateElevation() => scrollOffset > 10 ? 4.0 : 0.0;

  double _calculateTitleOpacity() =>
      scrollOffset > scrollThreshold
          ? 1.0
          : scrollOffset > scrollThreshold - 20
              ? (scrollOffset - (scrollThreshold - 20)) / 20
              : 0.0;

  Widget _buildDesktopMenu(BuildContext context, AppLocalizations loc, ThemeData theme) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildMenuWithSubmenu(context, loc.films, ['Action', 'Comédie', 'Drame', 'Horreur', 'Science-fiction'], 'film-category'),
            const SizedBox(width: 16),
            _buildMenuWithSubmenu(context, loc.series, ['Crime', 'Science-fiction', 'Comédie', 'Drama', 'Animation'], 'series-category'),
            const SizedBox(width: 16),
            _buildMenuWithSubmenu(context, loc.plus, [loc.documentaires, loc.telerealites, loc.live, 'Sports', 'Kids'], 'plus-category'),
            const SizedBox(width: 16),
            _buildMenuWithSubmenu(context, loc.explorerParPays, ['France', 'USA', 'Japon', 'Corée', 'Inde'], 'country'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcons(BuildContext context, bool isMobile, bool isTV, AppLocalizations loc, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isMobile) _buildCustomSearchField(context, loc, isTV),
        if (!isMobile) const SizedBox(width: 8),
        if (isMobile) _buildMobileSearchIcon(context, theme, isTV),
        if (!isMobile && !isTV) buildFaqIcon(context, loc), // 🔄 REMPLACÉ : Tutoriels → FAQ
        if (!isTV) _buildNotificationIcon(context, theme, loc),
        if (isMobile && !isTV) _buildMobileMenu(context, loc),
        _buildProfileMenu(context, loc, theme, isTV),
        if (isTV) _buildTVSearchIcon(context, theme, loc),
      ],
    );
  }

  Widget _buildCustomSearchField(BuildContext context, AppLocalizations loc, bool isTV) {
    if (isTV) return IconButton(icon: Icon(Icons.search, size: 28), onPressed: () => _showSearch(context, true), tooltip: loc.search);

    return Container(
      width: 250,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: loc.search,
          hintStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.white70, size: 20),
          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        ),
        style: TextStyle(color: Colors.white, fontSize: 14),
        onTap: () => _showSearch(context, false),
      ),
    );
  }

  Widget _buildMobileSearchIcon(BuildContext context, ThemeData theme, bool isTV) =>
      IconButton(icon: Icon(Icons.search, color: theme.iconTheme.color, size: isTV ? 32 : 24), onPressed: () => _showSearch(context, isTV));

  Widget _buildTVSearchIcon(BuildContext context, ThemeData theme, AppLocalizations loc) =>
      IconButton(icon: Icon(Icons.search, color: theme.iconTheme.color, size: 32), tooltip: loc.search, onPressed: () => _showSearch(context, true));

  void _showSearch(BuildContext context, bool isTV) {
    showSearch(context: context, delegate: IASearchDelegate(isTV: isTV));
  }

  Widget _buildNotificationIcon(BuildContext context, ThemeData theme, AppLocalizations loc) {
    return IconButton(
      icon: Icon(Icons.notifications_none, color: theme.iconTheme.color),
      tooltip: loc.notifications,
      onPressed: () => _handleNotificationPress(context),
    );
  }

  Widget _buildProfileMenu(BuildContext context, AppLocalizations loc, ThemeData theme, bool isTV) {
    return Consumer<ProfileProvider>(
      builder: (BuildContext context, ProfileProvider profileProvider, Widget? _) {
        final currentProfile = profileProvider.currentProfile;
        final isMobileView = isMobile(context);

        return PopupMenuButton<String>(
          tooltip: loc.compte,
          iconSize: isTV ? 48 : 38,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadius)),
          itemBuilder: (BuildContext context) {
            final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
            final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
            return [
              PopupMenuItem<String>(
                value: 'changerProfil',
                child: Row(
                  children: [
                    Icon(Icons.switch_account, color: theme.iconTheme.color, size: isTV ? 28 : 24),
                    const SizedBox(width: 10),
                    Text(loc.changerProfil, style: isTV ? theme.textTheme.titleMedium : null),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'compte',
                child: Row(
                  children: [
                    Icon(Icons.account_circle, color: theme.iconTheme.color, size: isTV ? 28 : 24),
                    const SizedBox(width: 10),
                    Text(loc.compte, style: isTV ? theme.textTheme.titleMedium : null),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'changerTheme',
                child: Row(
                  children: [
                    Icon(themeProvider.isLightTheme ? Icons.dark_mode : Icons.light_mode, color: theme.iconTheme.color, size: isTV ? 28 : 24),
                    const SizedBox(width: 10),
                    Text(themeProvider.isLightTheme ? loc.darkMode : loc.lightMode, style: isTV ? theme.textTheme.titleMedium : null),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'changerLangue',
                child: Row(
                  children: [
                    Icon(Icons.language, color: theme.iconTheme.color, size: isTV ? 28 : 24),
                    const SizedBox(width: 10),
                    Text(loc.changerLangue, style: isTV ? theme.textTheme.titleMedium : null),
                  ],
                ),
              ),
              if (isMobileView && !isTV)
                PopupMenuItem<String>(
                  value: 'faq', // 🔄 REMPLACÉ : tutoriel → faq
                  child: Row(
                    children: [
                      Icon(Icons.help_outline, color: theme.iconTheme.color, size: isTV ? 28 : 24), // 🔄 Icône changée
                      const SizedBox(width: 10),
                      Text(loc.faq, style: isTV ? theme.textTheme.titleMedium : null), // 🔄 Texte changé
                    ],
                  ),
                ),
              PopupMenuItem<String>(
                value: 'deconnexion',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: theme.iconTheme.color, size: isTV ? 28 : 24),
                    const SizedBox(width: 10),
                    Text(loc.deconnexion, style: isTV ? theme.textTheme.titleMedium : null),
                  ],
                ),
              ),
            ];
          },
          onSelected: (String value) => _handleProfileMenuSelection(context, value),
          child: _buildProfileAvatar(currentProfile, isTV),
        );
      },
    );
  }

  Widget _buildProfileAvatar(api_profile.Profile? currentProfile, bool isTV) {
    // Si le profil a un avatar URL, l'utiliser
    if (currentProfile?.avatarUrl != null && currentProfile!.avatarUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(isTV ? AppTheme.tvBorderRadius : AppTheme.borderRadius),
        child: Image.network(
          currentProfile.avatarUrl!,
          width: isTV ? 48 : 38,
          height: isTV ? 48 : 38,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(currentProfile, isTV),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: isTV ? 48 : 38,
              height: isTV ? 48 : 38,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(isTV ? AppTheme.tvBorderRadius : AppTheme.borderRadius),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      );
    }
    
    // Sinon utiliser l'avatar par défaut selon le type de profil
    return _buildDefaultAvatar(currentProfile, isTV);
  }

  Widget _buildDefaultAvatar(api_profile.Profile? currentProfile, bool isTV) {
    final defaultAvatarPath = currentProfile?.type?.name == 'child' 
        ? 'assets/avatars/child.png' 
        : 'assets/avatars/adult.png';
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(isTV ? AppTheme.tvBorderRadius : AppTheme.borderRadius),
      child: Image.asset(
        defaultAvatarPath,
        width: isTV ? 48 : 38,
        height: isTV ? 48 : 38,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: isTV ? 48 : 38,
          height: isTV ? 48 : 38,
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange,
            borderRadius: BorderRadius.circular(isTV ? AppTheme.tvBorderRadius : AppTheme.borderRadius),
          ),
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: isTV ? 32 : 24,
          ),
        ),
      ),
    );
  }

  void _handleProfileMenuSelection(BuildContext context, String value) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;

    switch (value) {
      case 'faq': // 🔄 REMPLACÉ : tutoriel → faq
        Navigator.of(context).pushNamed('/faq'); // 🔄 Route changée
        break;
      case 'changerProfil':
        _showProfileSwitcher(context);
        break;
      case 'compte':
        if (profileProvider.currentProfile != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AccountPage(currentProfile: profileProvider.currentProfile!)));
        }
        break;
      case 'changerTheme':
        Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
        break;
      case 'changerLangue':
        Provider.of<LocaleProvider>(context, listen: false).toggleLocale();
        break;
      case 'deconnexion':
        _confirmLogout(context);
        break;
    }
  }

  void _showProfileSwitcher(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final deviceInfoProvider = Provider.of<DeviceInfoProvider>(context, listen: false);
    final bool isTV = deviceInfoProvider.isTV;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadius)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTV ? 600 : 400, maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: ProfileSwitcher(
            profiles: profileProvider.availableProfiles,
            onProfileSelected: (api_profile.Profile profile) {
              profileProvider.selectProfile(profile);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${loc.profileChangedTo} ${profile.name}'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppTheme.primaryOrange,
                ),
              );
            },
            config: _profileConfig,
          ),
        ),
      ),
    );
  }

  void _handleNotificationPress(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.notificationsNonImpl), backgroundColor: AppTheme.primaryOrange),
    );
  }

  Widget _buildMenuWithSubmenu(BuildContext context, String label, List<String> subItems, String type) {
    final theme = Theme.of(context);
    final deviceInfoProvider = Provider.of<DeviceInfoProvider>(context, listen: false);
    final bool isTV = deviceInfoProvider.isTV;

    return _HoverMenuWrapper(
      child: PopupMenuButton<String>(
        tooltip: label,
        child: Text(label, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface, fontSize: isTV ? 20 : null)),
        onSelected: (value) => _navigateToGenrePage(context, value),
        itemBuilder: (context) => subItems.map((sub) => PopupMenuItem<String>(value: sub, child: Text(sub, style: isTV ? theme.textTheme.titleMedium : null))).toList(),
      ),
    );
  }

  void _navigateToGenrePage(BuildContext context, String genre) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => GenrePage(genre: genre, contents: _getContentsForGenre(genre))));
  }

  List<Content> _getContentsForGenre(String genre) {
    return List.generate(10, (index) {
      double rating = (3.5 + index * 0.2).clamp(0.0, 5.0);
      return Content(
        id: 'genre_${genre}_$index',
        title: '$genre Movie $index',
        description: 'A great $genre movie',
        imageUrl: 'https://picsum.photos/200/300?random=$genre$index',
        posterUrl: 'https://picsum.photos/200/300?random=$genre$index',
        videoUrl: 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4',
        type: ContentType.movie,
        genres: [genre],
        releaseYear: '202${index % 3}',
        duration: Duration(minutes: 90 + index * 5),
        rating: double.parse(rating.toStringAsFixed(1)),
      );
    });
  }

  void _confirmLogout(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isLoading = false;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: theme.dialogBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadius)),
              title: Text(
                loc.deconnexion,
                style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurface),
              ),
              content: isLoading
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Déconnexion en cours...'),
                      ],
                    )
                  : Text(
                      loc.logoutConfirmation,
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8)),
                    ),
              actions: isLoading
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          loc.cancel,
                          style: theme.textTheme.titleMedium?.copyWith(color: AppTheme.primaryOrange),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() => isLoading = true);
                          
                          try {
                            final userProvider = Provider.of<UserProvider>(context, listen: false);
                            final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
                            
                            // Réinitialiser le profile provider
                            await profileProvider.reset();
                            
                            // Déconnecter l'utilisateur
                            await userProvider.logout();
                            
                            if (context.mounted) {
                              Navigator.of(context).pop(); // Ferme le dialogue
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login', 
                                (Route<dynamic> route) => false
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setState(() => isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur lors de la déconnexion: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed, foregroundColor: Colors.white),
                        child: Text(loc.logout),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Widget _buildMobileMenu(BuildContext context, AppLocalizations loc) {
    final theme = Theme.of(context);
    
    return IconButton(
      icon: Icon(Icons.more_vert, color: theme.iconTheme.color, size: 28),
      onPressed: () => _showMobileMainMenu(context, loc, theme),
    );
  }

  void _showMobileMainMenu(BuildContext context, AppLocalizations loc, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadius))),
      isScrollControlled: true,
      backgroundColor: theme.bottomSheetTheme.backgroundColor ?? theme.cardColor,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16, left: 16, right: 16),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadius)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        loc.menu,
                        style: TextStyle(
                          color: theme.primaryTextTheme.titleLarge?.color ?? Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: Icon(Icons.close, color: theme.primaryTextTheme.titleLarge?.color ?? Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: Icon(Icons.movie, color: theme.iconTheme.color, size: 28),
                        title: Text(loc.films, style: theme.textTheme.titleMedium),
                        onTap: () {
                          Navigator.pop(context);
                          _showSubmenuModal(context, loc.films, ['Action', 'Comédie', 'Drame', 'Horreur', 'Science-fiction'], 'film-category');
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.tv, color: theme.iconTheme.color, size: 28),
                        title: Text(loc.series, style: theme.textTheme.titleMedium),
                        onTap: () {
                          Navigator.pop(context);
                          _showSubmenuModal(context, loc.series, ['Crime', 'Science-fiction', 'Comédie', 'Drama', 'Animation'], 'series-category');
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.add, color: theme.iconTheme.color, size: 28),
                        title: Text(loc.plus, style: theme.textTheme.titleMedium),
                        onTap: () {
                          Navigator.pop(context);
                          _showSubmenuModal(context, loc.plus, [loc.documentaires, loc.telerealites, loc.live, 'Sports', 'Kids'], 'plus-category');
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.public, color: theme.iconTheme.color, size: 28),
                        title: Text(loc.explorerParPays, style: theme.textTheme.titleMedium),
                        onTap: () {
                          Navigator.pop(context);
                          _showSubmenuModal(context, loc.explorerParPays, ['France', 'USA', 'Japon', 'Corée', 'Inde'], 'country');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSubmenuModal(BuildContext context, String title, List<String> subItems, String type) {
    final theme = Theme.of(context);
    final deviceInfoProvider = Provider.of<DeviceInfoProvider>(context, listen: false);
    final bool isTV = deviceInfoProvider.isTV;
    
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadius))),
      isScrollControlled: true,
      backgroundColor: theme.bottomSheetTheme.backgroundColor ?? theme.cardColor,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16, left: 16, right: 16),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadius)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: theme.primaryTextTheme.titleLarge?.color ?? Colors.white,
                          fontSize: isTV ? 26 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: IconButton(
                        icon: Icon(Icons.close, color: theme.primaryTextTheme.titleLarge?.color ?? Colors.white, size: isTV ? 32 : 24),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: subItems.length,
                  itemBuilder: (BuildContext context, int index) => Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5)),
                    ),
                    child: ListTile(
                      title: Text(
                        subItems[index],
                        style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface, fontSize: isTV ? 20 : null),
                      ),
                      tileColor: theme.cardColor,
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToGenrePage(context, subItems[index]);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HoverMenuWrapper extends StatefulWidget {
  final Widget child;
  const _HoverMenuWrapper({required this.child});

  @override
  State<_HoverMenuWrapper> createState() => _HoverMenuWrapperState();
}

class _HoverMenuWrapperState extends State<_HoverMenuWrapper> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final deviceInfoProvider = Provider.of<DeviceInfoProvider>(context, listen: false);
    final bool isTV = deviceInfoProvider.isTV;

    if (isTV) return widget.child;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        decoration: BoxDecoration(
          color: _isHovering ? AppTheme.primaryOrange.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        ),
        child: widget.child,
      ),
    );
  }
}