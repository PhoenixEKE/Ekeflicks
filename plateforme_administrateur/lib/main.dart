import 'package:flutter/material.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:plateforme_producteurs/providers/locale_provider.dart';
import 'routes.dart';
import 'api/admin_api_client.dart';
import 'providers/admin_auth_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        Provider(create: (_) => AdminApiClient()),
        ChangeNotifierProvider(create: (context) => AdminAuthProvider(context.read<AdminApiClient>())),
      ],
      child: const ProducerApp(),
    ),
  );
}

class ProducerApp extends StatelessWidget {
  const ProducerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp.router(
      title: 'Ekeflicks Producteurs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      routerConfig: appRouter,
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
      ],
    );
  }
}
