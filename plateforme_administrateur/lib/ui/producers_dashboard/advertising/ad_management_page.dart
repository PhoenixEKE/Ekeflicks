import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:plateforme_administrateur/api/admin_api_client.dart';
import 'package:plateforme_administrateur/core/core.dart';

class AdManagementPage extends StatefulWidget {
  const AdManagementPage({super.key});

  @override
  State<AdManagementPage> createState() => _AdManagementPageState();
}

class _AdManagementPageState extends State<AdManagementPage> {
  late Future<Map<String, dynamic>> _data;
  final TextEditingController _searchController = TextEditingController();
  String? _statusFilter;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final api = context.read<AdminApiClient>();
    final values = await Future.wait([
      api.adCampaigns(status: _statusFilter, search: _search),
      api.advertisingAnalytics(days: 30),
    ]);
    return {
      'campaigns': values[0] as List<Map<String, dynamic>>,
      'analytics': values[1] as Map<String, dynamic>,
    };
  }

  void _refresh() => setState(() => _data = _load());

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _edit([Map<String, dynamic>? campaign]) async {
    final changes = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CampaignEditor(campaign: campaign),
    );
    if (changes == null || !mounted) return;
    try {
      final api = context.read<AdminApiClient>();
      if (campaign == null) {
        await api.createAdCampaign(changes);
      } else {
        await api.updateAdCampaign(campaign['id'], changes);
      }
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(campaign == null ? 'Campagne créée.' : 'Campagne mise à jour.')),
        );
      }
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _setStatus(Map<String, dynamic> campaign, String value) async {
    try {
      await context.read<AdminApiClient>().setAdCampaignStatus(campaign['id'], value);
      _refresh();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _archive(Map<String, dynamic> campaign) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archiver la campagne ?'),
        content: Text('« ${campaign['name']} » ne sera plus diffusée. Son historique de rapports sera conservé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Archiver')),
        ],
      ),
    );
    if (accepted != true) return;
    try {
      await context.read<AdminApiClient>().archiveAdCampaign(campaign['id']);
      _refresh();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de l’opération : $error'), backgroundColor: Colors.red),
      );

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: Text('Impossible de charger les campagnes : ${snapshot.error}'),
              ),
            );
          }
          final payload = snapshot.data!;
          final campaigns = List<Map<String, dynamic>>.from(payload['campaigns'] as List? ?? const []);
          final analytics = Map<String, dynamic>.from(payload['analytics'] as Map? ?? const {});
          final metrics = Map<String, dynamic>.from(analytics['metrics'] as Map? ?? const {});
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(builder: (context, constraints) {
                  final controlWidth = constraints.maxWidth > 560 ? 360.0 : constraints.maxWidth;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: controlWidth,
                            child: Text('Régie publicitaire', style: AppTheme.textTitle.copyWith(fontSize: 24)),
                          ),
                          OutlinedButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Actualiser')),
                          FilledButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: const Text('Nouvelle campagne')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          SizedBox(
                            width: controlWidth,
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (value) => setState(() {
                                _search = value.trim();
                                _data = _load();
                              }),
                              decoration: InputDecoration(
                                labelText: 'Rechercher une campagne ou un annonceur',
                                prefixIcon: const Icon(Icons.search),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  tooltip: 'Effacer la recherche',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _search = '';
                                      _data = _load();
                                    });
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: constraints.maxWidth > 560 ? 190 : constraints.maxWidth,
                            child: DropdownButtonFormField<String>(
                              value: _statusFilter ?? 'all',
                              decoration: const InputDecoration(labelText: 'État', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('Tous les états')),
                                DropdownMenuItem(value: 'draft', child: Text('Brouillon')),
                                DropdownMenuItem(value: 'active', child: Text('Active')),
                                DropdownMenuItem(value: 'paused', child: Text('En pause')),
                                DropdownMenuItem(value: 'archived', child: Text('Archivée')),
                              ],
                              onChanged: (value) => setState(() {
                                _statusFilter = value == null || value == 'all' ? null : value;
                                _data = _load();
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 10),
                _SsaIStatus(configured: metrics['ssai_configured'] == true),
                const SizedBox(height: 10),
                LayoutBuilder(builder: (context, constraints) {
                  final cards = [
                    _MetricCard('Actives', metrics['active_campaigns'], Icons.campaign_outlined),
                    _MetricCard('Demandes', metrics['requests'], Icons.send_outlined),
                    _MetricCard('Impressions', metrics['impressions'], Icons.visibility_outlined),
                    _MetricCard('Remplissage', '${metrics['fill_rate_percent'] ?? 0} %', Icons.bar_chart),
                    _MetricCard('Complétion', '${metrics['completion_rate_percent'] ?? 0} %', Icons.task_alt),
                    _MetricCard('CTR', '${metrics['click_through_rate_percent'] ?? 0} %', Icons.ads_click),
                  ];
                  final count = constraints.maxWidth > 1100 ? 6 : constraints.maxWidth > 720 ? 3 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cards.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: count,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.8,
                    ),
                    itemBuilder: (_, index) => cards[index],
                  );
                }),
                const SizedBox(height: 12),
                Expanded(
                  child: campaigns.isEmpty
                      ? const Center(child: Text('Aucune campagne. Créez un brouillon pour configurer vos annonces.'))
                      : LayoutBuilder(builder: (context, constraints) {
                          if (constraints.maxWidth < 720) {
                            return ListView.separated(
                              itemCount: campaigns.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, index) => _CampaignCard(
                                campaign: campaigns[index],
                                onEdit: () => _edit(campaigns[index]),
                                onStatus: (status) => _setStatus(campaigns[index], status),
                                onArchive: () => _archive(campaigns[index]),
                              ),
                            );
                          }
                          return SingleChildScrollView(
                            child: Card(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Campagne')),
                                    DataColumn(label: Text('Format')),
                                    DataColumn(label: Text('Ciblage')),
                                    DataColumn(label: Text('Diffusion')),
                                    DataColumn(label: Text('État')),
                                    DataColumn(label: Text('Actions')),
                                  ],
                                  rows: campaigns.map((campaign) {
                                    final formats = (campaign['formats'] as List? ?? const []).join(', ');
                                    final targeting = [
                                      if ((campaign['target_countries'] as List? ?? const []).isNotEmpty)
                                        (campaign['target_countries'] as List).join(', '),
                                      if ((campaign['contextual_genres'] as List? ?? const []).isNotEmpty)
                                        'genres ${(campaign['contextual_genres'] as List).join(', ')}',
                                      if ((campaign['interest_tags'] as List? ?? const []).isNotEmpty)
                                        'habitudes avec consentement',
                                    ].join(' · ');
                                    return DataRow(cells: [
                                      DataCell(SizedBox(width: 190, child: Text(campaign['name']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis))),
                                      DataCell(Text(formats.isEmpty ? '—' : formats)),
                                      DataCell(SizedBox(width: 230, child: Text(targeting.isEmpty ? 'Tous les publics' : targeting, maxLines: 2, overflow: TextOverflow.ellipsis))),
                                      DataCell(Text(campaign['delivery_mode'] == 'ssai' ? 'SSAI' : 'Lecteur')),
                                      DataCell(_StatusChip(status: campaign['status']?.toString() ?? 'draft')),
                                      DataCell(_Actions(
                                        status: campaign['status']?.toString() ?? 'draft',
                                        onEdit: () => _edit(campaign),
                                        onStatus: (value) => _setStatus(campaign, value),
                                        onArchive: () => _archive(campaign),
                                      )),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        }),
                ),
              ],
            ),
          );
        },
      );
}

