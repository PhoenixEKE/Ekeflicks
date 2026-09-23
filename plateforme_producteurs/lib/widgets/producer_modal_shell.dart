import 'package:flutter/material.dart';

class ProducerModalShell extends StatelessWidget {
  const ProducerModalShell({
    super.key,
    required this.title,
    required this.child,
    this.actions = const <Widget>[],
    this.width,
    this.maxWidth = 760,
    this.maxHeight,
    this.insetPadding = const EdgeInsets.all(24),
    this.showClose = true,
    this.onClose,
    this.bodyPadding = const EdgeInsets.all(20),
    this.backgroundColor = const Color(0xFF111111),
    this.borderRadius = 18,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  final double? width;
  final double maxWidth;
  final double? maxHeight;

  final EdgeInsets insetPadding;
  final bool showClose;
  final VoidCallback? onClose;
  final EdgeInsetsGeometry bodyPadding;

  final Color backgroundColor;
  final double borderRadius;

  void _close(BuildContext context) {
    if (onClose != null) {
      onClose!();
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    final availableWidth = (media.size.width - insetPadding.horizontal).clamp(
      280.0,
      maxWidth,
    );

    final resolvedWidth = width == null
        ? availableWidth
        : width!.clamp(280.0, availableWidth);

    final availableHeight = (media.size.height - insetPadding.vertical).clamp(
      240.0,
      double.infinity,
    );

    final resolvedMaxHeight = maxHeight == null
        ? availableHeight
        : maxHeight!.clamp(240.0, availableHeight);

    return Dialog(
      backgroundColor: backgroundColor,
      insetPadding: insetPadding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: resolvedWidth,
          maxHeight: resolvedMaxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProducerModalHeader(
              title: title,
              showClose: showClose,
              onClose: () => _close(context),
            ),
            Flexible(
              child: SingleChildScrollView(padding: bodyPadding, child: child),
            ),
            if (actions.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 8,
                  children: actions,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProducerModalHeader extends StatelessWidget {
  const _ProducerModalHeader({
    required this.title,
    required this.showClose,
    required this.onClose,
  });

  final String title;
  final bool showClose;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo_dark.png',
            height: 30,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              return const Text(
                'EKEFLICKS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (showClose)
            IconButton(
              tooltip: 'Fermer',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
