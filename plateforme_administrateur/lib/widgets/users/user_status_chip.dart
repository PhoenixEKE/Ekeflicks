import 'package:flutter/material.dart';
import 'package:plateforme_producteurs/ui/producers_dashboard/users/models/user_model.dart';

class UserStatusChip extends StatelessWidget {
  final UserStatus status;

  const UserStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, text) = _getStatusData();
    return Chip(
      label: Text(text),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
      side: BorderSide.none,
    );
  }

  (Color, String) _getStatusData() {
    switch (status) {
      case UserStatus.active:
        return (Colors.green, 'Actif');
      case UserStatus.inactive:
        return (Colors.red, 'Inactif');
      case UserStatus.pending:
        return (Colors.orange, 'En attente');
    }
  }
}