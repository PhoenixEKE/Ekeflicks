import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plateforme_producteurs/onboarding/widgets/producer_auth_shell.dart';

class ProducerFaqPage extends StatelessWidget {
  const ProducerFaqPage({super.key});

  static const _items = <(String, String)>[
    (
      'Qui peut devenir Producteur EKEFLICKS ?',
      'Une société, un studio, un producteur indépendant ou une structure disposant des droits nécessaires sur ses contenus.',
    ),
    (
      'Quels contenus puis-je proposer ?',
      'Films, séries et autres œuvres audiovisuelles compatibles avec la ligne éditoriale et les exigences techniques EKEFLICKS.',
    ),
    (
      'Pourquoi mes informations professionnelles sont-elles demandées ?',
      'Elles servent à identifier juridiquement le Producteur et à personnaliser le contrat conclu avec EKEFLICKS.',
    ),
    (
      'Dois-je vérifier mon adresse email ?',
      'Oui. La vérification de l’adresse email est obligatoire avant la signature du contrat.',
    ),
    (
      'Puis-je déposer un contenu avant de signer ?',
      'Non. Le contrat Producteur doit être signé et le compte activé avant tout dépôt de film ou de série.',
    ),
    (
      'Que se passe-t-il après la signature ?',
      'Votre compte Producteur est activé et vous pouvez accéder aux fonctionnalités de dépôt et de suivi des contenus.',
    ),
    (
      'Comment mes contenus sont-ils validés ?',
      'Chaque dépôt passe par des contrôles techniques et automatisés, puis par une validation finale EKEFLICKS.',
    ),
    (
      'Puis-je suivre le statut de mes contenus ?',
      'Oui. Votre espace Producteur permet de suivre leur progression jusqu’à leur publication ou une éventuelle demande de correction.',
    ),
    (
      'Puis-je retrouver mon contrat signé ?',
      'Oui. Le contrat signé reste accessible dans votre espace Producteur depuis la rubrique « Mon contrat ».',
    ),
    (
      'Que se passe-t-il si le contrat EKEFLICKS change ?',
      'Une nouvelle version nécessitant votre accord vous sera présentée lorsque les modifications contractuelles l’exigent.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ProducerAuthShell(
      maxWidth: 1050,
      showFaqButton: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Retour',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Questions fréquentes',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 56),
            child: Text(
              'Tout ce qu’il faut savoir sur votre espace Producteur EKEFLICKS.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
          ),
          const SizedBox(height: 24),
          ..._items.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: ExpansionTile(
                iconColor: const Color(0xFFF67F00),
                collapsedIconColor: Colors.white70,
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(
                  item.$1,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 48, 18),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item.$2,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