class _SsaIStatus extends StatelessWidget {
  const _SsaIStatus({required this.configured});
  final bool configured;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: configured ? Colors.green.withOpacity(.12) : Colors.orange.withOpacity(.12),
        ),
        child: Row(children: [
          Icon(configured ? Icons.check_circle_outline : Icons.info_outline, color: configured ? Colors.green : Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              configured
                  ? 'SSAI raccordé. Les manifests stitchés sont remis au lecteur avec la licence DRM.'
                  : 'SSAI non raccordé : renseignez le fournisseur côté serveur avant d’activer les campagnes en insertion serveur.',
              style: AppTheme.textBody,
            ),
          ),
        ]),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, this.icon);
  final String label;
  final dynamic value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(height: 4),
            Text('${value ?? 0}', style: AppTheme.textTitle.copyWith(fontSize: 20)),
            Text(label, style: AppTheme.textCaption),
          ]),
        ),
      );
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.campaign, required this.onEdit, required this.onStatus, required this.onArchive});
  final Map<String, dynamic> campaign;
  final VoidCallback onEdit;
  final ValueChanged<String> onStatus;
  final VoidCallback onArchive;
  @override
  Widget build(BuildContext context) {
    final formats = (campaign['formats'] as List? ?? const []).join(', ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(campaign['name']?.toString() ?? '', style: AppTheme.textSubtitle)),
            _StatusChip(status: campaign['status']?.toString() ?? 'draft'),
          ]),
          Text('${campaign['advertiser'] ?? ''}', style: AppTheme.textCaption),
          const SizedBox(height: 8),
          Text('Formats : $formats'),
          Text('Mode : ${campaign['delivery_mode'] == 'ssai' ? 'SSAI' : 'lecteur'}'),
          Text('Pays : ${(campaign['target_countries'] as List? ?? const []).join(', ').isEmpty ? 'Tous' : (campaign['target_countries'] as List).join(', ')}'),
          const SizedBox(height: 8),
          _Actions(status: campaign['status']?.toString() ?? 'draft', onEdit: onEdit, onStatus: onStatus, onArchive: onArchive),
        ]),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'active' => Colors.green,
      'paused' => Colors.orange,
      'archived' => Colors.grey,
      _ => Colors.blueGrey,
    };
    return Chip(label: Text(status), backgroundColor: color.withOpacity(.16), side: BorderSide.none);
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.status, required this.onEdit, required this.onStatus, required this.onArchive});
  final String status;
  final VoidCallback onEdit;
  final ValueChanged<String> onStatus;
  final VoidCallback onArchive;
  @override
  Widget build(BuildContext context) => Wrap(spacing: 2, children: [
        IconButton(
          tooltip: 'Modifier',
          onPressed: status == 'archived' ? null : onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        if (status == 'active')
          IconButton(tooltip: 'Mettre en pause', onPressed: () => onStatus('paused'), icon: const Icon(Icons.pause_circle_outline))
        else if (status != 'archived')
          IconButton(tooltip: 'Activer', onPressed: () => onStatus('active'), icon: const Icon(Icons.play_circle_outline)),
        if (status != 'archived')
          IconButton(tooltip: 'Archiver', onPressed: onArchive, icon: const Icon(Icons.archive_outlined)),
      ]);
}

