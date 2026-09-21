import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plateforme_producteurs/core/app_theme.dart';

class ProducerPageShell extends StatelessWidget {
  const ProducerPageShell({
    super.key,
    required this.child,
    this.title,
    this.actions = const [],
    this.showFaq = false,
    this.showBack = false,
    this.onBack,
    this.maxWidth,
    this.padding,
    this.scrollable = false,
    this.contentDecoration = false,
  });

  final Widget child;
  final String? title;
  final List<Widget> actions;
  final bool showFaq;
  final bool showBack;
  final VoidCallback? onBack;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;
  final bool contentDecoration;

  static const Color _orange = Color(0xFFF67F00);

  static const BoxDecoration pageBackground = BoxDecoration(
    gradient: RadialGradient(
      center: Alignment.topCenter,
      radius: 1.5,
      colors: [Color(0xFF121212), Color(0xFF1E1E1E), Color(0xFF2D2D2D)],
      stops: [0.0, 0.5, 1.0],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final body = LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= 900 ? 32.0 : 16.0;

        Widget content = Padding(
          padding:
              padding ??
              EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 32),
          child: maxWidth == null
              ? child
              : Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth!),
                    child: child,
                  ),
                ),
        );

        if (contentDecoration) {
          content = Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              24,
              horizontalPadding,
              32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth ?? 1180),
                child: Container(
                  width: double.infinity,
                  padding: constraints.maxWidth >= 900
                      ? const EdgeInsets.all(24)
                      : const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(
                      AppTheme.borderRadiusMedium,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ),
          );
        }

        if (scrollable) {
          return SingleChildScrollView(child: content);
        }

        return content;
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: _buildHeader(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: pageBackground,
        child: body,
      ),
    );
  }

  PreferredSizeWidget _buildHeader(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF121212),
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 68,

      // LOGO TOUJOURS A GAUCHE
      leading: showBack
          ? Tooltip(
              message: 'Retour',
              child: IconButton(
                onPressed:
                    onBack ??
                    () {
                      if (context.canPop()) {
                        context.pop();
                      }
                    },
                icon: const Icon(Icons.arrow_back),
              ),
            )
          : null,
      titleSpacing: 20,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo_dark.png',
            height: 32,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              return const Text(
                'EKEFLICKS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              );
            },
          ),
          if (title != null && title!.trim().isNotEmpty) ...[
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                title!.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (showFaq)
          Tooltip(
            message: 'Questions fréquentes',
            child: IconButton(
              onPressed: () => context.push('/faq'),
              icon: const Icon(Icons.help_outline),
            ),
          ),

        ...actions,

        const SizedBox(width: 12),
      ],
    );
  }
}
