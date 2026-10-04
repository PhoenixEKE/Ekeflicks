import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:app_ekeflicks/core/app_responsive.dart';
import 'package:provider/provider.dart';

import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:app_ekeflicks/models/eke_ai_models.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';
import 'package:app_ekeflicks/services/eke_ai_service.dart';
import 'package:app_ekeflicks/ui/salons/ekeroom_page.dart';

class EkeAISearchPage extends StatefulWidget {
  final String? initialQuery;

  const EkeAISearchPage({super.key, this.initialQuery});

  @override
  State<EkeAISearchPage> createState() => _EkeAISearchPageState();
}

class _EkeAISearchPageState extends State<EkeAISearchPage> {
  late final TextEditingController _controller;

  bool _loading = false;
  String? _error;
  List<EkeAIContent> _results = const [];
  List<Map<String, dynamic>> _salons = const [];
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _scope = 'catalogue';
  String _audioLanguage = 'any';
  String _subtitleLanguage = 'any';
  bool _listening = false;

  bool get _english =>
      Localizations.localeOf(context).languageCode == 'en';

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialQuery ?? '');

    if (_controller.text.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _speech.stop();
    super.dispose();
  }

  EkeAIService _service() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return EkeAIService(userProvider.apiClient.dio);
  }

  Future<void> _search() async {
    final query = _controller.text.trim();

    if (query.isEmpty || _loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_scope == 'salons') {
        final salons = await _service().searchSalons(query);
        if (!mounted) return;
        setState(() {
          _salons = salons;
          _results = const [];
        });
      } else {
        final response = await _service().search(
          query,
          limit: 30,
          language: _english ? 'en' : 'fr',
          audioLanguage: _audioLanguage,
          subtitleLanguage: _subtitleLanguage,
        );

        if (!mounted) return;
        setState(() {
          _results = response.items;
          _salons = const [];
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _results = const [];
        _salons = const [];
        _error = _english
            ? 'EKE AI search is temporarily unavailable.'
            : 'La recherche EKE IA est momentanément indisponible.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _listen() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' && mounted) {
          setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!available || !mounted) return;
    setState(() => _listening = true);
    await _speech.listen(
      localeId: _english ? 'en_US' : 'fr_FR',
      onResult: (result) {
        if (!mounted) return;
        setState(() => _controller.text = result.recognizedWords);
        if (result.finalResult) {
          setState(() => _listening = false);
          _search();
        }
      },
    );
  }

  Future<void> _explain(EkeAIContent content) async {
    if (content.id.isEmpty) return;

    try {
      final result = await _service().explain(content.id);

      if (!mounted) return;

      final text =
          result.explanation?.trim().isNotEmpty == true
              ? result.explanation!.trim()
              : content.reason?.trim();

      showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Pourquoi ce contenu ?'),
              content: Text(
                text == null || text.isEmpty
                    ? 'EKE IA ne dispose pas encore '
                        'd’une explication pour ce contenu.'
                    : text,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ],
            ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Explication indisponible.')),
      );
    }
  }

  Widget _poster(EkeAIContent content) {
    final url = content.posterUrl;

    if (url == null || url.isEmpty) {
      return Container(
        color: Colors.black26,
        alignment: Alignment.center,
        child: const Icon(Icons.movie_outlined, size: 42),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder:
          (_, _, _) => Container(
            color: Colors.black26,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined, size: 42),
          ),
    );
  }

  Widget _salonCard(Map<String, dynamic> salon) {
    final title = (salon['name'] ?? 'Ekeroom').toString();
    final contentTitle = salon['content_title']?.toString();
    final count = (salon['member_count'] as num?)?.toInt() ?? 0;
    final id = salon['id']?.toString() ?? '';
    final scheduled = salon['scheduled_at']?.toString();
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.groups_outlined)),
        title: Text(title),
        subtitle: Text([
          if (contentTitle != null && contentTitle.isNotEmpty) contentTitle,
          _english ? '$count watching' : '$count participant(s)',
          if (scheduled != null && scheduled.isNotEmpty)
            (_english ? 'Scheduled: ' : 'Programmé : ') + scheduled,
        ].join(' · ')),
        trailing: FilledButton(
          onPressed: id.isEmpty
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => EkeroomPage(initialSalonId: id),
                    ),
                  ),
          child: Text(_english ? 'Join' : 'Rejoindre'),
        ),
      ),
    );
  }

  Widget _resultCard(EkeAIContent content) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _explain(content),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 105, height: 150, child: _poster(content)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title.isEmpty
                          ? 'Contenu EKEFLICKS'
                          : content.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (content.contentType?.isNotEmpty == true) ...[
                      const SizedBox(height: 5),
                      Text(
                        content.contentType!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (content.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        content.description!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed:
                          content.id.isEmpty ? null : () => _explain(content),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Pourquoi ce contenu ?'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_english ? 'EKE AI search' : 'Recherche EKE IA'),
        actions: [
          IconButton(
            tooltip: 'Ekeroom',
            onPressed: () => Navigator.pushNamed(context, '/ekeroom'),
            icon: const Icon(Icons.groups_outlined),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.pageDecoration(context),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: AppResponsive.isTVSize(context) ? 1400 : 1000),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(_english ? 'Films and series' : 'Films et séries'),
                          selected: _scope == 'catalogue',
                          onSelected: (_) => setState(() => _scope = 'catalogue'),
                        ),
                        ChoiceChip(
                          label: Text(_english ? 'Ekerooms' : 'Salons Ekeroom'),
                          selected: _scope == 'salons',
                          onSelected: (_) => setState(() => _scope = 'salons'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: InputDecoration(
                        hintText: _scope == 'salons'
                            ? (_english ? 'Search a room or a film title...' : 'Rechercher un salon ou un film...')
                            : (_english
                                ? 'Search for a film, series or genre...'
                                : 'Demandez à EKE IA un film, une série, un genre...'),
                        prefixIcon: const Icon(Icons.auto_awesome),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: _english ? 'Speak your search' : 'Dicter la recherche',
                              onPressed: _loading ? null : _listen,
                              icon: Icon(_listening ? Icons.mic : Icons.mic_none),
                            ),
                            IconButton(
                              tooltip: _english ? 'Search' : 'Rechercher',
                              onPressed: _loading ? null : _search,
                              icon: const Icon(Icons.search),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_scope == 'catalogue') ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _audioLanguage,
                              decoration: InputDecoration(
                                labelText: _english ? 'Audio language' : 'Langue audio',
                                isDense: true,
                              ),
                              items: [
                                DropdownMenuItem(value: 'any', child: Text(_english ? 'Any' : 'Toutes')),
                                const DropdownMenuItem(value: 'fr', child: Text('Français')),
                                const DropdownMenuItem(value: 'en', child: Text('English')),
                              ],
                              onChanged: (value) => setState(() => _audioLanguage = value ?? 'any'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _subtitleLanguage,
                              decoration: InputDecoration(
                                labelText: _english ? 'Subtitles' : 'Sous-titres',
                                isDense: true,
                              ),
                              items: [
                                DropdownMenuItem(value: 'any', child: Text(_english ? 'Any' : 'Tous')),
                                const DropdownMenuItem(value: 'fr', child: Text('Français')),
                                const DropdownMenuItem(value: 'en', child: Text('English')),
                              ],
                              onChanged: (value) => setState(() => _subtitleLanguage = value ?? 'any'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_loading) const LinearProgressIndicator(),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 8),
                    Expanded(
                      child:
                          _scope == 'salons'
                              ? (_salons.isEmpty && !_loading && _error == null
                                  ? Center(
                                      child: Text(
                                        _english ? 'Search for a room to join.' : 'Recherchez un salon à rejoindre.',
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: _salons.length,
                                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                                      itemBuilder: (context, index) => _salonCard(_salons[index]),
                                    ))
                              : (_results.isEmpty && !_loading && _error == null
                                  ? Center(
                                      child: Text(
                                        _english ? 'What would you like to watch?' : 'Que souhaitez-vous regarder ?',
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: _results.length,
                                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                                      itemBuilder: (context, index) => _resultCard(_results[index]),
                                    )),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
