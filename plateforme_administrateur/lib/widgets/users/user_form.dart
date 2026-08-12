import 'dart:math';
import 'package:flutter/material.dart'; 
import 'package:plateforme_administrateur/ui/producers_dashboard/users/models/user_model.dart';
import 'package:plateforme_administrateur/widgets/users/linked_profiles_widget.dart';
import 'package:plateforme_administrateur/gen/app_localizations.dart';

class UserForm extends StatefulWidget {
  final User? user;
  final List<String> countries;
  final void Function(User) onSave;

  const UserForm({
    super.key,
    this.user,
    required this.countries,
    required this.onSave,
  });

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  String? _selectedCountry;
  UserStatus? _selectedStatus;
  DateTime? _subscriptionStart;
  DateTime? _subscriptionEnd;
  bool _obscurePassword = true;

  bool get isNewUser => widget.user == null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _passwordController = TextEditingController(
        text: widget.user?.password ?? (isNewUser ? generatePassword() : ''));
    _selectedCountry = widget.user?.country ?? widget.countries.first;
    _selectedStatus = widget.user?.status ?? UserStatus.active;
    _subscriptionStart = widget.user?.subscriptionStart;
    _subscriptionEnd = widget.user?.subscriptionEnd;
  }

  // Génération d'un mot de passe aléatoire
  String generatePassword({int length = 12}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=';
    final rand = Random.secure();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final initialDate = isStart
        ? _subscriptionStart ?? DateTime.now()
        : _subscriptionEnd ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _subscriptionStart = picked;
        } else {
          _subscriptionEnd = picked;
        }
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final user = User(
        id: widget.user?.id ?? DateTime.now().millisecondsSinceEpoch,
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
        profileImage: widget.user?.profileImage,
        subscription: 'Premium', // ou autre logique
        country: _selectedCountry!,
        joinDate: widget.user?.joinDate ?? DateTime.now(),
        subscriptionStart: _subscriptionStart,
        subscriptionEnd: _subscriptionEnd,
        status: _selectedStatus!,
        linkedProfiles: widget.user?.linkedProfiles ?? [],
        transactions: widget.user?.transactions ?? [],
      );
      widget.onSave(user);
    }
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
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.name),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Champ requis' : null,
            ),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: l10n.email),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Champ requis' : null,
            ),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: l10n.phone),
            ),
            // Mot de passe visible uniquement si nouvel utilisateur
            if (isNewUser)
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Champ requis' : null,
              ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCountry,
              decoration: InputDecoration(labelText: l10n.country),
              items: widget.countries
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCountry = value!;
                });
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<UserStatus>(
              value: _selectedStatus,
              decoration: InputDecoration(labelText: l10n.status),
              items: UserStatus.values
                  .map((s) =>
                      DropdownMenuItem(value: s, child: Text(s.name)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(context, true),
                    child: InputDecorator(
                      decoration:
                          InputDecoration(labelText: l10n.subscriptionStart),
                      child: Text(_subscriptionStart != null
                          ? '${_subscriptionStart!.day}/${_subscriptionStart!.month}/${_subscriptionStart!.year}'
                          : '---'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(context, false),
                    child: InputDecorator(
                      decoration:
                          InputDecoration(labelText: l10n.subscriptionEnd),
                      child: Text(_subscriptionEnd != null
                          ? '${_subscriptionEnd!.day}/${_subscriptionEnd!.month}/${_subscriptionEnd!.year}'
                          : '---'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (!isNewUser)
              LinkedProfilesWidget(
                profiles: widget.user?.linkedProfiles ?? [],
                onAddProfile: (_) {},
                onRemoveProfile: (_) {},
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
