import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      final response = await _service().chat(text, limit: 10);

      if (!mounted) return;

      final answer =
          response.message?.trim().isNotEmpty == true
              ? response.message!.trim()
              : response.items.isEmpty
              ? 'Je n’ai pas trouvé de contenu disponible correspondant.'
              : 'Voici une sélection disponible sur EKEFLICKS.';

      setState(() {
        _messages.add(_AssistantMessage(fromUser: false, text: answer));
        _recommendations = response.items;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _messages.add(
          const _AssistantMessage(
            fromUser: false,
            text:
                'Je suis momentanément indisponible. '
                'Vous pouvez réessayer dans quelques instants.',
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome),
            SizedBox(width: 8),
            Text('Assistant EKE IA'),
          ],
        ),
      ),
      body: Container(
        decoration: AppTheme.pageDecoration(context),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
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
                              constraints: const BoxConstraints(maxWidth: 650),
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
                            'Sélection EKE IA',
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
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: const InputDecoration(
                              hintText:
                                  'Ex. Je veux une comédie africaine '
                                  'pour ce soir...',
                              prefixIcon: Icon(Icons.auto_awesome_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: 'Envoyer',
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
