import 'dart:math';
import 'package:flutter/material.dart';
import 'package:plateforme_administrateur/gen/app_localizations.dart';

class AddProducerForm extends StatefulWidget {
  const AddProducerForm({super.key});

  @override
  State<AddProducerForm> createState() => _AddProducerFormState();
}

class _AddProducerFormState extends State<AddProducerForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _country = 'France';
  String _generatedPassword = '';

  final List<String> _countries = [
    'France',
    'Belgique',
    'Suisse',
    'Canada',
    'Autre'
  ];

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    setState(() {
      _generatedPassword = _randomString(8);
    });
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt((chars.length * random.nextDouble()).floor()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.producerName,
                border: const OutlineInputBorder(),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Ce champ est obligatoire' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: l10n.email,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value!.isEmpty) return 'Ce champ est obligatoire';
                if (!value.contains('@')) return 'Email invalide';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: l10n.phone,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value!.isEmpty ? 'Ce champ est obligatoire' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: l10n.address,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _country,
              items: _countries.map((country) {
                return DropdownMenuItem(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
              onChanged: (value) => setState(() => _country = value!),
              decoration: InputDecoration(
                labelText: l10n.country,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _generatedPassword,
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      border: const OutlineInputBorder(),
                    ),
                    readOnly: true,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _generatePassword,
                  tooltip: l10n.generateNewPassword,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
