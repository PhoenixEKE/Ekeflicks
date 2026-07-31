import 'package:flutter/material.dart';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'models/producer_model.dart';
import 'package:plateforme_producteurs/widgets/producers/add_producer_form.dart';

class ProducersPage extends StatefulWidget {
  const ProducersPage({super.key});

  @override
  State<ProducersPage> createState() => _ProducersPageState();
}

class _ProducersPageState extends State<ProducersPage> {
  List<Producer> _producers = [];
  List<Producer> _filteredProducers = [];

  // ✅ Getter pour accéder aux traductions facilement
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _producers = _getMockProducers();
    _filteredProducers = _producers;
  }

  
  List<Producer> _getMockProducers() {
    return [
      Producer(
        id: 1,
        name: 'Film Productions',
        email: 'contact@filmprod.com',
        phone: '+1234567890',
        address: '123 Rue du Cinéma, Paris',
        country: 'France',
        password: 'temp123',
        totalVideos: 24,
        validatedVideos: 18,
        rejectedVideos: 3,
        pendingVideos: 3,
        totalViews: 12500,
        viewsPerVideo: {'Video1': 5000, 'Video2': 7500},
        earnings: 1250.50,
        status: 'active', // ✅ actif
      ),
      Producer(
        id: 2,
        name: 'Cinema Art',
        email: 'contact@cinemaart.com',
        phone: '+0987654321',
        address: '45 Avenue du Film, Lyon',
        country: 'France',
        password: 'temp456',
        totalVideos: 10,
        validatedVideos: 5,
        rejectedVideos: 2,
        pendingVideos: 3,
        totalViews: 5000,
        viewsPerVideo: {'VideoA': 3000, 'VideoB': 2000},
        earnings: 500.0,
        status: 'inactive', // ✅ inactif
      ),
    ];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.producersManagement,
                  style: AppTheme.textTitle.copyWith(fontSize: 24),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddProducerDialog,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addProducer),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildFilterRow(),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filteredProducers.length,
                          itemBuilder: (context, index) {
                            final producer = _filteredProducers[index];
                            return _buildProducerCard(producer);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProducerCard(Producer producer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(producer.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(producer.email),
            Text('${producer.phone} • ${producer.country}• ${producer.status.toUpperCase()}'),
            _buildVideoStats(producer),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${producer.totalViews} vues', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${producer.earnings} €', style: const TextStyle(color: Colors.green)),
          ],
        ),
        onTap: () => _showProducerDetails(producer.id),
      ),
    );
  }

  Widget _buildVideoStats(Producer producer) {
    return Row(
      children: [
        _buildStatChip('Total', producer.totalVideos.toString()),
        _buildStatChip('Validés', producer.validatedVideos.toString(), Colors.green),
        _buildStatChip('Rejetés', producer.rejectedVideos.toString(), Colors.red),
        _buildStatChip('En attente', producer.pendingVideos.toString(), Colors.orange),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: Chip(
        label: Text('$label: $value'),
        backgroundColor: color?.withOpacity(0.2) ?? Colors.grey[200],
        labelStyle: TextStyle(color: color ?? Colors.black),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.searchProducers,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDecorations.borderRadiusSmall),
              ),
            ),
            onChanged: _filterProducers,
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: 'all',
          items: [
            DropdownMenuItem(value: 'all', child: Text(l10n.allStatus)),
            DropdownMenuItem(value: 'active', child: Text(l10n.active)),
            DropdownMenuItem(value: 'inactive', child: Text(l10n.inactive)),
          ],
          onChanged: _filterByStatus,
        ),
      ],
    );
  }

  void _filterProducers(String query) {
    setState(() {
      _filteredProducers = _producers.where((producer) {
        return producer.name.toLowerCase().contains(query.toLowerCase()) ||
            producer.email.toLowerCase().contains(query.toLowerCase()) ||
            producer.phone.contains(query);
      }).toList();
    });
  }

  void _filterByStatus(String? status) {
    if (status == 'all') {
      setState(() => _filteredProducers = _producers);
    } else {
      setState(() {
        _filteredProducers = _producers.where(
          (producer) => producer.status.toLowerCase() == status,
        ).toList();
      });
    }
  }

  void _showAddProducerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addProducer),
        content: const AddProducerForm(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              // Sauvegarder le nouveau producteur
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showProducerDetails(int producerId) {
    final producer = _producers.firstWhere((p) => p.id == producerId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(producer.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${producer.email}'),
              Text('Téléphone: ${producer.phone}'),
              Text('Adresse: ${producer.address}'),
              Text('Pays: ${producer.country}'),
              const SizedBox(height: 16),
              const Text('Statistiques:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Films déposés: ${producer.totalVideos}'),
              Text('Validés: ${producer.validatedVideos}'),
              Text('Rejetés: ${producer.rejectedVideos}'),
              Text('En attente: ${producer.pendingVideos}'),
              const SizedBox(height: 16),
              Text('Vues totales: ${producer.totalViews}'),
              Text('Gains totaux: ${producer.earnings} €'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
