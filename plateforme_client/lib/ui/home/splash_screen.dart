import 'package:flutter/material.dart';
import 'package:app_ekeflicks/ui/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/providers/device_info_provider.dart';
import 'package:app_ekeflicks/providers/profile_provider.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';
import 'package:app_ekeflicks/ui/profiles/profile_selection_page.dart';
import 'package:app_ekeflicks/ui/users/post_login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    if (_navigated) return;
    _navigated = true;

    final deviceInfo = Provider.of<DeviceInfoProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Attendre l'initialisation du device info
    int tries = 0;
    while (!deviceInfo.isInitialized && tries < 30) {
      await Future.delayed(const Duration(milliseconds: 100));
      tries++;
    }

    if (!mounted) return;

    final isLoggedIn = userProvider.isLoggedIn;
    final hasUser = userProvider.currentUser != null;

    // Sur toutes les plateformes, une session restaurée doit reprendre
    // le même parcours qu'une connexion réussie.

    // Attendre 2s pour mobile/TV
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    Widget nextPage;
    if (isLoggedIn && hasUser) {
      try {
        // CORRECTION: Retirer le paramètre user_Id
        await profileProvider.loadProfiles();

        if (profileProvider.availableProfiles.length > 1) {
          nextPage = const ProfileSelectionPage();
        } else {
          nextPage = const PostLoginPage();
        }
      } catch (e) {
        // Le compte reste authentifié même si les profils ne peuvent pas
        // être chargés temporairement.
        debugPrint('Error loading profiles: $e');
        nextPage = const PostLoginPage();
      }
    } else {
      // Un visiteur non authentifié doit accéder à l'accueil public.
      // La connexion et l'inscription restent des actions volontaires.
      nextPage = const HomeScreen();
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceInfo = Provider.of<DeviceInfoProvider>(context);
    final mediaQuery = MediaQuery.of(context);

    if (deviceInfo.isInitialized &&
        !deviceInfo.isTV &&
        mediaQuery.size.width >= 1000) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/animations/splashscreen.gif', width: 150),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
