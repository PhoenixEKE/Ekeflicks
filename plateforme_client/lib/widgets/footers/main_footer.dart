import 'package:flutter/material.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:app_ekeflicks/widgets/footers/base_footer.dart';
import 'package:app_ekeflicks/widgets/dialog/contact_form_dialog.dart';

class MainFooter extends StatelessWidget {
  final bool? isMobile;
  static const _baseFooter = BaseFooter();

  const MainFooter({super.key, this.isMobile});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Si isMobile == true, mobile = true (on considère mobile sans calcul)
    // Sinon, on calcule la largeur d'écran
    final bool mobile = isMobile == true ? true : MediaQuery.of(context).size.width < 800;

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!mobile) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _buildSections(context, mobile),
            ),
            const SizedBox(height: 24),
            const Divider(color: Colors.white54),
            const SizedBox(height: 12),
          ] else ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white54),
            const SizedBox(height: 12),
          ],
          Text(
            loc.footerCopyright,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
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
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context, bool isMobile) {
    final loc = AppLocalizations.of(context)!;

    if (isMobile) {
      return [
        _baseFooter.footerSection(
          title: loc.footerContact,
          childrenWidget: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
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
            ),
          ],
        ),
      ];
    }

    return [
      _baseFooter.footerSection(
        title: loc.footerContact,
        childrenWidget: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
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
          ),
          const SizedBox(height: 6),
          isMobile
              ? MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _baseFooter.openPhone(context, '+2250716096940'),
                    child: Text(
                      "${loc.footerPhone} : +225 07 16 09 69 40",
                      style: const TextStyle(
                        color: Colors.white70,
                        decoration: TextDecoration.underline,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Text(
                  "${loc.footerPhone} : +225 07 16 09 69 40",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
          const SizedBox(height: 6),
          isMobile
              ? MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _baseFooter.openWhatsApp(context, '+2250716096940'),
                    child: Text(
                      "${loc.footerWhatsApp} : +225 07 16 09 69 40",
                      style: const TextStyle(
                        color: Colors.white70,
                        decoration: TextDecoration.underline,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Text(
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
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
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
          ),
          const SizedBox(height: 6),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
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
