import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:app_ekeflicks/providers/device_info_provider.dart';
import 'package:app_ekeflicks/utils/keyboard_navigation_utils.dart';
import 'package:app_ekeflicks/utils/focus_utils.dart';
import 'base_app_bar.dart';

/// AppBar responsive pour mobile, desktop et TV
class SimpleAppBar extends BaseAppBar {
  final String logoPath;
  final VoidCallback? onLanguagePressed;
  final FocusNode? languageFocusNode;

  const SimpleAppBar({
    super.key,
    required this.logoPath,
    this.onLanguagePressed,
    this.languageFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final deviceInfo = Provider.of<DeviceInfoProvider>(context);

    if (deviceInfo.isTV) {
      return _buildTvAppBar(context, theme, loc);
    } else {
      return _buildStandardAppBar(context, theme, loc);
    }
  }

  /// AppBar standard (mobile / desktop)
  Widget _buildStandardAppBar(BuildContext context, ThemeData theme, AppLocalizations loc) {
    final isLoginScreen = ModalRoute.of(context)?.settings.name == '/login';

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      leading: Navigator.of(context).canPop()
          ? Tooltip(
              message: loc.retour,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            )
          : null,
      title: Image.asset(
        logoPath,
        height: 36,
      ),
      centerTitle: false,
      actions: [
        // 🔄 AJOUT : Bouton FAQ dans l'AppBar standard
        if (!isLoginScreen) // Ne pas afficher FAQ sur l'écran de login
          IconButton(
            icon: Icon(Icons.help_outline, color: theme.iconTheme.color), // 🔄 Icône FAQ
            onPressed: () => Navigator.of(context).pushNamed('/faq'), // 🔄 Route FAQ
            tooltip: loc.faq, // 🔄 Tooltip FAQ
          ),
        if (onLanguagePressed != null && isLoginScreen)
          IconButton(
            icon: Icon(Icons.language, color: theme.iconTheme.color),
            onPressed: onLanguagePressed,
            tooltip: loc.changerLangue,
          ),
      ],
    );
  }

  /// AppBar TV avec support télécommande et focus
  Widget _buildTvAppBar(BuildContext context, ThemeData theme, AppLocalizations loc) {
    final isLoginScreen = ModalRoute.of(context)?.settings.name == '/login';

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            logoPath,
            height: 48,
            width: 120,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          if (!isLoginScreen) // 🔄 AJOUT : Bouton FAQ pour TV
            _buildTvFaqButton(context, theme, loc),
          if (onLanguagePressed != null && languageFocusNode != null && isLoginScreen)
            _buildTvLanguageButton(context, theme, loc),
        ],
      ),
    );
  }

  // 🔄 AJOUT : Bouton FAQ optimisé pour TV
  Widget _buildTvFaqButton(BuildContext context, ThemeData theme, AppLocalizations loc) {
    final faqFocusNode = FocusNode();

    return KeyboardNavigator(
      focusNode: faqFocusNode,
      keyHandlers: {
        LogicalKeyboardKey.select: () => Navigator.of(context).pushNamed('/faq'),
        LogicalKeyboardKey.enter: () => Navigator.of(context).pushNamed('/faq'),
        LogicalKeyboardKey.space: () => Navigator.of(context).pushNamed('/faq'),
      },
      child: FocusUtils.buildFocusIndicator(
        focusNode: faqFocusNode,
        focusColor: AppTheme.primaryOrange,
        child: IconButton(
          icon: Icon(
            Icons.help_outline, // 🔄 Icône FAQ
            color: faqFocusNode.hasFocus
                ? AppTheme.primaryOrange
                : theme.iconTheme.color,
            size: 32,
          ),
          onPressed: () => Navigator.of(context).pushNamed('/faq'), // 🔄 Route FAQ
          tooltip: loc.faq, // 🔄 Tooltip FAQ
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(12),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }

  /// Bouton langue optimisé pour TV
  Widget _buildTvLanguageButton(BuildContext context, ThemeData theme, AppLocalizations loc) {
    return KeyboardNavigator(
      focusNode: languageFocusNode,
      keyHandlers: {
        LogicalKeyboardKey.select: onLanguagePressed!,
        LogicalKeyboardKey.enter: onLanguagePressed!,
        LogicalKeyboardKey.space: onLanguagePressed!,
      },
      child: FocusUtils.buildFocusIndicator(
        focusNode: languageFocusNode!,
        focusColor: AppTheme.primaryOrange,
        child: IconButton(
          icon: Icon(
            Icons.language,
            color: languageFocusNode!.hasFocus
                ? AppTheme.primaryOrange
                : theme.iconTheme.color,
            size: 32,
          ),
          onPressed: onLanguagePressed,
          tooltip: loc.changerLangue,
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(12),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    );
  }

  /// Gestion clavier / télécommande
  void handleKeyEvent(RawKeyEvent event, BuildContext context) {
    KeyboardNavigationService.handleBasicNavigation(
      event,
      onSelect: () {
        if (languageFocusNode?.hasFocus == true && onLanguagePressed != null) {
          onLanguagePressed!();
        }
      },
      onBack: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  /// Définir le focus initial (TV)
  void requestLanguageFocus(BuildContext context) {
    final deviceInfo = Provider.of<DeviceInfoProvider>(context, listen: false);
    if (deviceInfo.isTV && languageFocusNode != null) {
      languageFocusNode!.requestFocus();
    }
  }

  /// Libérer le focus (TV)
  void unfocusLanguage() {
    if (languageFocusNode != null && languageFocusNode!.hasFocus) {
      languageFocusNode!.unfocus();
    }
  }
}