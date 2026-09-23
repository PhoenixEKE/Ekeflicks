import 'package:flutter/material.dart';

class ProducerSheetHeader extends StatelessWidget {
  const ProducerSheetHeader({
    super.key,
    required this.title,
    this.actions = const <Widget>[],
    this.showClose = true,
    this.onClose,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  });

  final String title;
  final List<Widget> actions;
  final bool showClose;
  final VoidCallback? onClose;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: padding,
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo_dark.png',
            height: 32,
            errorBuilder: (_, __, ___) => const Text(
              'EKEFLICKS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...actions,
          if (showClose)
            IconButton(
              tooltip: 'Fermer',
              onPressed:
                  onClose ??
                  () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
              icon: const Icon(Icons.close, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
