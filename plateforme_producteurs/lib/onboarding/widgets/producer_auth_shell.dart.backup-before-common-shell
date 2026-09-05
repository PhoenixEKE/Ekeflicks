import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [Color(0xFF121212), Color(0xFF1E1E1E), Color(0xFF2D2D2D)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 900
                  ? 32.0
                  : 16.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  14,
                  horizontalPadding,
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 64,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                'assets/images/logo_dark.png',
                                height: 52,
                                fit: BoxFit.contain,
                              ),
                              if (showFaqButton)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Tooltip(
                                    message: 'Questions fréquentes',
                                    child: Material(
                                      color: const Color(
                                        0xFF242424,
                                      ).withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(50),
                                      child: IconButton(
                                        onPressed: () => context.push('/faq'),
                                        icon: const Icon(
                                          Icons.help_outline,
                                          color: Color(0xFFF67F00),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(
                            constraints.maxWidth >= 900 ? 24 : 18,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF242424,
                            ).withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 28,
                                offset: const Offset(0, 14),
                                color: Colors.black.withValues(alpha: 0.24),
                              ),
                            ],
                          ),
                          child: child,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
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
