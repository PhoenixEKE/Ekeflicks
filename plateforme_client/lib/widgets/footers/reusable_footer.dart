import 'package:flutter/material.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/widgets/footers/base_footer.dart';
import 'package:app_ekeflicks/widgets/dialog/contact_form_dialog.dart';

/// Footer réutilisable qui ne s'affiche que sur les écrans larges (desktop)
/// Version simplifiée qui disparaît complètement sur mobile
class ReusableFooter extends StatelessWidget {
  const ReusableFooter({super.key});

  static const _baseFooter = BaseFooter();

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;
    if (isMobile) return const SizedBox.shrink(); // Ne rien afficher sur mobile

    final loc = AppLocalizations.of(context)!;

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _buildSections(context),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white54),
          const SizedBox(height: 12),
          Text(
            loc.footerCopyright,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${loc.footerFollowUs} : ",
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 8),
              _baseFooter.socialIcon(context, 'assets/social/facebook.svg', 'https://facebook.com/ekeflicks'),
              _baseFooter.socialIcon(context, 'assets/social/instagram.svg', 'https://instagram.com/ekeflicks'),
              _baseFooter.socialIcon(context, 'assets/social/tiktok.svg', 'https://tiktok.com/@ekeflicks'),
              _baseFooter.socialIcon(context, 'assets/social/whatsapp.svg', 'https://wa.me/2250716096940'),
              _baseFooter.socialIcon(context, 'assets/social/youtube.svg', 'https://youtube.com/ekeflicks'),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return [
      _baseFooter.footerSection(
        title: loc.footerContact,
        childrenWidget: [
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const ContactFormDialog(),
              );
            },
            child: Text(
              "${loc.footerEmail} : support@ekeflicks.com",
              style: const TextStyle(
                color: Colors.white70,
                decoration: TextDecoration.underline,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "${loc.footerPhone} : +225 07 16 09 69 40",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            "${loc.footerWhatsApp} : +225 07 16 09 69 40",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      _baseFooter.footerSection(
        title: loc.footerCompany,
        childrenWidget: [
          InkWell(
            onTap: () => Navigator.of(context).pushNamed('/privacy'),
            child: Text(
              loc.footerPrivacyPolicy,
              style: const TextStyle(
                color: Colors.white70,
                decoration: TextDecoration.underline,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => Navigator.of(context).pushNamed('/terms'),
            child: Text(
              loc.footerTerms,
              style: const TextStyle(
                color: Colors.white70,
                decoration: TextDecoration.underline,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      _baseFooter.footerSection(
        title: loc.footerDownloadApp,
        childrenWidget: [
          SizedBox(
            height: 60,
            child: Image.asset(
              'assets/images/app_download.webp',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      _baseFooter.footerSection(
        title: loc.footerPaymentMethods,
        childrenWidget: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _baseFooter.paymentIcon('assets/payments/visa.svg'),
              _baseFooter.paymentIcon('assets/payments/mastercard.svg'),
              _baseFooter.paymentIcon('assets/payments/mobilemoney.svg'),
            ],
          ),
        ],
      ),
    ];
  }
}
