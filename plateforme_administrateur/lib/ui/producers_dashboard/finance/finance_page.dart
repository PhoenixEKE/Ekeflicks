import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:plateforme_administrateur/api/admin_api_client.dart';
import 'package:plateforme_administrateur/core/core.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});
  @override State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  final search = TextEditingController();
  String status = 'pending';
  late Future<List<Map<String, dynamic>>> data;
  @override void initState() { super.initState(); data = _load(); }
  Future<List<Map<String, dynamic>>> _load() => context.read<AdminApiClient>().payouts(status: status, search: search.text.trim());
  void _reload() => setState(() => data = _load());
  @override void dispose() { search.dispose(); super.dispose(); }

  Future<void> _decide(Map<String, dynamic> payout, String action) async {
    final reason = TextEditingController();
    final password = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(action == 'approve' ? 'Première validation' : action == 'mark-paid' ? 'Seconde validation et paiement' : 'Rejeter le reversement'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: reason, maxLines: 3, decoration: const InputDecoration(labelText: 'Motif / référence de paiement')),
        if (action == 'mark-paid') TextField(controller: password, obscureText: true,
          decoration: const InputDecoration(labelText: 'Votre mot de passe (réauthentification)')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmer'))
      ],
    ));
    if (confirmed == true) {
      try {
        await context.read<AdminApiClient>().reviewPayout(payout['id'] as int, action,
          reason: reason.text, password: action == 'mark-paid' ? password.text : null);
        _reload();
      } on AdminApiException catch (error) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
    reason.dispose(); password.dispose();
  }

  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Décisions de reversement', style: AppTheme.textTitle.copyWith(fontSize: 24)),
      const Text('Une seconde personne doit confirmer la mise en paiement.'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextField(controller: search, onSubmitted: (_) => _reload(), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Producteur'))),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: status,
          items: const [
            DropdownMenuItem(value: 'pending', child: Text('À valider')),
            DropdownMenuItem(value: 'approved', child: Text('À payer')),
            DropdownMenuItem(value: 'paid', child: Text('Payés')),
            DropdownMenuItem(value: 'rejected', child: Text('Rejetés')),
          ],
          onChanged: (value) { status = value!; _reload(); }
        )
      ]),
      const SizedBox(height: 12),
      Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Erreur API : ${snapshot.error}'));
          final rows = snapshot.data ?? [];
          if (rows.isEmpty) return const Center(child: Text('Aucune demande.'));
          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, index) {
              final row = rows[index];
              final state = row['status'];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.payments)),
                title: Text('${row['amount_local']} ${row['currency']}'),
                subtitle: Text('${row['producer_email']} • ${row['payout_method']} • ${row['payout_account']}'),
                trailing: Wrap(spacing: 8, children: [
                  if (state == 'pending') ...[
                    OutlinedButton(
                      onPressed: () => _decide(row, 'reject'),
                      child: const Text('Rejeter')
                    ),
                    FilledButton(
                      onPressed: () => _decide(row, 'approve'),
                      child: const Text('Approuver')
                    )
                  ],
                  if (state == 'approved')
                    FilledButton.icon(
                      onPressed: () => _decide(row, 'mark-paid'),
                      icon: const Icon(Icons.verified),
                      label: const Text('Confirmer le paiement')
                    ),
                  if (state == 'paid' || state == 'rejected')
                    Chip(label: Text(state.toString().toUpperCase())),
                ]),
              );
            }
          );
        }
      ))
    ])
  );
}
