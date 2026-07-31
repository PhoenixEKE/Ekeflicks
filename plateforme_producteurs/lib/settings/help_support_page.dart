import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  late YoutubePlayerController _ytController;
  
  final List<Map<String, String>> _videoTutorials = const [
    {"id": "video1", "icon": "account_circle"},
    {"id": "video2", "icon": "inventory_2"},
    {"id": "video3", "icon": "receipt_long"},
  ];

  final List<String> _faqIds = const ["faq1", "faq2"];

  @override
  void initState() {
    super.initState();
    _ytController = YoutubePlayerController(
      initialVideoId: 'EXEMPLE1',
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _ytController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  void _playVideo(String videoId) {
    _ytController.load(videoId);
    _ytController.play();
  }

  // Méthode pour obtenir les traductions des vidéos
  String _getVideoTitle(AppLocalizations l10n, String videoId) {
    switch (videoId) {
      case 'video1':
        return l10n.helpSupportVideo1Title;
      case 'video2':
        return l10n.helpSupportVideo2Title;
      case 'video3':
        return l10n.helpSupportVideo3Title;
      default:
        return '';
    }
  }

  // Méthode pour obtenir les questions FAQ
  String _getFaqQuestion(AppLocalizations l10n, String faqId) {
    switch (faqId) {
      case 'faq1':
        return l10n.helpSupportFaq1Question;
      case 'faq2':
        return l10n.helpSupportFaq2Question;
      default:
        return '';
    }
  }

  // Méthode pour obtenir les réponses FAQ
  String _getFaqAnswer(AppLocalizations l10n, String faqId) {
    switch (faqId) {
      case 'faq1':
        return l10n.helpSupportFaq1Answer;
      case 'faq2':
        return l10n.helpSupportFaq2Answer;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpSupportTitle),
        centerTitle: true,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Section Hero
          SliverToBoxAdapter(
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.blue.shade900, Colors.blue.shade700]
                      : [Colors.blue.shade50, Colors.blue.shade100],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.help_center, size: 48, color: theme.primaryColor),
                    const SizedBox(height: 12),
                    Text(
                      l10n.helpCenterTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Player YouTube intégré
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: YoutubePlayer(
                  controller: _ytController,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.blueAccent,
                ),
              ),
            ),
          ),

          // Section Tutoriels vidéo
          SliverPadding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                l10n.videoTutorialsTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildVideoItem(context, _videoTutorials[index], l10n),
              childCount: _videoTutorials.length,
            ),
          ),

          // Section FAQ
          SliverPadding(
            padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                l10n.faqTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildFaqItem(context, _faqIds[index], l10n),
              childCount: _faqIds.length,
            ),
          ),

          // Section Contact
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.contactSupportTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactInfo(
                    icon: Icons.email,
                    label: l10n.contactEmailLabel,
                    value: l10n.contactEmail,
                    onTap: () => _launchUrl('mailto:${l10n.contactEmail}'),
                  ),
                  _buildContactInfo(
                    icon: Icons.phone,
                    label: l10n.contactPhoneFrLabel,
                    value: l10n.contactPhoneFr,
                    onTap: () => _launchUrl('tel:${l10n.contactPhoneFr.replaceAll(' ', '')}'),
                  ),
                  _buildContactInfo(
                    icon: Icons.phone,
                    label: l10n.contactPhoneCiLabel,
                    value: l10n.contactPhoneCi,
                    onTap: () => _launchUrl('tel:${l10n.contactPhoneCi.replaceAll(' ', '')}'),
                  ),
                  _buildContactInfo(
                    icon: Icons.chat,
                    label: l10n.contactWhatsAppLabel,
                    value: l10n.contactWhatsApp,
                    onTap: () => _launchUrl('https://wa.me/${l10n.contactWhatsApp.replaceAll(' ', '')}'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoItem(BuildContext context, Map<String, String> video, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _playVideo('EXEMPLE${video['id']?.substring(video['id']!.length - 1)}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                _getIconData(video['icon']!),
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _getVideoTitle(l10n, video['id']!),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Icon(Icons.play_circle_filled, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String faqId, AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text(_getFaqQuestion(l10n, faqId)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_getFaqAnswer(l10n, faqId)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    value,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'account_circle':
        return Icons.account_circle;
      case 'inventory_2':
        return Icons.inventory_2;
      case 'receipt_long':
        return Icons.receipt_long;
      default:
        return Icons.help_outline;
    }
  }
}