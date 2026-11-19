import 'package:flutter/material.dart';

import 'package:app_ekeflicks/models/eke_ai_models.dart';

class EkeAIContentCard extends StatelessWidget {
  final EkeAIContent content;
  final VoidCallback? onTap;
  final VoidCallback? onExplain;
  final VoidCallback? onLike;
  final VoidCallback? onFavorite;

  const EkeAIContentCard({
    super.key,
    required this.content,
    this.onTap,
    this.onExplain,
    this.onLike,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final poster = content.posterUrl;

    return SizedBox(
      width: 160,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 2 / 3,
                child:
                    poster != null && poster.isNotEmpty
                        ? Image.network(
                          poster,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _PosterPlaceholder(),
                        )
                        : const _PosterPlaceholder(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                child: Text(
                  content.title.isEmpty ? 'Contenu EKEFLICKS' : content.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (content.reason?.trim().isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    content.reason!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                child: Wrap(
                  spacing: 0,
                  children: [
                    IconButton(
                      tooltip: 'Pourquoi ce contenu ?',
                      onPressed: onExplain,
                      icon: const Icon(Icons.auto_awesome_outlined),
                    ),
                    IconButton(
                      tooltip: 'J’aime',
                      onPressed: onLike,
                      icon: const Icon(Icons.thumb_up_alt_outlined),
                    ),
                    IconButton(
                      tooltip: 'Favori',
                      onPressed: onFavorite,
                      icon: const Icon(Icons.favorite_border),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EkeAIEmptyState extends StatelessWidget {
  final String message;

  const EkeAIEmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.auto_awesome_outlined, size: 36),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class EkeAIErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const EkeAIErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            const Text(
              'EKE IA est momentanément indisponible.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      alignment: Alignment.center,
      child: const Icon(Icons.movie_outlined, size: 38),
    );
  }
}
