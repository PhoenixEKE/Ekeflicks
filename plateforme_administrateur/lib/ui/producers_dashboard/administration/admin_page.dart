import 'package:flutter/material.dart';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'package:plateforme_producteurs/widgets/administration/AddAdminFormWidget.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final List<Map<String, dynamic>> _admins = [
    {
      'id': 1,
      'name': 'Admin Principal',
      'email': 'admin@example.com',
      'role': 'Super Admin',
      'lastLogin': '2023-05-20 14:30',
      'phone': '',
      'password': '********',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.adminManagement,
              style: AppTheme.textTitle.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _showAddAdminDialog,
                            icon: const Icon(Icons.add),
                            label: Text(l10n.addAdmin),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _admins.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final admin = _admins[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppTheme.primary,
                                child: Icon(Icons.admin_panel_settings,
                                    color: Colors.white),
                              ),
                              title: Text(admin['name']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(admin['email']),
                                  Text('${l10n.role}: ${admin['role']}'),
                                  Text('${l10n.lastLogin}: ${admin['lastLogin']}'),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) {
                                  if (admin['role'] == 'Super Admin') {
                                    return []; // Pas d'action possible
                                  }
                                  return [
                                    PopupMenuItem(
                                      child: Text(l10n.edit),
                                      onTap: () =>
                                          _editAdmin(Map.from(admin)),
                                    ),
                                    PopupMenuItem(
                                      child: Text(l10n.delete),
                                      onTap: () =>
                                          _deleteAdmin(admin['id']),
                                    ),
                                  ];
                                },
                              ),
                            );
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

  void _showAddAdminDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addAdmin),
        content: AddAdminFormWidget(
          onSave: (newAdmin) {
            setState(() {
              _admins.add({
                'id': _admins.length + 1,
                ...newAdmin,
              });
            });
          },
        ),
      ),
    );
  }

  void _editAdmin(Map<String, dynamic> admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.edit),
        content: AddAdminFormWidget(
          initialData: admin,
          onSave: (updatedAdmin) {
            setState(() {
              final index =
                  _admins.indexWhere((a) => a['id'] == admin['id']);
              if (index != -1) {
                _admins[index] = {
                  'id': admin['id'],
                  ...updatedAdmin,
                };
              }
            });
          },
        ),
      ),
    );
  }

  void _deleteAdmin(int adminId) {
    setState(() {
      _admins.removeWhere((a) => a['id'] == adminId);
    });
  }
}
