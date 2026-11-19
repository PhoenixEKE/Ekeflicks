import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/models/producer_onboarding.dart';
import 'package:plateforme_producteurs/services/api_client.dart';
import 'package:plateforme_producteurs/services/producer_service.dart';
import 'package:plateforme_producteurs/core/web_helpers.dart';
import 'package:geolocator/geolocator.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  ProducerAccount? _account;
  ProducerAgreement? _agreement;

  bool _loading = true;
  bool _privacyLoading = true;
  bool _privacySaving = false;
  Map<String, dynamic> _privacyPreferences = const {
    'microphone_enabled': false,
    'camera_enabled': false,
    'automatic_geolocation': false,
    'eke_voice_gender': 'female',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final account = await ProducerService.instance.getOnboarding();

      ProducerAgreement? agreement;

      try {
        agreement = await ProducerService.instance.getCurrentAgreement();
      } catch (_) {
        agreement = null;
      }

      try {
        _privacyPreferences = await ProducerService.instance.getProducerPrivacyPreferences();
      } catch (_) {
        // Profile details remain available if this optional endpoint is unavailable.
      } finally {
        _privacyLoading = false;
      }

      if (!mounted) return;

      setState(() {
        _account = account;
        _agreement = agreement;
      });
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

  Future<void> _setPrivacyPreference(String key, bool enabled) async {
    if (_privacySaving) return;
    setState(() => _privacySaving = true);
    try {
      if (key == 'automatic_geolocation' && enabled) {
        final permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
          throw Exception(Localizations.localeOf(context).languageCode == 'en'
              ? 'Location permission was not granted. You can enable it later in your browser or device settings.'
              : 'L’autorisation de localisation n’a pas été accordée. Vous pourrez l’activer plus tard dans les réglages du navigateur ou de l’appareil.');
        }
      }
      final updated = await ProducerService.instance.updateProducerPrivacyPreferences({key: enabled});
      if (mounted) setState(() => _privacyPreferences = updated);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _privacySaving = false);
    }
  }

  Widget _privacySettings() {
    final english = Localizations.localeOf(context).languageCode == 'en';
    Widget consent(String key, String title, String subtitle, IconData icon) => CheckboxListTile(
      value: _privacyPreferences[key] == true,
      onChanged: _privacySaving || _privacyLoading ? null : (value) => _setPrivacyPreference(key, value == true),
      controlAffinity: ListTileControlAffinity.leading,
      secondary: Icon(icon, color: AppTheme.primaryOrange),
      title: Text(title),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
    );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(english ? 'Privacy and permissions' : 'Confidentialité et autorisations', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(english
              ? 'These choices are optional. You can withdraw them here; your browser or device may also ask separately when a feature is used.'
              : 'Ces choix sont facultatifs. Vous pouvez les retirer ici; le navigateur ou l’appareil peut aussi demander une autorisation distincte au moment d’utiliser une fonction.'),
          if (_privacyLoading) const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: LinearProgressIndicator()),
          consent('microphone_enabled', english ? 'Allow microphone for Eke voice input' : 'Autoriser le micro pour dicter à Eke', english ? 'Audio is used only after you tap the microphone.' : 'Le micro est utilisé uniquement lorsque vous appuyez sur le bouton de dictée.', Icons.mic_none),
          consent('camera_enabled', english ? 'Allow camera for content images' : 'Autoriser la caméra pour les images de contenu', english ? 'Camera access is requested only when you choose Camera in an upload form.' : 'L’accès caméra sera demandé uniquement si vous choisissez Caméra dans un formulaire de dépôt.', Icons.photo_camera_outlined),
          consent('automatic_geolocation', english ? 'Allow automatic geolocation' : 'Autoriser la géolocalisation automatique', english ? 'Location is optional and requested only while using a feature that needs it. EKEFLICKS does not track your location in the background.' : 'La localisation est facultative et ne sera demandée que pendant l’usage d’une fonction qui en a besoin. EKEFLICKS ne suit pas votre position en arrière-plan.', Icons.location_searching),
          if (_privacySaving) const Align(alignment: Alignment.centerRight, child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        ]),
      ),
    );
  }

  Future<void> _editAccount(ProducerAccount account) async {
    final fields = <String, TextEditingController>{
      'firstname': TextEditingController(text: account.firstname),
      'lastname': TextEditingController(text: account.lastname),
      'company': TextEditingController(text: account.companyName),
      'legal': TextEditingController(text: account.legalName ?? ''),
      'form': TextEditingController(text: account.legalForm ?? ''),
      'registration': TextEditingController(text: account.registrationNumber ?? ''),
      'tax': TextEditingController(text: account.taxNumber ?? ''),
      'country': TextEditingController(text: account.countryCode ?? ''),
      'address': TextEditingController(text: account.address ?? ''),
      'city': TextEditingController(text: account.city ?? ''),
      'phone': TextEditingController(text: account.phone ?? ''),
      'representative': TextEditingController(text: account.representativeName ?? ''),
      'role': TextEditingController(text: account.representativeRole ?? ''),
    };
    var saving = false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) {
        final labels = <String, String>{
          'firstname': 'Prénom', 'lastname': 'Nom', 'company': 'Nom de la société',
          'legal': 'Raison sociale', 'form': 'Forme juridique',
          'registration': 'Immatriculation', 'tax': 'Numéro fiscal',
          'country': 'Pays (code ISO)', 'address': 'Adresse', 'city': 'Ville',
          'phone': 'Téléphone', 'representative': 'Représentant légal', 'role': 'Fonction',
        };
        return AlertDialog(
          title: const Text('Modifier mes informations'),
          content: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [for (final entry in fields.entries) Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(controller: entry.value, decoration: InputDecoration(labelText: labels[entry.key], border: const OutlineInputBorder())),
            )],
          )),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
            FilledButton(onPressed: saving ? null : () async {
              setDialogState(() => saving = true);
              try {
                await ProducerService.instance.updateOnboarding(
                  companyName: fields['company']!.text, legalName: fields['legal']!.text,
                  legalForm: fields['form']!.text, registrationNumber: fields['registration']!.text,
                  taxNumber: fields['tax']!.text, countryCode: fields['country']!.text,
                  address: fields['address']!.text, city: fields['city']!.text,
                  phone: fields['phone']!.text, representativeName: fields['representative']!.text,
                  representativeRole: fields['role']!.text,
                );
                await ProducerService.instance.updatePersonalInfo(
                  firstname: fields['firstname']!.text, lastname: fields['lastname']!.text,
                  phone: fields['phone']!.text, countryCode: fields['country']!.text,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              } catch (error) {
                setDialogState(() => saving = false);
                if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(error.toString())));
              }
            }, child: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Enregistrer')),
          ],
        );
      }),
    );
    for (final controller in fields.values) { controller.dispose(); }
    if (saved == true) await _load();
  }

  Widget _info(
    String label,
    String? value, {
    IconData icon = Icons.info_outline,
  }) {
    final text = value?.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryOrange, size: 22),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textWhite70,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text == null || text.isEmpty ? '—' : text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emailInfo(String? email) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _info('Email', email, icon: Icons.email_outlined),
      TextButton.icon(
        onPressed: () => context.push('/support'),
        icon: const Icon(Icons.support_agent_outlined, size: 18),
        label: Text(
          Localizations.localeOf(context).languageCode == 'en'
              ? 'Request a change through Support'
              : 'Envoyer une demande depuis Support',
        ),
      ),
    ],
  );

  Future<void> _downloadSignedContract(ProducerAgreement agreement) async {
    try {
      final bytes = await ProducerService.instance.downloadAgreement(
        signed: true,
      );

      final version = agreement.contractVersion.replaceAll(
        RegExp(r'[^A-Za-z0-9._-]'),
        '-',
      );

      downloadPdfBytes(
        bytes,
        'contrat-producteur-ekeflicks-$version-signe.pdf',
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      final historicalUnavailable =
          e.statusCode == 404 && agreement.contractVersion == '2026-09-v1';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            historicalUnavailable
                ? 'Le contrat historique est bien enregistré comme signé, '
                      'mais son PDF signé archivé n’est pas disponible.'
                : e.message,
          ),
        ),
      );
    }
  }

  Widget _contractCard(ProducerAgreement agreement) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.verified_outlined,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contrat Producteur',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${agreement.contractTitle} • Version ${agreement.contractVersion}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textWhite70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/agreement'),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Mon contrat'),
                ),
                ElevatedButton.icon(
                  onPressed: agreement.isSigned
                      ? () => _downloadSignedContract(agreement)
                      : null,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Télécharger le contrat signé'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final account = _account;
    final agreement = _agreement;

    if (account == null) {
      return const Center(child: Text('Profil Producteur indisponible.'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.sizeOf(context).width < 600 ? 12 : 24,
        18,
        MediaQuery.sizeOf(context).width < 600 ? 12 : 24,
        24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  child: Wrap(
                    spacing: 18,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppTheme.primaryOrange.withValues(
                          alpha: 0.16,
                        ),
                        child: const Icon(
                          Icons.business_center_outlined,
                          color: AppTheme.primaryOrange,
                          size: 31,
                        ),
                      ),
                      const SizedBox(width: 18),
                      SizedBox(
                        width: 280,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.companyName,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              account.displayName,
                              style: const TextStyle(
                                color: AppTheme.textWhite70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          account.status == 'active'
                              ? 'Compte actif'
                              : account.status,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _editAccount(account),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Modifier mes informations'),
                      ),
                    ],
                  ),
                ),
              ),

              if (agreement?.isSigned == true) ...[
                const SizedBox(height: 12),
                _contractCard(agreement!),
              ],

              const SizedBox(height: 14),

              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Informations professionnelles',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 1050
                              ? 3
                              : constraints.maxWidth >= 650
                              ? 2
                              : 1;

                          const spacing = 12.0;

                          final width =
                              (constraints.maxWidth -
                                  ((columns - 1) * spacing)) /
                              columns;

                          Widget cell(Widget child) =>
                              SizedBox(width: width, child: child);

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: [
                              cell(_emailInfo(account.email)),
                              cell(
                                _info(
                                  'Raison sociale',
                                  account.legalName,
                                  icon: Icons.apartment_outlined,
                                ),
                              ),
                              cell(
                                _info(
                                  'Forme juridique',
                                  account.legalForm,
                                  icon: Icons.account_balance_outlined,
                                ),
                              ),
                              cell(
                                _info(
                                  'Immatriculation',
                                  account.registrationNumber,
                                  icon: Icons.badge_outlined,
                                ),
                              ),
                              cell(
                                _info(
                                  'Numéro fiscal',
                                  account.taxNumber,
                                  icon: Icons.receipt_long_outlined,
                                ),
                              ),
                              cell(
                                _info(
                                  'Adresse',
                                  account.address,
                                  icon: Icons.location_on_outlined,
                                ),
                              ),
                              cell(
                                _info(
                                  'Ville',
                                  account.city,
                                  icon: Icons.location_city_outlined,
                                ),
                              ),
                              cell(
                                _info(
                                  'Pays',
                                  account.countryCode,
                                  icon: Icons.public,
                                ),
                              ),
                              cell(
                                _info(
                                  'Téléphone',
                                  account.phone,
                                  icon: Icons.phone_outlined,
                                ),
                              ),
                              cell(
                                _info(
                                  'Représentant légal',
                                  account.representativeName,
                                  icon: Icons.person_outline,
                                ),
                              ),
                              cell(
                                _info(
                                  'Fonction',
                                  account.representativeRole,
                                  icon: Icons.work_outline,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _privacySettings(),
            ],
          ),
        ),
      ),
    );
  }
}
