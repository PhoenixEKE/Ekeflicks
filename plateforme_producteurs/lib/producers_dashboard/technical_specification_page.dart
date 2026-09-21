import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plateforme_producteurs/core/app_theme.dart';
import 'package:plateforme_producteurs/core/web_helpers.dart';
import 'package:plateforme_producteurs/services/producer_service.dart';
import 'package:plateforme_producteurs/widgets/producer_page_shell.dart';

class TechnicalSpecificationPage extends StatefulWidget {
  const TechnicalSpecificationPage({super.key});

  @override
  State<TechnicalSpecificationPage> createState() =>
      _TechnicalSpecificationPageState();
}

class _TechnicalSpecificationPageState
    extends State<TechnicalSpecificationPage> {
  Map<String, dynamic>? _specification;
  Object? _error;
  bool _loading = true;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _loadSpecification();
  }

  Future<void> _loadSpecification() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final specification = await ProducerService.instance
          .getTechnicalSpecification();

      if (!mounted) {
        return;
      }

      setState(() {
        _specification = specification;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    if (_downloading) {
      return;
    }

    setState(() {
      _downloading = true;
    });

    try {
      final bytes = await ProducerService.instance
          .downloadTechnicalSpecification();

      final version = _text(_specification?['version']);
      final safeVersion = version.isEmpty
          ? 'actuel'
          : version.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

      downloadPdfBytes(
        bytes,
        'cahier-des-charges-technique-EKEFLICKS-$safeVersion.pdf',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Téléchargement impossible : $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
        });
      }
    }
  }

  String _text(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  String _publicationDate(dynamic value) {
    final raw = _text(value);

    if (raw.isEmpty) {
      return '';
    }

    final date = DateTime.tryParse(raw);

    if (date == null) {
      return raw;
    }

    return DateFormat('dd/MM/yyyy').format(date.toLocal());
  }

  List<Map<String, dynamic>> _sections() {
    final raw = _specification?['sections'];

    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> _items(Map<String, dynamic> section) {
    final raw = section['items'];

    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ProducerPageShell(
      title: 'Cahier des charges technique',
      showBack: true,
      maxWidth: 1100,
      scrollable: true,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return _ErrorState(error: _error.toString(), onRetry: _loadSpecification);
    }

    final specification = _specification;

    if (specification == null) {
      return _ErrorState(
        error: 'Aucun cahier des charges technique disponible.',
        onRetry: _loadSpecification,
      );
    }

    final title = _text(specification['title']);
    final version = _text(specification['version']);
    final introduction = _text(specification['introduction']);
    final publication = _publicationDate(specification['published_at']);
    final sections = _sections();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 20,
          runSpacing: 16,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? 'Cahier des charges technique' : title,
                    style: AppTheme.textTitle.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.verified_outlined,
                        label: version.isEmpty
                            ? 'Version publiée'
                            : 'Version $version',
                      ),
                      if (publication.isNotEmpty)
                        _InfoChip(
                          icon: Icons.calendar_today_outlined,
                          label: 'Publié le $publication',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _downloading ? null : _downloadPdf,
              icon: _downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              label: Text(
                _downloading ? 'Téléchargement…' : 'Télécharger le PDF',
              ),
            ),
          ],
        ),
        if (introduction.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            child: Text(
              introduction,
              style: AppTheme.textBody.copyWith(height: 1.55),
            ),
          ),
        ],
        const SizedBox(height: 28),
        if (sections.isEmpty)
          Text('Aucune section disponible.', style: AppTheme.textBody)
        else
          ...sections.map(
            (section) => _SectionCard(section: section, items: _items(section)),
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: AppTheme.primary),
          const SizedBox(width: 7),
          Text(
            label,
            style: AppTheme.textCaption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.items});

  final Map<String, dynamic> section;
  final List<Map<String, dynamic>> items;

  String _text(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final title = _text(section['title']);
    final description = _text(section['description']);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.textTitle.copyWith(fontSize: 20)),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTheme.textBody.copyWith(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: 18),
            ...items.map(_buildItem),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item) {
    final label = _text(item['label']);
    final value = _text(item['value']);
    final required = item['required'] == true;

    if (label.isEmpty && value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(label, style: AppTheme.textBodyBold),
                      if (required)
                        Text(
                          'Obligatoire',
                          style: AppTheme.textCaption.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                if (label.isNotEmpty && value.isNotEmpty)
                  const SizedBox(height: 3),
                if (value.isNotEmpty)
                  Text(
                    value,
                    style: AppTheme.textBody.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.45,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 54,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: 18),
              Text(
                'Cahier des charges indisponible',
                style: AppTheme.textTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                error,
                style: AppTheme.textBody.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
