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
  void _refresh() => setState(() => _reload());

  Future<void> _createStaff() async {
    final email = TextEditingController();
    final password = TextEditingController();
    String role = 'Modérateur';
    bool visible = false;
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Text('Créer un administrateur'),
        content: SizedBox(
          width: (MediaQuery.sizeOf(context).width - 64).clamp(240, 480).toDouble(),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: email, decoration: const InputDecoration(labelText: 'Adresse e-mail')),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: !visible,
            decoration: InputDecoration(labelText: 'Mot de passe initial (12 caractères minimum)',
              suffixIcon: IconButton(
                tooltip: visible ? 'Masquer le mot de passe' : 'Afficher le mot de passe',
                icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setDialogState(() => visible = !visible),
              ))),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: role, isExpanded: true,
            decoration: const InputDecoration(labelText: 'Rôle'),
            items: const ['Modérateur', 'Finance', 'Support']
              .map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
            onChanged: (value) => setDialogState(() => role = value!),
          ),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          FilledButton(onPressed: () async {
            if (email.text.trim().isEmpty || !email.text.contains('@') || password.text.length < 12) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(
                content: Text('Saisissez une adresse e-mail valide et un mot de passe d’au moins 12 caractères.'),
              ));
              return;
            }
            try {
              final created = await context.read<AdminApiClient>().createStaff(
                email: email.text.trim(), password: password.text, role: role);
              if (dialogContext.mounted) Navigator.pop(dialogContext, created);
            } on AdminApiException catch (error) {
              if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(error.message)));
            }
          }, child: const Text('Créer')),
        ],
      ),
    ));
    final initialPassword = password.text;
    email.dispose(); password.dispose();
    if (result != null && mounted) {
      final user = Map<String, dynamic>.from(result['user'] ?? const {});
      await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
        title: const Text('Administrateur créé'),
        content: SelectableText(
          'Identifiant : ${user['email'] ?? ''}\nMot de passe initial : $initialPassword\n\n'
          'Lien MFA à transmettre une seule fois via un canal sécurisé :\n${result['mfa_provisioning_uri'] ?? ''}',
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Terminé'))],
      ));
    }
  }

  Future<void> _editRole([Map<String, dynamic>? role]) async {
    final api = context.read<AdminApiClient>();
    final name = TextEditingController(text: role?['name']?.toString() ?? '');
    final permissions = await api.permissions();
    final selected = <int>{
      ...List<dynamic>.from(role?['permissions'] ?? const []).map((id) => int.parse(id.toString())),
    };
    if (!mounted) return;
    final saved = await showDialog<bool>(context: context, builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(role == null ? 'Créer un rôle' : 'Modifier le rôle'),
        content: SizedBox(width: 620, height: 500, child: Column(children: [
          TextField(controller: name, enabled: role == null || !_isBaseRole(role), decoration: const InputDecoration(labelText: 'Nom du rôle')),
          const SizedBox(height: 12),
          const Align(alignment: Alignment.centerLeft, child: Text('Permissions')),
          Expanded(child: ListView(children: permissions.map((permission) {
            final id = int.parse(permission['id'].toString());
            return CheckboxListTile(
              dense: true, value: selected.contains(id),
              title: Text(_permissionLabel(permission['key']?.toString() ?? '', permission['name']?.toString() ?? '')),
              subtitle: Text(permission['key']?.toString() ?? ''),
              onChanged: (value) => setDialogState(() => value == true ? selected.add(id) : selected.remove(id)),
            );
          }).toList())),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
          FilledButton(onPressed: () async {
            if (name.text.trim().isEmpty) return;
            try {
              if (role == null) {
                await api.createRole(name.text.trim(), selected.toList());
              } else {
                await api.updateRole(role['id'], name.text.trim(), selected.toList());
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext, true);
            } on AdminApiException catch (error) {
              if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(error.message)));
            }
          }, child: Text(role == null ? 'Créer' : 'Enregistrer')),
        ],
      ),
    ));
    name.dispose();
    if (saved == true && mounted) _refresh();
  }

  bool _isBaseRole(Map<String, dynamic> role) => const {'Modérateur', 'Finance', 'Support'}.contains(role['name']);

  Future<void> _deleteRole(Map<String, dynamic> role) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Supprimer le rôle ?'),
      content: Text('Le rôle « ${role['name']} » sera définitivement supprimé.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Supprimer')),
      ],
    ));
    if (confirmed != true || !mounted) return;
    try { await context.read<AdminApiClient>().deleteRole(role['id']); _refresh(); }
    on AdminApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  String _permissionLabel(String key, String fallback) {
    const actions = {'add': 'Ajouter', 'change': 'Modifier', 'delete': 'Supprimer', 'view': 'Consulter'};
    final code = key.split('.').last;
    final action = actions.entries.where((entry) => code.startsWith('${entry.key}_')).firstOrNull;
    if (action == null) return fallback;
    final object = code.substring(action.key.length + 1).replaceAll('_', ' ');
    return '${action.value} ${object.replaceAll('user', 'utilisateur').replaceAll('payment', 'paiement').replaceAll('content', 'contenu').replaceAll('subscription', 'abonnement')}';
  }

  @override Widget build(BuildContext context) => Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(alignment: WrapAlignment.spaceBetween, runSpacing: 12, spacing: 16, children: [
        Text('Rôles et permissions', style: AppTheme.textTitle.copyWith(fontSize: 24)),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(onPressed: () => _editRole(), icon: const Icon(Icons.add_moderator), label: const Text('Créer un rôle')),
          FilledButton.icon(onPressed: _createStaff, icon: const Icon(Icons.person_add), label: const Text('Créer un administrateur')),
        ]),
      ]),
      const SizedBox(height: 16),
      Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(future: _roles, builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Impossible de charger les rôles : ${snapshot.error}'));
        final roles = snapshot.data ?? [];
        if (roles.isEmpty) return const Center(child: Text('Aucun rôle.'));
        return ListView.separated(itemCount: roles.length, separatorBuilder: (_, __) => const Divider(), itemBuilder: (_, index) {
          final role = roles[index]; final permissionIds = List<dynamic>.from(role['permissions'] ?? []);
          return ListTile(
            onTap: () => _editRole(role),
            leading: const CircleAvatar(child: Icon(Icons.admin_panel_settings)),
            title: Text(role['name']?.toString() ?? ''), subtitle: Text('${permissionIds.length} permission(s)'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(tooltip: 'Modifier', onPressed: () => _editRole(role), icon: const Icon(Icons.edit)),
              if (!_isBaseRole(role)) IconButton(tooltip: 'Supprimer', onPressed: () => _deleteRole(role), icon: const Icon(Icons.delete_outline)),
              const Icon(Icons.chevron_right),
            ]),
          );
        });
      })),
    ])),
  );
}
