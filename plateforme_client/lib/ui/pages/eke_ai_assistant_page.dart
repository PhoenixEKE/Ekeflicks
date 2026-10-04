import 'package:flutter/material.dart';
import 'package:app_ekeflicks/core/app_responsive.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:app_ekeflicks/models/eke_ai_models.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';
import 'package:app_ekeflicks/services/eke_ai_service.dart';
import 'package:app_ekeflicks/widgets/eke_ai/eke_ai_widgets.dart';

class EkeAIAssistantPage extends StatefulWidget {
  const EkeAIAssistantPage({super.key});

  @override
  State<EkeAIAssistantPage> createState() => _EkeAIAssistantPageState();
}

class _AssistantMessage {
  final bool fromUser;
  final String text;

  const _AssistantMessage({required this.fromUser, required this.text});
}

class _EkeAIAssistantPageState extends State<EkeAIAssistantPage> {
  final TextEditingController _controller = TextEditingController();

  final List<_AssistantMessage> _messages =
      const [
        _AssistantMessage(
          fromUser: false,
          text:
              'Bonjour, je suis EKE IA. '
              'Je peux vous aider à trouver un contenu disponible sur EKEFLICKS.',
        ),
      ].toList();

  List<EkeAIContent> _recommendations = const [];
  bool _loading = false;
  bool _listening = false;
  bool _greetingSet = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  String _occasion = '';
  String _audioLanguage = 'any';
  String _subtitleLanguage = 'any';

  bool get _english =>
      Localizations.localeOf(context).languageCode == 'en';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_greetingSet) return;
    _greetingSet = true;
    _messages[0] = _AssistantMessage(
      fromUser: false,
      text: _english
          ? 'Hello, I’m EKE AI. I can find available films and series, recommend something for your evening, or help you find an Ekeroom.'
          : 'Bonjour, je suis EKE AI. Je peux trouver des films et séries disponibles, vous conseiller pour votre soirée ou rechercher un Ekeroom.',
    );
  }

  EkeAIService _service() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return EkeAIService(userProvider.apiClient.dio);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add(_AssistantMessage(fromUser: true, text: text));
      _controller.clear();
      _loading = true;
    });

    try {
      final response = await _service().chat(
        text,
        limit: 10,
        language: _english ? 'en' : 'fr',
        occasion: _occasion.isEmpty ? null : _occasion,
        audioLanguage: _audioLanguage,
        subtitleLanguage: _subtitleLanguage,
      );

      if (!mounted) return;

      final answer =
          response.message?.trim().isNotEmpty == true
              ? response.message!.trim()
              : response.items.isEmpty
              ? (_english
                  ? 'I could not find available content matching that request.'
                  : 'Je n’ai pas trouvé de contenu disponible correspondant.')
              : (_english
                  ? 'Here is a selection available on EKEFLICKS.'
                  : 'Voici une sélection disponible sur EKEFLICKS.');

      setState(() {
        _messages.add(_AssistantMessage(fromUser: false, text: answer));
        _recommendations = response.items;
      });
      try {
        await _tts.setLanguage(_english ? 'en-US' : 'fr-FR');
        await _tts.speak(answer);
      } catch (_) {
        // Voice output is optional; the written response remains available.
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _messages.add(
          const _AssistantMessage(
            fromUser: false,
            text: _english
                ? 'I’m temporarily unavailable. Please try again shortly.'
                : 'Je suis momentanément indisponible. Réessayez dans quelques instants.',
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _feedback(EkeAIContent content, String action) async {
    if (content.id.isEmpty) return;

    try {
      await _service().feedback(contentId: content.id, action: action);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Préférence enregistrée.')));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action momentanément indisponible.')),
      );
    }
  }

  Future<void> _explain(EkeAIContent content) async {
    if (content.id.isEmpty) return;

    try {
      final result = await _service().explain(content.id);

      if (!mounted) return;

      final explanation =
          result.explanation?.trim().isNotEmpty == true
              ? result.explanation!.trim()
              : content.reason?.trim();

      showDialog<void>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Pourquoi ce contenu ?'),
              content: Text(
                explanation == null || explanation.isEmpty
                    ? 'EKE IA ne dispose pas encore '
                        'd’une explication pour ce contenu.'
                    : explanation,
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
    if (!available || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_english
              ? 'Voice input is unavailable on this device.'
              : 'La saisie vocale est indisponible sur cet appareil.'),
        ),
      );
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      localeId: _english ? 'en_US' : 'fr_FR',
      onResult: (result) {
        if (!mounted) return;
        setState(() => _controller.text = result.recognizedWords);
        if (result.finalResult) {
          setState(() => _listening = false);
          _send();
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) setState(() => _listening = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome),
            const SizedBox(width: 8),
            Text(_english ? 'EKE AI assistant' : 'Assistant EKE IA'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _english ? 'Search catalogue and rooms' : 'Rechercher films et salons',
            onPressed: () => Navigator.pushNamed(context, '/eke-ai-search'),
            icon: const Icon(Icons.search),
          ),
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
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final message in _messages)
                          Align(
                            alignment:
                                message.fromUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(maxWidth: AppResponsive.isTVSize(context) ? 980 : 650),
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    message.fromUser
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer
                                        : Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(message.text),
                            ),
                          ),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: LinearProgressIndicator(),
                          ),
                        if (_recommendations.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            _english ? 'EKE AI picks' : 'Sélection EKE IA',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 360,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _recommendations.length,
                              separatorBuilder:
                                  (_, _) => const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final content = _recommendations[index];

                                return EkeAIContentCard(
                                  content: content,
                                  onExplain: () => _explain(content),
                                  onLike: () => _feedback(content, 'like'),
                                  onFavorite:
                                      () => _feedback(content, 'favorite'),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text(_english ? 'Any evening' : 'Tous types de soirée'),
                              selected: _occasion.isEmpty,
                              onSelected: (_) => setState(() => _occasion = ''),
                            ),
                            ChoiceChip(
                              label: Text(_english ? 'Family' : 'Familiale'),
                              selected: _occasion == 'family',
                              onSelected: (_) => setState(() => _occasion = 'family'),
                            ),
                            ChoiceChip(
                              label: Text(_english ? 'Romantic' : 'Romantique'),
                              selected: _occasion == 'romantic',
                              onSelected: (_) => setState(() => _occasion = 'romantic'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _audioLanguage,
                                decoration: const InputDecoration(
                                  labelText: 'Audio',
                                  isDense: true,
                                ),
                                items: [
                                  DropdownMenuItem(value: 'any', child: Text(_english ? 'Any audio' : 'Tous les audios')),
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
                                  DropdownMenuItem(value: 'any', child: Text(_english ? 'Any subtitles' : 'Tous les sous-titres')),
                                  const DropdownMenuItem(value: 'fr', child: Text('Français')),
                                  const DropdownMenuItem(value: 'en', child: Text('English')),
                                ],
                                onChanged: (value) => setState(() => _subtitleLanguage = value ?? 'any'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              hintText: _english
                                  ? 'e.g. A family comedy for tonight...'
                                  : 'Ex. une comédie africaine pour ce soir...',
                              prefixIcon: const Icon(Icons.auto_awesome_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: _listening
                              ? (_english ? 'Stop voice input' : 'Arrêter la voix')
                              : (_english ? 'Speak' : 'Parler'),
                          onPressed: _loading
                              ? null
                              : (_listening ? _stopListening : _listen),
                          icon: Icon(_listening ? Icons.mic : Icons.mic_none),
                        ),
                        IconButton.filled(
                          tooltip: _english ? 'Send' : 'Envoyer',
                          onPressed: _loading ? null : _send,
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
