import 'dart:math';
import 'package:flutter/material.dart';
import 'package:plateforme_administrateur/gen/app_localizations.dart';
import 'package:plateforme_administrateur/core/core.dart';

class AddAdminFormWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic>? initialData; // Ajout pour l'édition

  const AddAdminFormWidget({
    super.key,
    required this.onSave,
    this.initialData,
  });

  @override
  State<AddAdminFormWidget> createState() => _AddAdminFormWidgetState();
}

class _AddAdminFormWidgetState extends State<AddAdminFormWidget> {
  final _formKey = GlobalKey<FormState>();

  late String name;
  late String email;
  late String phone;
  late String role;
  late String password;

  @override
  void initState() {
    super.initState();
    // Initialisation des champs (ajout ou édition)
    name = widget.initialData?['name'] ?? '';
    email = widget.initialData?['email'] ?? '';
    phone = widget.initialData?['phone'] ?? '';
    role = widget.initialData?['role'] ?? 'Gestionnaire';
    password = widget.initialData?['password'] ?? _generatePassword();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: name,
              decoration: InputDecoration(
                labelText: l10n.name,
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? l10n.enterName : null,
              onSaved: (value) => name = value!.trim(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: email,
              decoration: InputDecoration(
                labelText: l10n.email,
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => value == null || !value.contains('@')
                  ? l10n.enterValidEmail
                  : null,
              onSaved: (value) => email = value!.trim(),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: phone,
              decoration: InputDecoration(
                labelText: l10n.phone,
                prefixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value == null || value.isEmpty ? l10n.enterPhone : null,
              onSaved: (value) => phone = value!.trim(),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: role,
              items: const [
                DropdownMenuItem(
                    value: 'Gestionnaire', child: Text('Gestionnaire')),
                DropdownMenuItem(value: 'Financière', child: Text('Financière')),
                DropdownMenuItem(value: 'Super Admin', child: Text('Super Admin')),
              ],
              onChanged: (value) => role = value!,
              decoration: InputDecoration(
                labelText: l10n.role,
                prefixIcon: const Icon(Icons.admin_panel_settings),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: TextEditingController(text: password),
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    readOnly: true,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: l10n.regeneratePassword,
                  onPressed: () {
                    setState(() {
                      password = _generatePassword();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      widget.onSave({
                        'name': name,
                        'email': email,
                        'phone': phone,
                        'role': role,
                        'password': password,
                        'lastLogin': widget.initialData?['lastLogin'] ?? '',
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Génération mot de passe sécurisé
  String _generatePassword({int length = 12}) {
    const String upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lower = 'abcdefghijklmnopqrstuvwxyz';
    const String numbers = '0123456789';
    const String special = '!@#\$%^&*()-_=+[]{}|;:,.<>?';

    final String allChars = upper + lower + numbers + special;
    final Random rand = Random.secure();

    return List.generate(
            length, (index) => allChars[rand.nextInt(allChars.length)])
        .join();
  }
}
