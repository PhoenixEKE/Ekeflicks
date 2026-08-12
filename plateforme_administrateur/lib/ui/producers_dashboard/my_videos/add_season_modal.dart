import 'package:flutter/material.dart';
import 'package:plateforme_administrateur/gen/app_localizations.dart';

class AddSeasonModal extends StatefulWidget {
  final Function(String) onAddSeason;

  const AddSeasonModal({
    super.key,
    required this.onAddSeason,
  });

  @override
  State<AddSeasonModal> createState() => _AddSeasonModalState();
}

class _AddSeasonModalState extends State<AddSeasonModal> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.addSeason),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: l10n.seasonTitleLabel,
                hintText: l10n.seasonTitleHint,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.requiredField;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onAddSeason(_controller.text);
              Navigator.pop(context);
            }
          },
          child: Text(l10n.add),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
