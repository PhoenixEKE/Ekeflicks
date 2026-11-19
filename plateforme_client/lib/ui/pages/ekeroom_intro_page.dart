import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_ekeflicks/core/app_theme.dart';

class EkeRoomIntroPage extends StatelessWidget {
  const EkeRoomIntroPage({super.key});

  Future<void> _openOffers(BuildContext context) async {
    if (kIsWeb) {
      Navigator.of(context).pushNamed('/subscription-step1');
      return;
    }
    final uri = Uri(scheme: 'https', host: 'ekeflicks.com', fragment: '/subscription-step1');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible d’ouvrir le navigateur.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final theme = Theme.of(context);
    final benefits = english
        ? const [
            ('One shared screen', 'Watch the same film or episode together, wherever everyone is.'),
            ('A more social night', 'React and chat while the story unfolds.'),
            ('Easy to invite', 'Bring friends and family into a shared EkeRoom session.'),
          ]
        : const [
            ('Un même écran partagé', 'Regardez le même film ou épisode ensemble, où que vous soyez.'),
            ('Une séance plus vivante', 'Réagissez et échangez pendant que l’histoire se déroule.'),
            ('Des proches invités', 'Réunissez amis et famille dans une séance EkeRoom.'),
          ];

    return Scaffold(
      appBar: AppBar(title: const Text('EkeRoom')),
      body: Container(
        decoration: AppTheme.pageDecoration(context),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: Column(
                      children: [
                        const Icon(Icons.groups_rounded, size: 70, color: AppTheme.primaryOrange),
                        const SizedBox(height: 18),
                        Text(
                          english ? 'Movie nights are better together.' : 'Le cinéma se partage, même à distance.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          english
                              ? 'EkeRoom brings your friends and family together for a synchronized film or series session, with conversation along the way.'
                              : 'EkeRoom réunit vos proches autour d’un film ou d’une série en lecture synchronisée, avec un espace pour échanger pendant la séance.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(height: 1.45),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => _openOffers(context),
                          icon: const Icon(Icons.play_circle_outline),
                          label: Text(english ? 'Discover plans' : 'Découvrir les offres'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ...benefits.map((benefit) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.check_circle_outline, color: AppTheme.primaryOrange),
                    title: Text(benefit.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(benefit.$2),
                  ),
                )),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(english ? 'Back to catalogue' : 'Retour au catalogue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
