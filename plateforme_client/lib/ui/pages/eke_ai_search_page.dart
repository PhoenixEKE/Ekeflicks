import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_ekeflicks/core/app_theme.dart';
import 'package:app_ekeflicks/models/eke_ai_models.dart';
import 'package:app_ekeflicks/providers/user_provider.dart';
import 'package:app_ekeflicks/services/eke_ai_service.dart';

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
      final response = await _service().search(query, limit: 30);

      if (!mounted) return;

      setState(() {
        _results = response.items;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _results = const [];
        _error = 'La recherche EKE IA est momentanément indisponible.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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
      appBar: AppBar(title: const Text('Recherche EKE IA')),
      body: Container(
        decoration: AppTheme.pageDecoration(context),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: InputDecoration(
                        hintText:
                            'Demandez à EKE IA un film, '
                            'une série, un genre...',
                        prefixIcon: const Icon(Icons.auto_awesome),
                        suffixIcon: IconButton(
                          tooltip: 'Rechercher',
                          onPressed: _loading ? null : _search,
                          icon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loading) const LinearProgressIndicator(),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 8),
                    Expanded(
                      child:
                          _results.isEmpty && !_loading && _error == null
                              ? const Center(
                                child: Text(
                                  'Que souhaitez-vous regarder ?',
                                  textAlign: TextAlign.center,
                                ),
                              )
                              : ListView.separated(
                                itemCount: _results.length,
                                separatorBuilder:
                                    (_, _) => const SizedBox(height: 8),
                                itemBuilder:
                                    (context, index) =>
                                        _resultCard(_results[index]),
                              ),
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
