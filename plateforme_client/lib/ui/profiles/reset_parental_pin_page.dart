import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_ekeflicks/providers/profile_provider.dart';

class ResetParentalPinPage extends StatefulWidget {
  const ResetParentalPinPage({super.key});

  @override
  State<ResetParentalPinPage> createState() => _ResetParentalPinPageState();
}

class _ResetParentalPinPageState extends State<ResetParentalPinPage> {
  final _pin = TextEditingController();
  final _confirmation = TextEditingController();
  String? _token;
  String? _profileId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    AppLinks().getInitialLink().then(_readLink);
    _readLink(Uri.base);
  }

  void _readLink(Uri? uri) {
    if (uri == null || !mounted) return;
    setState(() {
      _token = uri.queryParameters['token'];
      _profileId = uri.queryParameters['profile'];
    });
  }

  Future<void> _submit() async {
    if (!RegExp(r'^\d{4,6}$').hasMatch(_pin.text) ||
        _pin.text != _confirmation.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Les PIN doivent être identiques et contenir 4 à 6 chiffres.',
          ),
        ),
      );
      return;
    }
    if (_token == null || _profileId == null) return;
    setState(() => _saving = true);
    try {
      await context.read<ProfileProvider>().apiClient.dio.post<Object>(
        '/profiles/$_profileId/confirm-pin-reset/',
        data: {'token': _token, 'new_pin': _pin.text},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN parental modifié.')),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lien invalide ou expiré.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Nouveau PIN parental')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _pin,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration:
                        const InputDecoration(labelText: 'Nouveau PIN'),
                  ),
                  TextField(
                    controller: _confirmation,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration:
                        const InputDecoration(labelText: 'Confirmer le PIN'),
                  ),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: const Text('Modifier le PIN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  @override
  void dispose() {
    _pin.dispose();
    _confirmation.dispose();
    super.dispose();
  }
}
