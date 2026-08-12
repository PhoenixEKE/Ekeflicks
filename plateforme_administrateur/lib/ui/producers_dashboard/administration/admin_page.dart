import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plateforme_producteurs/api/admin_api_client.dart';
import 'package:plateforme_producteurs/core/core.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<List<Map<String, dynamic>>> _roles;
  @override void initState() { super.initState(); _reload(); }
  void _reload() => _roles = context.read<AdminApiClient>().roles();

  Future<void> _createRole() async {
    final name = TextEditingController();
    final permissions = await context.read<AdminApiClient>().permissions();
    final selected = <int>{};
    if (!mounted) return;
    final saved = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Créer un rôle'),
        content: SizedBox(width: 560, height: 480, child: Column(children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Nom du rôle')),
          const SizedBox(height: 12),
          const Align(alignment: Alignment.centerLeft, child: Text('Permissions (privilège minimal)')),
          Expanded(child: ListView(children: permissions.map((permission) => CheckboxListTile(
            dense: true, value: selected.contains(permission['id']),
            title: Text(permission['name'] as String), subtitle: Text(permission['key'] as String),
            onChanged: (value) => setDialogState(() => value == true ? selected.add(permission['id'] as int) : selected.remove(permission['id'])),
          )).toList())),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () async {
            if (name.text.trim().isEmpty) return;
            try { await context.read<AdminApiClient>().createRole(name.text.trim(), selected.toList());
              if (context.mounted) Navigator.pop(context, true);
            } on AdminApiException catch (error) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
            }
          }, child: const Text('Créer')),
        ],
      ),
    ));
    name.dispose();
    if (saved == true) setState(_reload);
  }

  @override Widget build(BuildContext context) => Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Rôles et permissions', style: AppTheme.textTitle.copyWith(fontSize: 24)),
        FilledButton.icon(onPressed: _createRole, icon: const Icon(Icons.add_moderator), label: const Text('Créer un rôle')),
      ]),
      const SizedBox(height: 16),
      Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(future: _roles, builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Impossible de charger les rôles : ${snapshot.error}'));
        final roles = snapshot.data ?? [];
        if (roles.isEmpty) return const Center(child: Text('Aucun rôle. Créez le premier rôle à privilège minimal.'));
        return ListView.separated(itemCount: roles.length, separatorBuilder: (_, __) => const Divider(), itemBuilder: (_, index) {
          final role = roles[index]; final permissionIds = List<dynamic>.from(role['permissions'] ?? []);
          return ListTile(leading: const CircleAvatar(child: Icon(Icons.admin_panel_settings)),
            title: Text(role['name'] as String), subtitle: Text('${permissionIds.length} permission(s)'),
            trailing: const Icon(Icons.chevron_right));
        });
      })),
    ])),
  );
}
