import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:plateforme_producteurs/core/web_helpers.dart';
import 'package:plateforme_producteurs/models/producer_onboarding.dart';
import 'package:plateforme_producteurs/onboarding/widgets/producer_auth_shell.dart';
import 'package:plateforme_producteurs/services/api_client.dart';
import 'package:plateforme_producteurs/services/producer_service.dart';

class ProducerAgreementPage extends StatefulWidget {
  const ProducerAgreementPage({super.key});

  @override
  State<ProducerAgreementPage> createState() => _ProducerAgreementPageState();
}

class _ProducerAgreementPageState extends State<ProducerAgreementPage> {
  ProducerAgreement? _agreement;

  bool _accepted = false;
  bool _loading = true;
  bool _signing = false;
  bool _opening = false;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final agreement = await ProducerService.instance.getCurrentAgreement();

      if (!mounted) return;

      setState(() {
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

  String _date(DateTime? value) {
    if (value == null) return '—';

    return DateFormat('dd/MM/yyyy à HH:mm').format(value.toLocal());
  }

  Future<void> _openContract() async {
    if (_opening) return;

    setState(() => _opening = true);

    try {
      final bytes = await ProducerService.instance.downloadAgreement(
        download: false,
      );

      openPdfBytes(bytes);
    } on ApiException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() => _opening = false);
      }
    }
  }

  Future<void> _downloadContract() async {
    if (_downloading) return;

    setState(() => _downloading = true);

    try {
      final bytes = await ProducerService.instance.downloadAgreement();

      final agreement = _agreement;

      final version =
          agreement?.contractVersion.replaceAll(
            RegExp(r'[^A-Za-z0-9._-]'),
            '-',
          ) ??
          'producteur';

      final suffix = agreement?.isSigned == true ? 'signe' : 'a-signer';

      downloadPdfBytes(
        bytes,
        'contrat-producteur-ekeflicks-$version-$suffix.pdf',
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  Future<void> _sign() async {
    if (_signing || !_accepted) return;

    setState(() => _signing = true);

    try {
      final agreement = await ProducerService.instance.signAgreement();

      if (!mounted) return;

      setState(() {
        _agreement = agreement;
        _accepted = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Contrat signé. Votre compte Producteur est maintenant activé.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));

      if (e.statusCode == 409) {
        await _load();
      }
    } finally {
      if (mounted) {
        setState(() => _signing = false);
      }
    }
  }

  Widget _statusCard(ProducerAgreement agreement) {
    const orange = Color(0xFFF67F00);
    final signed = agreement.isSigned;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: signed
            ? Colors.green.withValues(alpha: 0.09)
            : orange.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: signed
              ? Colors.green.withValues(alpha: 0.30)
              : orange.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            signed ? Icons.verified_outlined : Icons.pending_actions_outlined,
            color: signed ? Colors.greenAccent : orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signed ? 'Contrat signé' : 'Signature requise',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  signed
                      ? 'Votre contrat est conservé dans votre espace Producteur.'
                      : 'Lisez le document personnalisé avant de confirmer votre acceptation.',
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ProducerAuthShell(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final agreement = _agreement;

    if (agreement == null) {
      return const ProducerAuthShell(
        child: Center(child: Text('Le contrat Producteur est indisponible.')),
      );
    }

    final signed = agreement.isSigned;

    return ProducerAuthShell(
      maxWidth: 1180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProducerFormHeader(
            title: signed
                ? 'Mon contrat Producteur'
                : 'Contrat Producteur EKEFLICKS',
            subtitle: signed
                ? 'Retrouvez à tout moment le contrat associé à votre compte Producteur.'
                : 'Consultez attentivement votre contrat personnalisé avant de le signer.',
            icon: signed
                ? Icons.verified_user_outlined
                : Icons.description_outlined,
          ),

          const SizedBox(height: 20),

          _statusCard(agreement),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                _ContractLine(
                  label: 'Document',
                  value: agreement.contractTitle,
                ),
                _ContractLine(
                  label: 'Version',
                  value: agreement.contractVersion,
                ),
                if (agreement.effectiveDate != null)
                  _ContractLine(
                    label: 'Date d’effet',
                    value: DateFormat(
                      'dd/MM/yyyy',
                    ).format(agreement.effectiveDate!.toLocal()),
                  ),
                if (signed)
                  _ContractLine(
                    label: 'Signé le',
                    value: _date(agreement.signedAt),
                  ),
                if (signed && agreement.signerName?.trim().isNotEmpty == true)
                  _ContractLine(
                    label: 'Signataire',
                    value: agreement.signerName!,
                  ),
                if (signed && agreement.signerRole?.trim().isNotEmpty == true)
                  _ContractLine(label: 'Qualité', value: agreement.signerRole!),
              ],
            ),
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _opening ? null : _openContract,
                  icon: _opening
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(
                    signed ? 'Ouvrir mon contrat' : 'Lire le contrat PDF',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _downloading ? null : _downloadContract,
                  icon: _downloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                  label: const Text('Télécharger'),
                ),
              ),
            ],
          ),

          if (!signed) ...[
            const SizedBox(height: 26),

            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: CheckboxListTile(
                value: _accepted,
                activeColor: const Color(0xFFF67F00),
                onChanged: (value) {
                  setState(() => _accepted = value == true);
                },
                title: const Text(
                  'Je reconnais avoir lu et accepté le contrat Producteur EKEFLICKS qui m’a été présenté.',
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'La signature utilise les informations du représentant légal enregistrées dans votre dossier Producteur.',
                    style: TextStyle(color: Colors.white60, height: 1.4),
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _accepted && !_signing ? _sign : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF67F00),
                  foregroundColor: Colors.white,
                ),
                icon: _signing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.draw_outlined),
                label: const Text(
                  'Signer et activer mon compte Producteur',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],

          if (signed) ...[
            const SizedBox(height: 22),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF67F00),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.dashboard_outlined),
                label: const Text('Accéder à mon espace Producteur'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContractLine extends StatelessWidget {
  const _ContractLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.white54)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
