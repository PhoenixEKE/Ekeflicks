import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_theme.dart';
import 'core/api_config.dart';
import 'l10n/app_localizations.dart';
import 'providers/device_info_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/content_provider.dart';
import 'providers/user_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/avatar_provider.dart';

import 'routes.dart' as app_routes;
import 'ui/users/reset_password_page.dart';
import 'ui/profiles/reset_parental_pin_page.dart';
import 'package:app_ekeflicks/src/openapi.dart';
import 'services/content_api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation du thème
  await AppTheme.init();

  // Initialisation du provider de locale
  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();

  // Initialisation du provider de thème
  final themeProvider = ThemeProvider();
  await themeProvider.loadThemePrefs();

  // Openapi reads ApiConfig, including the API_ORIGIN build-time override.
  // Keeping the deployment URL out of this file prevents web builds from
  // silently sending authentication requests to a stale Apache host.
  final openapi = Openapi(
    basePathOverride: '${ApiConfig.origin}/api/v1/',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider(create: (_) => DeviceInfoProvider()),
        ChangeNotifierProvider(
          create: (_) => ContentProvider(ContentApiService(openapi.dio)),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider(openapi)),
        ChangeNotifierProvider(create: (_) => ProfileProvider(openapi)),
        ChangeNotifierProvider(create: (context) => AvatarProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;
  late final SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _prefs = await SharedPreferences.getInstance();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

      final isLoggedIn = await userProvider.checkAuthStatus();
      if (isLoggedIn) {
        try {
          await profileProvider.loadProfilesGlobal();

          final lastProfileId = _prefs.getString('last_profile_id');
          if (lastProfileId != null) {
            final savedProfile = profileProvider.getProfileById(lastProfileId);
            if (savedProfile != null) {
              await profileProvider.selectProfile(savedProfile);
            }
          }

          if (profileProvider.currentProfile == null && profileProvider.hasProfiles) {
            await profileProvider.selectProfile(
              profileProvider.mainProfile ?? profileProvider.availableProfiles.first,
            );
          }
        } catch (e) {
          await userProvider.logout();
          await profileProvider.reset();
        }
      }
    });
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    // Gérer le lien initial si l'app est ouverte via un deep link
    _appLinks.getInitialLink().then(_handleDeepLink);
    // Écouter les liens ultérieurs
    _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri? uri) {
    if (!mounted || uri == null) return;

    // Gérer la réinitialisation du mot de passe
    // Supporte les deux formats : /reset-password et /password-reset-confirm
    if (uri.pathSegments.isNotEmpty &&
        (uri.pathSegments[0] == 'reset-password' ||
            uri.pathSegments[0] == 'password-reset-confirm')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
      );
    }
    // Gérer la réinitialisation du PIN parental
    // Supporte à la fois le format chemin (/reset-parental-pin) et le format query string (?action=reset-parental-pin)
    else if ((uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'reset-parental-pin') ||
             uri.queryParameters['action'] == 'reset-parental-pin') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ResetParentalPinPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    // Si la locale n'est pas définie, on force le français
    final locale = localeProvider.locale ?? const Locale('fr');

    // Déterminer la route initiale en fonction de l'URL
    final initialUri = Uri.base;
    final initialRoute = initialUri.queryParameters['action'] ==
            'reset-parental-pin'
        ? '/reset-parental-pin'
        : initialUri.path == '/reset-password'
            ? '/reset-password'
            : initialUri.path == '/reset-parental-pin'
                ? '/reset-parental-pin'
                : '/';

    return MaterialApp(
      title: 'EkeFlicks',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: localeProvider.supportedLocales,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: initialRoute,
      routes: app_routes.getAppRoutes(),
    );
  }
}
