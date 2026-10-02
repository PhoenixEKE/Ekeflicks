import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plateforme_producteurs/onboarding/widgets/producer_auth_shell.dart';
import 'package:plateforme_producteurs/services/producer_service.dart';

class ProducerFaqPage extends StatefulWidget {
  const ProducerFaqPage({super.key});

  @override
  State<ProducerFaqPage> createState() => _ProducerFaqPageState();
}

class _ProducerFaqPageState extends State<ProducerFaqPage> {
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await ProducerService.instance.getProducerFaq();
      if (mounted) setState(() => _items = rows);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final filtered = _items.where((item) {
      final text = '${item['question']} ${item['answer']} ${item['category']}'.toLowerCase();
      return text.contains(_query.toLowerCase().trim());
    }).toList();
    return ProducerAuthShell(
      maxWidth: 1050,
      showFaqButton: false,
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            IconButton(tooltip: english ? 'Back' : 'Retour', onPressed: () {
              if (context.canPop()) { context.pop(); } else { context.go('/'); }
            }, icon: const Icon(Icons.arrow_back)),
            const SizedBox(width: 8),
            Expanded(child: Text(
              english ? 'Producer FAQ' : 'FAQ Producteurs',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            )),
          ]),
          const SizedBox(height: 8),
          Text(english ? 'Verified answers about your producer account and portal.' : 'Réponses vérifiées sur votre compte et votre espace Producteur.'),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: english ? 'Search questions' : 'Rechercher une question',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading) const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null) Expanded(child: Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(english ? 'FAQ could not be loaded.' : 'La FAQ n’a pas pu être chargée.', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: Text(english ? 'Retry' : 'Réessayer')),
            ],
          )))
          else Expanded(child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final item = filtered[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  title: Text(item['question']?.toString() ?? ''),
                  subtitle: Text(item['category']?.toString() ?? ''),
                  children: [Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    child: Align(alignment: Alignment.centerLeft, child: Text(item['answer']?.toString() ?? '')),
                  )],
                ),
              );
            },
          )),
        ],
      ),
    );
  }
}