class _CampaignEditor extends StatefulWidget {
  const _CampaignEditor({this.campaign});
  final Map<String, dynamic>? campaign;

  @override
  State<_CampaignEditor> createState() => _CampaignEditorState();
}

class _CampaignEditorState extends State<_CampaignEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _advertiser;
  late final TextEditingController _media;
  late final TextEditingController _vast;
  late final TextEditingController _image;
  late final TextEditingController _ctaLabel;
  late final TextEditingController _cta;
  late final TextEditingController _countries;
  late final TextEditingController _genres;
  late final TextEditingController _interests;
  late final TextEditingController _cues;
  late final TextEditingController _ageMin;
  late final TextEditingController _ageMax;
  late final TextEditingController _contentIds;
  late final TextEditingController _duration;
  late final TextEditingController _activeFrom;
  late final TextEditingController _activeUntil;
  late final TextEditingController _skipAfter;
  late final TextEditingController _frequency;
  late final TextEditingController _priority;
  late final Set<String> _formats;
  late String _delivery;
  late String _status;

  @override
  void initState() {
    super.initState();
    final data = widget.campaign ?? const <String, dynamic>{};
    _name = TextEditingController(text: data['name']?.toString() ?? '');
    _advertiser = TextEditingController(text: data['advertiser']?.toString() ?? '');
    _media = TextEditingController(text: data['media_url']?.toString() ?? '');
    _vast = TextEditingController(text: data['vast_tag_url']?.toString() ?? '');
    _image = TextEditingController(text: data['image_url']?.toString() ?? '');
    _ctaLabel = TextEditingController(text: data['cta_label']?.toString() ?? '');
    _cta = TextEditingController(text: data['cta_url']?.toString() ?? '');
    _countries = TextEditingController(text: _join(data['target_countries']));
    _genres = TextEditingController(text: _join(data['contextual_genres']));
    _interests = TextEditingController(text: _join(data['interest_tags']));
    _cues = TextEditingController(text: _join(data['cue_points_seconds']));
    _ageMin = TextEditingController(text: data['target_age_min']?.toString() ?? '');
    _ageMax = TextEditingController(text: data['target_age_max']?.toString() ?? '');
    _contentIds = TextEditingController(text: _join(data['content_ids']));
    _duration = TextEditingController(text: data['media_duration_seconds']?.toString() ?? '');
    _activeFrom = TextEditingController(text: _localDateTime(data['active_from']));
    _activeUntil = TextEditingController(text: _localDateTime(data['active_until']));
    _skipAfter = TextEditingController(text: data['skip_after_seconds']?.toString() ?? '');
    _frequency = TextEditingController(text: data['frequency_cap_per_day']?.toString() ?? '3');
    _priority = TextEditingController(text: data['priority']?.toString() ?? '0');
    _formats = Set<String>.from((data['formats'] as List? ?? const ['preroll']).map((e) => e.toString()));
    _delivery = data['delivery_mode']?.toString() ?? 'client_side';
    _status = data['status']?.toString() ?? 'draft';
  }

  String _join(dynamic value) => value is List ? value.join(', ') : '';

  List<String> _csv(String value) => value.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();

  List<int> _ints(String value) => _csv(value).map(int.parse).toSet().toList()..sort();

  int? _optionalInt(String value) => value.trim().isEmpty ? null : int.tryParse(value.trim());

  String _localDateTime(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '';
    final parsed = DateTime.tryParse(value.toString());
    return parsed == null ? '' : parsed.toLocal().toIso8601String().substring(0, 19);
  }

  String? _utcDateTime(String value) {
    if (value.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null) throw const FormatException('La date doit être au format AAAA-MM-JJTHH:MM:SS.');
    return parsed.toUtc().toIso8601String();
  }

  Map<String, dynamic> _payload() => {
        'name': _name.text.trim(),
        'advertiser': _advertiser.text.trim(),
        'status': _status,
        'delivery_mode': _delivery,
        'formats': _formats.toList(),
        'media_url': _media.text.trim(),
        'vast_tag_url': _vast.text.trim(),
        'image_url': _image.text.trim(),
        'media_duration_seconds': int.tryParse(_duration.text) ?? 0,
        'active_from': _utcDateTime(_activeFrom.text),
        'active_until': _utcDateTime(_activeUntil.text),
        'cta_label': _ctaLabel.text.trim(),
        'cta_url': _cta.text.trim(),
        'target_countries': _csv(_countries.text).map((e) => e.toUpperCase()).toList(),
        'contextual_genres': _csv(_genres.text),
        'interest_tags': _csv(_interests.text),
        'target_age_min': _optionalInt(_ageMin.text),
        'target_age_max': _optionalInt(_ageMax.text),
        'content_ids': _ints(_contentIds.text),
        'cue_points_seconds': _ints(_cues.text),
        'frequency_cap_per_day': int.tryParse(_frequency.text) ?? 3,
        'priority': int.tryParse(_priority.text) ?? 0,
        'skip_after_seconds': _optionalInt(_skipAfter.text),
      };

  @override
  void dispose() {
    for (final field in [
      _name, _advertiser, _media, _vast, _image, _ctaLabel, _cta, _countries,
      _genres, _interests, _cues, _ageMin, _ageMax, _contentIds, _duration,
      _activeFrom, _activeUntil, _skipAfter, _frequency, _priority,
    ]) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.campaign == null ? 'Créer une campagne' : 'Modifier la campagne'),
        content: SizedBox(
          width: 680,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(_name, 'Nom de campagne', required: true),
                  _field(_advertiser, 'Annonceur'),
                  DropdownButtonFormField<String>(
                    value: _delivery,
                    decoration: const InputDecoration(labelText: 'Insertion', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'client_side', child: Text('Côté lecteur')),
                      DropdownMenuItem(value: 'ssai', child: Text('SSAI côté serveur')),
                    ],
                    onChanged: (value) => setState(() {
                      _delivery = value ?? 'client_side';
                      if (_delivery == 'ssai') _formats.remove('pause');
                    }),
                  ),
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerLeft, child: Text('Placements', style: AppTheme.textBodyBold)),
                  Wrap(
                    spacing: 6,
                    children: [
                      _formatChip('preroll', 'Pré-roll'),
                      _formatChip('midroll', 'Mid-roll'),
                      _formatChip('pause', 'Sur pause'),
                    ],
                  ),
                  _field(_media, 'URL vidéo HTTPS (requise pour pré-roll et mid-roll côté lecteur)'),
                  _field(_vast, 'URL VAST HTTPS (création SSAI)'),
                  _field(_image, 'URL visuel HTTPS (publicité sur pause)'),
                  _field(_duration, 'Durée vidéo en secondes', keyboardType: TextInputType.number),
                  _field(_cues, 'Repères mid-roll en secondes (ex. 600, 1200)'),
                  Row(children: [
                    Expanded(child: _field(_activeFrom, 'Début de diffusion (heure locale)', keyboardType: TextInputType.datetime)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(_activeUntil, 'Fin de diffusion (heure locale)', keyboardType: TextInputType.datetime)),
                  ]),
                  const Text('Saisissez AAAA-MM-JJTHH:MM:SS, ou laissez vide. Les campagnes SSAI ne gèrent pas les publicités sur pause.', style: TextStyle(fontSize: 12)),
                  _field(_countries, 'Pays ISO (ex. CI, CM, FR)'),
                  _field(_genres, 'Genres contextuels (ex. drame, comédie)'),
                  _field(_interests, 'Centres d’intérêt du profil (consentement requis)'),
                  Row(children: [
                    Expanded(child: _field(_ageMin, 'Âge adulte min.', keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(_ageMax, 'Âge max.', keyboardType: TextInputType.number)),
                  ]),
                  _field(_contentIds, 'ID de contenus ciblés (séparés par des virgules, vide = tous)'),
                  Row(children: [
                    Expanded(child: _field(_frequency, 'Max. impressions / jour', keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(_priority, 'Priorité', keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: _field(_skipAfter, 'Délai avant ignorer', keyboardType: TextInputType.number)),
                  ]),
                  _field(_ctaLabel, 'Texte du bouton interactif'),
                  _field(_cta, 'Lien interactif HTTPS (achat, détail ou QR/deep link)'),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'État', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'draft', child: Text('Brouillon')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'paused', child: Text('En pause')),
                    ],
                    onChanged: (value) => setState(() => _status = value ?? 'draft'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Les habitudes et l’âge sont utilisés uniquement pour les profils adultes ayant activé la personnalisation. Les repères mid-roll sont définis manuellement aux transitions souhaitées.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              try {
                if (_formats.isEmpty) throw const FormatException('Choisissez au moins un placement.');
                final payload = _payload();
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(context, payload);
              } on FormatException catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      );

  Widget _formatChip(String value, String label) => FilterChip(
        label: Text(label),
        selected: _formats.contains(value),
        onSelected: _delivery == 'ssai' && value == 'pause'
            ? null
            : (selected) => setState(() {
          if (selected) {
            _formats.add(value);
          } else {
            _formats.remove(value);
          }
        }),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboardType,
  }) =>
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          validator: required
              ? (value) => value == null || value.trim().isEmpty ? 'Champ obligatoire.' : null
              : null,
        ),
      );
}
