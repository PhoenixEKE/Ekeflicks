import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/device_info_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/content_provider.dart';
import 'providers/user_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/avatar_provider.dart';

import 'routes.dart';
import 'ui/users/reset_password_page.dart';
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

  final openapi = Openapi(
    basePathOverride: 'http://180.149.198.245/api/v1/',
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

          final lastProfileId = _prefs.getInt('last_profile_id');
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
    _appLinks.uriLinkStream.listen((uri) {
      if (!mounted || uri == null) return;
      if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == "password-reset-confirm") {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    // Si la locale n'est pas définie, on force le français
    final locale = localeProvider.locale ?? const Locale('fr');

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
      initialRoute: '/',
      routes: getAppRoutes(),
    );
  }
}
