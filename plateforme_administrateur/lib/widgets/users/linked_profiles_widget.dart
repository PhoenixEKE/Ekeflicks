import 'package:flutter/material.dart';
import 'package:plateforme_administrateur/ui/producers_dashboard/users/models/user_model.dart';

class LinkedProfilesWidget extends StatelessWidget {
  final List<LinkedProfile> profiles;
  final Function(LinkedProfile) onAddProfile;
  final Function(String) onRemoveProfile;

  const LinkedProfilesWidget({
    super.key,
    required this.profiles,
    required this.onAddProfile,
    required this.onRemoveProfile,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 500,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...profiles.map((profile) => Card(
                  child: ListTile(
                    title: Text(profile.name),
                    subtitle: Text(
                      "${profile.type} - ${profile.relation}"
                      "${profile.type == 'Enfant' ? "\nParental: ${profile.parentalControl == true ? "Activé" : "Désactivé"} | Temps: ${profile.viewingTime ?? "-"}" : ""}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => onRemoveProfile(profile.id),
                    ),
                  ),
                )),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showAddProfileDialog(context),
              icon: const Icon(Icons.add),
              label: const Text("Ajouter un profil"),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProfileDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String type = "Enfant"; // valeur par défaut
    String name = "";
    bool parentalControl = false;
    String? viewingTime;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter un profil lié"),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(value: "Enfant", child: Text("Enfant")),
                    DropdownMenuItem(value: "Invité", child: Text("Invité")),
                  ],
                  onChanged: (value) {
                    if (value != null) type = value;
                  },
                  decoration: const InputDecoration(labelText: "Type de profil"),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: "Nom"),
                  validator: (val) => val == null || val.isEmpty ? "Nom requis" : null,
                  onChanged: (val) => name = val,
                ),
                if (type == "Enfant") ...[
                  SwitchListTile(
                    title: const Text("Activer contrôle parental"),
                    value: parentalControl,
                    onChanged: (val) {
                      parentalControl = val;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Temps de visionnage (ex: 2h/jour)"),
                    onChanged: (val) => viewingTime = val,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Ajouter"),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                onAddProfile(
                  LinkedProfile(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    type: type,
                    name: name,
                    relation: type == "Enfant" ? "Fils/Fille" : "Invité",
                    accessLevel: type == "Enfant" ? "Limité" : "Standard",
                    parentalControl: type == "Enfant" ? parentalControl : null,
                    viewingTime: type == "Enfant" ? viewingTime : null,
                  ),
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
