import 'package:flutter/material.dart';
import 'package:plateforme_producteurs/ui/producers_dashboard/users/models/user_model.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';

class UserActions extends StatelessWidget {
  final User user;
  final VoidCallback onEdit;
  final VoidCallback onFinance;
  final VoidCallback onManageProfiles;

  const UserActions({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onFinance,
    required this.onManageProfiles,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onEdit,
          tooltip: l10n.editUser, // ⬅️ traduction
        ),
        IconButton(
          icon: const Icon(Icons.attach_money),
          onPressed: onFinance,
          tooltip: l10n.transactions, // ⬅️ traduction
        ),
        IconButton(
          icon: const Icon(Icons.people),
          onPressed: onManageProfiles,
          tooltip: l10n.linkedProfiles, // ⬅️ traduction
        ),
      ],
    );
  }
}
