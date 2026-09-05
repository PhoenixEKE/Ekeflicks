import 'package:flutter/material.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:app_ekeflicks/providers/locale_provider.dart';
import 'contact_form_dialog.dart';

Future<void> showCustomMenuDialog(BuildContext context, AppLocalizations loc) {
  final isMobile = MediaQuery.of(context).size.width < 900;

  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final updatedLoc = AppLocalizations.of(context)!;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 16,
              left: 16,
              right: 16,
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔹 Barre de glissement (au-dessus du titre)
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // 🔹 En-tête "Menu" avec bouton de fermeture
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: Text(
                          updatedLoc.menu,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 🔹 Liste des options
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isMobile)
                          ListTile(
                            leading: const Icon(Icons.language),
                            title: Text(updatedLoc.changerDeLangue),
                            onTap: () {
                              Provider.of<LocaleProvider>(
                                context,
                                listen: false,
                              ).toggleLocale();
                              setState(() {});
                            },
                          ),
                        if (isMobile)
                          ListTile(
                            leading: const Icon(
                              Icons.help_outline,
                            ), // 🔄 Icône changée
                            title: Text(updatedLoc.faq), // 🔄 Texte changé
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(
                                context,
                              ).pushNamed('/faq'); // 🔄 Route changée
                            },
                          ),
                        ListTile(
                          leading: const Icon(Icons.privacy_tip),
                          title: Text(updatedLoc.politiqueConfidentialite),
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pushNamed('/privacy');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.rule),
                          title: Text(updatedLoc.conditionsUtilisation),
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pushNamed('/terms');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.contact_mail),
                          title: Text(updatedLoc.contact),
                          onTap: () {
                            Navigator.of(context).pop();
                            showDialog(
                              context: context,
                              builder: (context) => const ContactFormDialog(),
                            );
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                        ),

                        // 🔽 Espace après "Contact" (équivalent visuel au cadre titre)
                        const SizedBox(height: 56),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
