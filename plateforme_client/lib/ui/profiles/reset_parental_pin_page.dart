import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_ekeflicks/providers/profile_provider.dart';
import 'package:app_ekeflicks/utils/api_error_message.dart';
import 'package:dio/dio.dart';

class ResetParentalPinPage extends StatefulWidget {
  const ResetParentalPinPage({super.key, this.token, this.profileId});

  final String? token;
  final String? profileId;

  @override
  State<ResetParentalPinPage> createState() => _ResetParentalPinPageState();
}

class _ResetParentalPinPageState extends State<ResetParentalPinPage> {
  final _pin = TextEditingController();
  final _confirmation = TextEditingController();
  String? _token;
  String? _profileId;
  bool _saving = false;

  void _close() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed('/login');
    }
  }

  @override
  void initState() {
    super.initState();
    _token = widget.token ?? Uri.base.queryParameters['token'];
    _profileId = widget.profileId ?? Uri.base.queryParameters['profile'];
  }

  Future<void> _submit() async {
    if (!RegExp(r'^\d{4,6}$').hasMatch(_pin.text) ||
        _pin.text != _confirmation.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Les PIN doivent être identiques et contenir 4 à 6 chiffres.',
          ),
          duration: Duration(seconds: 7),
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
          const SnackBar(
            content: Text(
              'PIN parental modifié. '
              'Un e-mail de confirmation vous a été envoyé.',
            ),
            duration: Duration(seconds: 7),
          ),
        );
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } on DioException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              firstApiErrorMessage(error.response?.data) ??
                  'Lien invalide ou expiré.',
            ),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Retour',
            onPressed: _close,
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Nouveau PIN parental'),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
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
                    decoration: const InputDecoration(
                      labelText: 'Nouveau PIN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmation,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Confirmer le PIN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Modifier le PIN'),
                    ),
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
