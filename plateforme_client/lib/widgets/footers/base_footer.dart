import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

/// Classe de base pour les fonctionnalités communes des footers
class BaseFooter {
  const BaseFooter();

  /// Méthode pour ouvrir une URL
  Future<void> openUrl(BuildContext context, String url, {LaunchMode mode = LaunchMode.externalApplication}) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: mode);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir le lien')),
        );
      }
    }
  }

  /// Méthode pour lancer un appel téléphonique
  Future<void> openPhone(BuildContext context, String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    await openUrl(context, uri.toString(), mode: LaunchMode.externalApplication);
  }

  /// Méthode pour lancer WhatsApp
  Future<void> openWhatsApp(BuildContext context, String phoneNumber) async {
    final whatsappUrl = "https://wa.me/$phoneNumber";
    await openUrl(context, whatsappUrl, mode: LaunchMode.externalApplication);
  }

  /// Widget pour les icônes de paiement
  Widget paymentIcon(String assetPath) {
    final isSvg = assetPath.toLowerCase().endsWith('.svg');
    return SizedBox(
      width: 60,
      height: 60,
      child: Center(
        child: isSvg
            ? SvgPicture.asset(
                assetPath,
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              )
            : Image.asset(
                assetPath,
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
      ),
    );
  }

  /// Widget pour les icônes sociales
  Widget socialIcon(BuildContext context, String assetPath, String url) {
    const iconSize = 24.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => openUrl(context, url),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Center(
            child: SvgPicture.asset(
              assetPath,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  /// Section générique de footer
  Widget footerSection({
    required String title,
    List<Widget>? childrenWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (childrenWidget != null) ...childrenWidget,
      ],
    );
  }
}
