import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:app_ekeflicks/providers/profile_provider.dart';
import 'package:app_ekeflicks/src/models/profile.dart';

class ProfileAccessService {
  static Future<bool> canOpen(BuildContext context, Profile target) async {
    final provider = context.read<ProfileProvider>();
    final currentIsChild = provider.currentProfile?.type?.name == 'child';
    final targetIsAdult = target.type?.name != 'child';
    if (!currentIsChild || !targetIsAdult || target.id == null) return true;

    final status = await provider.apiClient.dio.post<Object>(
      '/profiles/${target.id}/verify-pin/',
      data: const <String, String>{},
    );
    final data = status.data is Map ? Map<String, dynamic>.from(status.data! as Map) : const <String, dynamic>{};
    if (data['pin_required'] != true) return true;
    if (!context.mounted) return false;

    final pin = await askForParentalPin(context);
    if (pin == null || !context.mounted) return false;
    try {
      final verification = await provider.apiClient.dio.post<Object>(
        '/profiles/${target.id}/verify-pin/',
        data: {'pin': pin},
      );
      final result = verification.data is Map
          ? Map<String, dynamic>.from(verification.data! as Map)
          : const <String, dynamic>{};
      return result['verified'] == true;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN incorrect.'), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }

  static Future<String?> askForParentalPin(
    BuildContext context, {
    String title = 'Code PIN parental requis',
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          onSubmitted: (_) => Navigator.pop(dialogContext, controller.text),
          decoration: const InputDecoration(labelText: 'PIN parental', prefixIcon: Icon(Icons.lock)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: const Text('Déverrouiller')),
        ],
      ),
    ).whenComplete(controller.dispose);
  }
}
