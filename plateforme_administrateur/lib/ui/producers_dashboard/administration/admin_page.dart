import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plateforme_administrateur/api/admin_api_client.dart';
import 'package:plateforme_administrateur/core/core.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  @override State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<List<Map<String, dynamic>>> _roles;
  @override void initState() { super.initState(); _reload(); }
  void _reload() => _roles = context.read<AdminApiClient>().roles();

  Future<void> _createStaff() async {
    final email = TextEditingController();
    final password = TextEditingController();
    String role = 'Modérateur';
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Créer un administrateur'),
        content: SizedBox(width: 480, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: email, decoration: const InputDecoration(labelText: 'Adresse e-mail')),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe initial (12 caractères minimum)')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: role, decoration: const InputDecoration(labelText: 'Rôle'),
            items: const ['Modérateur', 'Finance', 'Support']
              .map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
            onChanged: (value) => setDialogState(() => role = value!),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(onPressed: () async {
            try {
              final created = await context.read<AdminApiClient>().createStaff(
                email: email.text.trim(), password: password.text, role: role);
              if (context.mounted) Navigator.pop(context, created);
            } on AdminApiException catch (error) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
            }
          }, child: const Text('Créer')),
        ],
      ),
    ));
    email.dispose(); password.dispose();
    if (result != null && mounted) {
      await showDialog<void>(context: context, builder: (context) => AlertDialog(
        title: const Text('Enrôlement MFA requis'),
        content: SelectableText('Transmettez ce lien une seule fois au nouvel administrateur, via un canal sécurisé :\n\n${result['mfa_provisioning_uri']}'),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Terminé'))],
      ));
    }
  }

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
        Wrap(spacing: 8, children: [
          OutlinedButton.icon(onPressed: _createRole, icon: const Icon(Icons.add_moderator), label: const Text('Créer un rôle')),
          FilledButton.icon(onPressed: _createStaff, icon: const Icon(Icons.person_add), label: const Text('Créer un administrateur')),
        ]),
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
