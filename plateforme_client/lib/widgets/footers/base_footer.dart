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

  /// Widget pour les icônes de paiement (supporte PNG, JPG, SVG)
  Widget paymentIcon(String assetPath) {
    return Container(
      width: 60,
      height: 60,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: _assetIcon(assetPath, size: 42),
      ),
    );
  }

  /// Widget pour les icônes sociales
  Widget socialIcon(BuildContext context, String assetPath, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => openUrl(context, url),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: _assetIcon(assetPath, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget interne pour charger une image (SVG ou PNG/JPG)
  Widget _assetIcon(String assetPath, {required double size}) {
    final isSvg = assetPath.toLowerCase().endsWith('.svg');
    final isPng = assetPath.toLowerCase().endsWith('.png');
    final isJpg = assetPath.toLowerCase().endsWith('.jpg') || assetPath.toLowerCase().endsWith('.jpeg');

    if (isSvg) {
      return SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
      );
    }

    if (isPng || isJpg) {
      return Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.image_not_supported,
              color: Colors.grey[400],
              size: size * 0.6,
            ),
          );
        },
      );
    }

    // Fallback pour les formats non supportés
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.image,
        color: Colors.grey[400],
        size: size * 0.6,
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
