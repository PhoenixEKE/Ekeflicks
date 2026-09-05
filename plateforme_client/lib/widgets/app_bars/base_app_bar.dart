import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/providers/theme_provider.dart';
import 'package:app_ekeflicks/providers/locale_provider.dart';
import 'package:app_ekeflicks/widgets/search/ia_search_delegate.dart';
import 'package:app_ekeflicks/core/app_theme.dart';

abstract class BaseAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const BaseAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 900;
  bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900;

  String getLogoPath(BuildContext context) {
    final isLight = context.select<ThemeProvider, bool>((p) => p.isLightTheme);
    return isLight
        ? 'assets/images/logo_light.png'
        : 'assets/images/logo_dark.png';
  }

  Widget buildLogo(BuildContext context, {double height = 38}) {
    return GestureDetector(
      onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
      child: HoverableLogo(imagePath: getLogoPath(context), height: height),
    );
  }

  Widget buildThemeToggle(BuildContext context, AppLocalizations loc) {
    final themeProvider = context.read<ThemeProvider>();
    final isLight = themeProvider.isLightTheme;

    return IconButton(
      icon: Icon(
        isLight ? Icons.dark_mode : Icons.light_mode,
        size: 20,
        color: Theme.of(context).iconTheme.color,
      ),
      tooltip: loc.changerDeTheme,
      onPressed: themeProvider.toggleTheme,
    );
  }

  Widget buildLanguageToggle(BuildContext context, AppLocalizations loc) {
    return IconButton(
      icon: Icon(
        Icons.language,
        size: 20,
        color: Theme.of(context).iconTheme.color,
      ),
      tooltip: loc.changerDeLangue,
      onPressed: () => context.read<LocaleProvider>().toggleLocale(),
    );
  }

  Widget buildFaqIcon(BuildContext context, AppLocalizations loc) {
    return IconButton(
      icon: Icon(Icons.help_outline, color: Theme.of(context).iconTheme.color),
      tooltip:
          loc.faq, // Assurez-vous d'ajouter cette clé dans vos fichiers ARB
      onPressed: () => Navigator.of(context).pushNamed('/faq'),
    );
  }

  Widget buildSearchField(BuildContext context, AppLocalizations loc) {
    final isLight = context.select<ThemeProvider, bool>((p) => p.isLightTheme);

    return SizedBox(
      width: isDesktop(context) ? 250 : 200,
      child: TextField(
        readOnly: true,
        onTap: () => showSearch(context: context, delegate: IASearchDelegate()),
        decoration: InputDecoration(
          hintText: loc.rechercher,
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 10,
          ),
          filled: true,
          fillColor: isLight ? Colors.white : Colors.grey[850],
        ),
      ),
    );
  }
}

class HoverableLogo extends StatefulWidget {
  final String imagePath;
  final double height;

  const HoverableLogo({super.key, required this.imagePath, this.height = 38});

  @override
  State<HoverableLogo> createState() => _HoverableLogoState();
}

class _HoverableLogoState extends State<HoverableLogo>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return FocusableActionDetector(
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      mouseCursor: SystemMouseCursors.click,
      child: MouseRegion(
        onEnter: (_) {
          if (isDesktop) setState(() => _isHovering = true);
        },
        onExit: (_) {
          if (isDesktop) setState(() => _isHovering = false);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          transform:
              (_isHovering || _isFocused)
                  ? (Matrix4.identity()
                    ..scale(1.1)
                    ..rotateZ(0.015))
                  : Matrix4.identity(),
          transformAlignment: Alignment.center,
          child: Image.asset(
            widget.imagePath,
            height: widget.height,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const FlutterLogo(size: 32),
          ),
        ),
      ),
    );
  }
}
