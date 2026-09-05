import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plateforme_producteurs/core/countries.dart';
import 'package:plateforme_producteurs/onboarding/widgets/producer_auth_shell.dart';
import 'package:plateforme_producteurs/services/api_client.dart';
import 'package:plateforme_producteurs/services/producer_service.dart';

class ProducerOnboardingPage extends StatefulWidget {
  const ProducerOnboardingPage({super.key});

  @override
  State<ProducerOnboardingPage> createState() => _ProducerOnboardingPageState();
}

class _ProducerOnboardingPageState extends State<ProducerOnboardingPage> {
  final _formKey = GlobalKey<FormState>();

  final _company = TextEditingController();
  final _legalName = TextEditingController();
  final _legalForm = TextEditingController();
  final _registration = TextEditingController();
  final _tax = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  final _representative = TextEditingController();
  final _role = TextEditingController();

  String _countryCode = 'CI';

  bool _loading = true;
  bool _saving = false;
  bool _resending = false;
  bool _checkingEmail = false;
  bool _showVerification = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _company.dispose();
    _legalName.dispose();
    _legalForm.dispose();
    _registration.dispose();
    _tax.dispose();
    _address.dispose();
    _city.dispose();
    _phone.dispose();
    _representative.dispose();
    _role.dispose();
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

  Future<void> _load() async {
    try {
      final account = await ProducerService.instance.getOnboarding();

      if (!mounted) return;

      _company.text = account.companyName;
      _legalName.text = account.legalName ?? '';
      _legalForm.text = account.legalForm ?? '';
      _registration.text = account.registrationNumber ?? '';
      _tax.text = account.taxNumber ?? '';
      _address.text = account.address ?? '';
      _city.text = account.city ?? '';
      _phone.text = account.phone ?? '';
      _representative.text = account.representativeName ?? '';
      _role.text = account.representativeRole ?? '';

      final code = account.countryCode?.toUpperCase();
      if (code != null && producerCountries.any((c) => c.code == code)) {
        _countryCode = code;
      }

      // IMPORTANT :
      // l'email doit être vérifié avant toute redirection
      // vers le contrat.
      if (!account.emailVerified) {
        setState(() {
          _showVerification =
              account.representativeName?.trim().isNotEmpty == true;
        });
        return;
      }

      if (account.status == 'active') {
        context.go('/dashboard');
        return;
      }

      if (account.status == 'contract_pending') {
        context.go('/agreement');
        return;
      }
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) {
      return;
    }

    setState(() => _saving = true);

    try {
      final account = await ProducerService.instance.updateOnboarding(
        companyName: _company.text,
        legalName: _legalName.text,
        legalForm: _legalForm.text,
        registrationNumber: _registration.text,
        taxNumber: _tax.text,
        countryCode: _countryCode,
        address: _address.text,
        city: _city.text,
        phone: _phone.text,
        representativeName: _representative.text,
        representativeRole: _role.text,
      );

      if (!mounted) return;

      if (!account.emailVerified) {
        setState(() => _showVerification = true);
        return;
      }

      if (account.status == 'contract_pending') {
        context.go('/agreement');
      }
    } on ApiException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _resendVerification() async {
    if (_resending) return;

    setState(() => _resending = true);

    try {
      await ProducerService.instance.resendEmailVerification();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Un nouvel email de vérification vient d’être envoyé.'),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() => _resending = false);
      }
    }
  }

  Future<void> _checkEmailVerification() async {
    if (_checkingEmail) return;

    setState(() => _checkingEmail = true);

    try {
      final account = await ProducerService.instance.getOnboarding();

      if (!mounted) return;

      if (!account.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Votre adresse email n’est pas encore vérifiée.'),
          ),
        );
        return;
      }

      if (account.status == 'contract_pending') {
        context.go('/agreement');
        return;
      }

      setState(() => _showVerification = false);
    } on ApiException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() => _checkingEmail = false);
      }
    }
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _decoration(label, icon),
      validator: required
          ? (value) =>
                value == null || value.trim().isEmpty ? 'Champ requis' : null
          : null,
    );
  }

  Widget _verificationPanel() {
    const orange = Color(0xFFF67F00);

    return ProducerAuthShell(
      maxWidth: 600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProducerFormHeader(
            title: 'Vérifiez votre adresse email',
            subtitle:
                'Vos informations professionnelles ont été enregistrées. Vérifiez maintenant votre email pour accéder au contrat Producteur EKEFLICKS.',
            icon: Icons.mark_email_read_outlined,
          ),
          const SizedBox(height: 30),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: orange.withValues(alpha: 0.30)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cliquez sur le lien reçu par email. Vous serez ramené automatiquement vers le portail Producteurs.',
                    style: TextStyle(height: 1.45),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _checkingEmail ? null : _checkEmailVerification,
              icon: _checkingEmail
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('J’ai vérifié mon email — Continuer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _resending ? null : _resendVerification,
            icon: _resending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.email_outlined),
            label: const Text('Renvoyer l’email de vérification'),
          ),

          const SizedBox(height: 18),

          TextButton.icon(
            onPressed: () {
              setState(() => _showVerification = false);
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Modifier mes informations'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_showVerification) {
      return _verificationPanel();
    }

    const orange = Color(0xFFF67F00);

    return ProducerAuthShell(
      maxWidth: 1180,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ProducerFormHeader(
              title: 'Informations professionnelles',
              subtitle:
                  'Complétez votre dossier Producteur avant de consulter et signer le contrat EKEFLICKS.',
              icon: Icons.business_center_outlined,
            ),
            const SizedBox(height: 22),

            LayoutBuilder(
              builder: (context, constraints) {
                final desktop = constraints.maxWidth >= 800;
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
                      _field(
                        _company,
                        'Nom de la société / nom commercial *',
                        Icons.business_outlined,
                        required: true,
                      ),
                    ),
                    cell(
                      _field(
                        _legalName,
                        'Raison sociale *',
                        Icons.apartment_outlined,
                        required: true,
                      ),
                    ),
                    cell(
                      _field(
                        _legalForm,
                        'Forme juridique *',
                        Icons.account_balance_outlined,
                        required: true,
                      ),
                    ),
                    cell(
                      _field(
                        _registration,
                        'Numéro d’immatriculation / registre *',
                        Icons.badge_outlined,
                        required: true,
                      ),
                    ),
                    cell(
                      _field(
                        _tax,
                        'Numéro fiscal',
                        Icons.receipt_long_outlined,
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
                      _field(
                        _address,
                        'Adresse *',
                        Icons.location_on_outlined,
                        required: true,
                      ),
                    ),
                    cell(
                      _field(
                        _city,
                        'Ville *',
                        Icons.location_city_outlined,
                        required: true,
                      ),
                    ),
                    cell(_field(_phone, 'Téléphone', Icons.phone_outlined)),
                    cell(
                      _field(
                        _representative,
                        'Nom du représentant légal *',
                        Icons.person_outline,
                        required: true,
                      ),
                    ),
                    cell(
                      _field(
                        _role,
                        'Fonction du représentant *',
                        Icons.work_outline,
                        required: true,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 10),

            const Text(
              '* Champs obligatoires pour poursuivre vers le contrat.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),

            const SizedBox(height: 18),

            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 360,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Enregistrer et continuer',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
