import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:plateforme_producteurs/services/producer_service.dart';
import 'package:plateforme_producteurs/widgets/producer_page_shell.dart';
import 'eke_web_speech_stub.dart'
    if (dart.library.js_interop) 'eke_web_speech_web.dart' as web_speech;

class ProducerEkePage extends StatefulWidget {
  const ProducerEkePage({super.key});

  @override
  State<ProducerEkePage> createState() => _ProducerEkePageState();
}

class _ProducerEkePageState extends State<ProducerEkePage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _speech = stt.SpeechToText();
  final _tts = FlutterTts();
  final List<_EkeMessage> _messages = [];
  bool _busy = false;
  bool _listening = false;
  bool _speechReady = false;
  bool _greeted = false;
  bool _microphoneAllowed = false;
  String _voiceGender = 'female';

  bool get _english => Localizations.localeOf(context).languageCode == 'en';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final values = await ProducerService.instance.getProducerPrivacyPreferences();
      if (!mounted) return;
      setState(() {
        _microphoneAllowed = values['microphone_enabled'] == true;
        _voiceGender = values['eke_voice_gender'] == 'male' ? 'male' : 'female';
      });
    } catch (_) {
      // Permissions remain off when the preference service is unavailable.
    }
  }

  Future<void> _setVoiceGender(String gender) async {
    setState(() => _voiceGender = gender);
    try {
      await ProducerService.instance.updateProducerPrivacyPreferences({'eke_voice_gender': gender});
    } catch (error) {
      if (!mounted) return;
      _showInfo(error.toString());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_greeted) return;
    _greeted = true;
    _messages.add(_EkeMessage(
      text: _english
          ? 'Hello, I’m Eke, your producer assistant. I can explain published portal documents and your content statistics, and answer from verified help articles. Ask me by typing or using the microphone.'
          : 'Bonjour, je suis Eke, votre assistant producteur. Je peux expliquer les documents publiés du portail et vos statistiques de contenu, et répondre à partir des articles d’aide vérifiés. Écrivez votre question ou utilisez le microphone.',
      fromEke: true,
    ));
  }

  Future<void> _initSpeech() async {
    try {
      final ready = await _speech.initialize(
        onStatus: (value) {
          if (mounted) setState(() => _listening = value == 'listening');
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
      if (mounted) setState(() => _speechReady = ready);
    } catch (_) {
      if (mounted) setState(() => _speechReady = false);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      return;
    }
    if (!_microphoneAllowed) {
      _showInfo(_english
          ? 'Enable microphone use in My Account before dictating to Eke.'
          : 'Activez le micro dans Mon compte avant de dicter à Eke.');
      return;
    }
    if (!_speechReady) await _initSpeech();
    if (!_speechReady) {
      _showInfo(_english
          ? 'Voice input is unavailable in this browser or permission was denied.'
          : 'La saisie vocale n’est pas disponible dans ce navigateur ou l’autorisation du micro a été refusée.');
      return;
    }
    await _speech.listen(
      localeId: _english ? 'en-US' : 'fr-FR',
      listenFor: const Duration(seconds: 25),
      onResult: (result) {
        if (mounted) setState(() { _input.text = result.recognizedWords; });
      },
    );
  }

  Future<void> _send() async {
    final question = _input.text.trim();
    if (question.isEmpty || _busy) return;
    setState(() {
      _messages.add(_EkeMessage(text: question, fromEke: false));
      _input.clear();
      _busy = true;
    });
    _scrollToBottom();
    try {
      final response = await ProducerService.instance.askEkeProducer(question);
      if (!mounted) return;
      final sources = (response['matches'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => row['question']?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .toList();
      setState(() => _messages.add(_EkeMessage(
        text: response['reply']?.toString() ?? '',
        fromEke: true,
        sources: sources,
        needsSupport: response['needs_support'] == true,
      )));
    } catch (error) {
      if (mounted) setState(() => _messages.add(_EkeMessage(
        text: _english
            ? 'I could not reach the help service. Please retry or open Support.'
            : 'Je n’arrive pas à joindre le service d’aide. Réessayez ou ouvrez Support.',
        fromEke: true,
        needsSupport: true,
      )));
    } finally {
      if (mounted) setState(() => _busy = false);
      _scrollToBottom();
    }
  }

  Future<void> _speak(String text) async {
    try {
      final language = _english ? 'en-US' : 'fr-FR';
      if (kIsWeb) {
        final found = await web_speech.speakWithGender(text, language, _voiceGender);
        if (!found) _showInfo(_english
            ? 'Your browser does not provide a voice of the selected gender in this language.'
            : 'Votre navigateur ne propose pas de voix du genre choisi dans cette langue.');
      } else {
        await _tts.setLanguage(language);
        final dynamic rawVoices = await _tts.getVoices;
        final voices = rawVoices is List ? rawVoices.whereType<Map>().toList() : <Map>[];
        bool matches(Map voice) {
          final gender = voice['gender']?.toString().toLowerCase() ?? '';
          final name = voice['name']?.toString().toLowerCase() ?? '';
          final target = _voiceGender == 'female' ? 'female' : 'male';
          final normalizedGender = gender.trim();
          if (normalizedGender == target ||
              (target == 'male' && normalizedGender.startsWith('male') && !normalizedGender.contains('female'))) {
            return true;
          }
          if (_voiceGender == 'female') return ['female', 'femme', 'woman', 'samantha', 'karen', 'amelie', 'julie', 'zira'].any(name.contains) && !name.contains('male');
          return !name.contains('female') &&
              ['male', 'homme', 'man', 'thomas', 'daniel', 'paul', 'nicolas', 'antoine', 'henri'].any(name.contains);
        }
        Map? selected;
        for (final voice in voices) {
          if (matches(voice)) { selected = voice; break; }
        }
        if (selected == null) {
          _showInfo(_english ? 'No voice of the selected gender is installed.' : 'Aucune voix du genre choisi n’est installée.');
          return;
        }
        await _tts.setVoice({'name': selected['name'].toString(), 'locale': selected['locale'].toString()});
        await _tts.speak(text);
      }
    } catch (_) {
      _showInfo(_english ? 'Speech playback is unavailable on this device.' : 'La lecture vocale n’est pas disponible sur cet appareil.');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    });
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _english;
    return ProducerPageShell(
      title: 'Eke',
      showBack: true,
      maxWidth: 920,
      contentDecoration: true,
      child: SizedBox(
        height: (MediaQuery.sizeOf(context).height - 190).clamp(280.0, 1200.0).toDouble(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(
            spacing: 4,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: (MediaQuery.sizeOf(context).width * .62).clamp(190.0, 560.0),
                child: Row(children: [
                  const CircleAvatar(child: Icon(Icons.support_agent_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l10n ? 'Eke · Producer assistant' : 'Eke · Assistant producteur', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                    Text(l10n ? 'Portal documents · your analytics · verified help' : 'Documents · vos statistiques · aide vérifiée', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                  ])),
                ]),
              ),
              IconButton(
                tooltip: l10n ? 'My Account' : 'Mon compte',
                onPressed: () => context.push('/profile'),
                icon: const Icon(Icons.account_circle_outlined),
              ),
              IconButton(
                tooltip: l10n ? 'Open Support' : 'Ouvrir Support',
                onPressed: () => context.push('/support'),
                icon: const Icon(Icons.contact_support_outlined),
              ),
              Tooltip(
                message: l10n ? 'Voice' : 'Voix',
                child: DropdownButton<String>(
                  value: _voiceGender,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.record_voice_over_outlined),
                  items: [
                    DropdownMenuItem(value: 'female', child: Text(l10n ? 'Woman' : 'Femme')),
                    DropdownMenuItem(value: 'male', child: Text(l10n ? 'Man' : 'Homme')),
                  ],
                  onChanged: (value) { if (value != null) _setVoiceGender(value); },
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Expanded(child: ListView.builder(
            controller: _scroll,
            itemCount: _messages.length + (_busy ? 1 : 0),
            itemBuilder: (context, index) {
              if (_busy && index == _messages.length) {
                return Align(alignment: Alignment.centerLeft, child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(l10n ? 'Eke is checking published information…' : 'Eke consulte les informations publiées…'),
                ));
              }
              final item = _messages[index];
              return Align(
                alignment: item.fromEke ? Alignment.centerLeft : Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
                  child: Card(
                    color: item.fromEke ? null : Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(padding: const EdgeInsets.all(14), child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(item.text),
                        if (item.needsSupport)
                          TextButton.icon(
                            onPressed: () => context.push('/support'),
                            icon: const Icon(Icons.support_agent_outlined),
                            label: Text(l10n ? 'Contact Support' : 'Contacter le support'),
                          ),
                        if (item.sources.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('${l10n ? 'Sources' : 'Articles'} : ${item.sources.join(' · ')}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                        if (item.fromEke) Align(alignment: Alignment.centerRight, child: IconButton(
                          tooltip: l10n ? 'Read aloud' : 'Lire à voix haute',
                          onPressed: () => _speak(item.text),
                          icon: const Icon(Icons.volume_up_outlined),
                        )),
                      ],
                    )),
                  ),
                ),
              );
            },
          )),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          IconButton.filledTonal(
              tooltip: _listening ? (l10n ? 'Stop listening' : 'Arrêter l’écoute') : (l10n ? 'Speak your question' : 'Dicter votre question'),
              onPressed: _toggleListening,
              icon: Icon(_listening ? Icons.mic : Icons.mic_none),
            ),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: l10n ? 'Ask Eke a question…' : 'Posez une question à Eke…',
                border: const OutlineInputBorder(),
              ),
            )),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: _busy ? null : _send, icon: const Icon(Icons.send_rounded)),
          ]),
          const SizedBox(height: 8),
          Text(l10n
              ? 'Eke uses published portal documents, your own content analytics and the published global Top 10. It cannot read Finance or other producers’ private data.'
              : 'Eke utilise les documents publiés du portail, vos propres statistiques de contenu et le Top 10 global publié. Il ne consulte pas Finance ni les données privées d’autres producteurs.',
              style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}

class _EkeMessage {
  const _EkeMessage({required this.text, required this.fromEke, this.sources = const [], this.needsSupport = false});
  final String text;
  final bool fromEke;
  final List<String> sources;
  final bool needsSupport;
}
