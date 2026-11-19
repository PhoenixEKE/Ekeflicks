import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/notification_service.dart';

class UnsubscribePage extends StatefulWidget {
  const UnsubscribePage({super.key, this.token});
  final String? token;
  @override
  State<UnsubscribePage> createState() => _UnsubscribePageState();
}

class _UnsubscribePageState extends State<UnsubscribePage> {
  late Future<void> _result;
  @override
  void initState() {
    super.initState();
    final dio = context.read<ProfileProvider>().apiClient.dio;
    final token = widget.token;

    _result = Future.microtask(() {
      if (token == null || token.isEmpty) {
        throw StateError('Lien invalide');
      }
      return NotificationService(dio).unsubscribe(token);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Désabonnement')),
    body: FutureBuilder<void>(
      future: _result,
      builder: (_, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              snapshot.hasError
                  ? 'Ce lien est invalide ou a expiré.'
                  : 'Vous êtes désabonné des e-mails facultatifs.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    ),
  );
}
