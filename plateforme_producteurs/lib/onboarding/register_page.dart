import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plateforme_producteurs/core/countries.dart';
import 'package:plateforme_producteurs/onboarding/widgets/producer_auth_shell.dart';
import 'package:plateforme_producteurs/services/api_client.dart';
import 'package:plateforme_producteurs/services/auth_service.dart';

class ProducerRegisterPage extends StatefulWidget {
  const ProducerRegisterPage({super.key});

  @override
  State<ProducerRegisterPage> createState() => _ProducerRegisterPageState();
}

class _ProducerRegisterPageState extends State<ProducerRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _firstname = TextEditingController();
  final _lastname = TextEditingController();
  final _phone = TextEditingController();
  final _company = TextEditingController();

  String _countryCode = 'CI';
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _firstname.dispose();
    _lastname.dispose();
    _phone.dispose();
    _company.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _loading) return;

    setState(() => _loading = true);

    try {
      final response = await ApiClient.instance.post(
        '/api/v1/auth/web/producer/register/',
        body: {
          'email': _email.text.trim(),
          'password': _password.text,
          'firstname': _firstname.text.trim(),
          'lastname': _lastname.text.trim(),
          'phone': _phone.text.trim(),
          'country_code': _countryCode,
          'company_name': _company.text.trim(),
        },
      );

      if (response.statusCode != 201) {
        throw ApiException(
          ApiClient.instance.errorMessage(
            response,
            fallback: 'Impossible de créer le compte Producteur.',
          ),
          statusCode: response.statusCode,
        );
      }

      final data = ApiClient.instance.decode(response);

      if (data is Map<String, dynamic>) {
        final access = data['access']?.toString();

        if (access != null && access.isNotEmpty) {
          ApiClient.instance.setAccessToken(access);
          await AuthService.instance.me();
        }
      }

      if (!mounted) return;
      context.go('/onboarding');
    } on ApiException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF67F00);

    return ProducerAuthShell(
      maxWidth: 1080,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ProducerFormHeader(
              title: 'Devenir Producteur EKEFLICKS',
              subtitle:
                  'Créez votre espace professionnel pour proposer vos films et séries à EKEFLICKS.',
            ),
            const SizedBox(height: 22),

            LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 760;
                final fieldWidth = desktop
                    ? (constraints.maxWidth - 16) / 2
                    : constraints.maxWidth;

                Widget cell(Widget child) =>
                    SizedBox(width: fieldWidth, child: child);

                return Wrap(
                  spacing: 16,
                  runSpacing: 14,
                  children: [
                    cell(
                      TextFormField(
                        controller: _firstname,
                        decoration: _decoration(
                          'Prénom *',
                          Icons.person_outline,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Champ requis'
                            : null,
                      ),
                    ),
                    cell(
                      TextFormField(
                        controller: _lastname,
                        decoration: _decoration('Nom *', Icons.person_outline),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Champ requis'
                            : null,
                      ),
                    ),
                    cell(
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _decoration(
                          'Adresse email *',
                          Icons.email_outlined,
                        ),
                        validator: (value) =>
                            value != null && value.contains('@')
                            ? null
                            : 'Email invalide',
                      ),
                    ),
                    cell(
                      TextFormField(
                        controller: _password,
                        obscureText: _obscurePassword,
                        decoration:
                            _decoration(
                              'Mot de passe *',
                              Icons.lock_outline,
                            ).copyWith(
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                        validator: (value) => value != null && value.length >= 8
                            ? null
                            : '8 caractères minimum',
                      ),
                    ),
                    cell(
                      TextFormField(
                        controller: _company,
                        decoration: _decoration(
                          'Nom de la société *',
                          Icons.business_outlined,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Champ requis'
                            : null,
                      ),
                    ),
                    cell(
                      DropdownButtonFormField<String>(
                        value: _countryCode,
                        isExpanded: true,
                        decoration: _decoration('Pays *', Icons.public),
                        items: producerCountries
                            .map(
                              (country) => DropdownMenuItem<String>(
                                value: country.code,
                                child: Text(country.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _countryCode = value);
                          }
                        },
                        validator: (value) => value == null || value.isEmpty
                            ? 'Sélectionnez un pays'
                            : null,
                      ),
                    ),
                    cell(
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: _decoration(
                          'Téléphone',
                          Icons.phone_outlined,
                          hint: 'Optionnel',
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 10),

            const Text(
              '* Champs obligatoires',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('J’ai déjà un compte Producteur'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Créer mon compte Producteur',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
