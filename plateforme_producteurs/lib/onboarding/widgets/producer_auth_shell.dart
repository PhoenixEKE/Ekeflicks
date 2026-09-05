import 'package:flutter/material.dart';
import 'package:plateforme_producteurs/widgets/producer_page_shell.dart';

class ProducerAuthShell extends StatelessWidget {
  const ProducerAuthShell({
    super.key,
    required this.child,
    this.maxWidth = 1180,
    this.showFaqButton = true,
  });

  final Widget child;
  final double maxWidth;
  final bool showFaqButton;

  @override
  Widget build(BuildContext context) {
    return ProducerPageShell(
      maxWidth: maxWidth,
      showFaq: showFaqButton,
      scrollable: true,
      contentDecoration: true,
      child: child,
    );
  }
}

class ProducerFormHeader extends StatelessWidget {
  const ProducerFormHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.movie_creation_outlined,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF67F00);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: orange.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: orange, size: 25),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
