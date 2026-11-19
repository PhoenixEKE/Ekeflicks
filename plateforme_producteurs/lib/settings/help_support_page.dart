import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'package:plateforme_producteurs/widgets/producer_page_shell.dart';
import 'package:plateforme_producteurs/services/producer_service.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _emailReasonController = TextEditingController();
  List<Map<String, dynamic>> _requests = const [];
  List<Map<String, dynamic>> _emailRequests = const [];
  List<Map<String, dynamic>> _faqEntries = const [];
  bool _sending = false;
  bool _sendingEmailChange = false;
  bool _loadingRequests = true;
  bool _loadingFaq = true;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _newEmailController.dispose();
    _emailReasonController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _loadFaq();
  }

  Future<void> _loadRequests() async {
    try {
      final requests = await ProducerService.instance.getSupportRequests();
      final emailRequests = await ProducerService.instance.getEmailChangeRequests();
      if (mounted) setState(() { _requests = requests; _emailRequests = emailRequests; });
    } catch (_) {
      // Support contact remains available even if request history is offline.
    } finally {
      if (mounted) setState(() => _loadingRequests = false);
    }
  }

  Future<void> _loadFaq() async {
    try {
      final rows = await ProducerService.instance.getProducerFaq();
      if (mounted) setState(() => _faqEntries = rows);
    } catch (_) {
      // Support remains available if the FAQ service is temporarily offline.
    } finally {
      if (mounted) setState(() => _loadingFaq = false);
    }
  }

  String _statusLabel(String value) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    switch (value) {
      case 'pending': return english ? 'Pending' : 'En attente';
      case 'in_progress': return english ? 'In progress' : 'En cours';
      case 'resolved': return english ? 'Resolved' : 'Résolue';
      case 'closed': return english ? 'Closed' : 'Fermée';
      case 'rejected': return english ? 'Rejected' : 'Refusée';
      case 'cancelled': return english ? 'Cancelled' : 'Annulée';
      default: return value;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Future<void> _sendSupportMessage() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner le sujet et votre message.')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await ProducerService.instance.createSupportRequest(subject: subject, message: message);
      _subjectController.clear();
      _messageController.clear();
      await _loadRequests();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Localizations.localeOf(context).languageCode == 'en' ? 'Your request was sent.' : 'Votre demande a été envoyée.')),
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendEmailChangeRequest() async {
    final email = _newEmailController.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(Localizations.localeOf(context).languageCode == 'en' ? 'Enter a valid new email address.' : 'Saisissez une nouvelle adresse e-mail valide.'),
      ));
      return;
    }
    setState(() => _sendingEmailChange = true);
    try {
      await ProducerService.instance.createEmailChangeRequest(
        requestedEmail: email,
        reason: _emailReasonController.text,
      );
      _newEmailController.clear();
      _emailReasonController.clear();
      await _loadRequests();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(Localizations.localeOf(context).languageCode == 'en' ? 'Your request was sent to EKEFLICKS Support.' : 'Votre demande a été envoyée au support EKEFLICKS.'),
      ));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _sendingEmailChange = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final content = RefreshIndicator(
        onRefresh: _loadRequests,
        child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                    Icon(
                      Icons.help_center,
                      size: 48,
                      color: theme.primaryColor,
                    ),
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
              (context, index) {
                final item = _faqEntries[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ExpansionTile(
                    title: Text(item['question']?.toString() ?? ''),
                    subtitle: Text(item['category']?.toString() ?? ''),
                    children: [Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                      child: Align(alignment: Alignment.centerLeft, child: Text(item['answer']?.toString() ?? '')),
                    )],
                  ),
                );
              },
              childCount: _faqEntries.length,
            ),
          ),
          if (_loadingFaq)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))),
          if (!_loadingFaq && _faqEntries.isEmpty)
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(16), child: Text(Localizations.localeOf(context).languageCode == 'en' ? 'The FAQ could not be loaded.' : 'La FAQ n’a pas pu être chargée.'))),

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
                  TextField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      labelText: Localizations.localeOf(context).languageCode == 'en' ? 'Subject' : 'Sujet',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _messageController,
                    minLines: 4,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: Localizations.localeOf(context).languageCode == 'en' ? 'Your message' : 'Votre message',
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _sending ? null : _sendSupportMessage,
                    icon: const Icon(Icons.send_outlined),
                    label: Text(_sending ? (Localizations.localeOf(context).languageCode == 'en' ? 'Sending…' : 'Envoi…') : (Localizations.localeOf(context).languageCode == 'en' ? 'Send request' : 'Envoyer la demande')),
                  ),
                  const SizedBox(height: 24),
                  Text(Localizations.localeOf(context).languageCode == 'en' ? 'Request an email address change' : 'Demander un changement d’adresse e-mail', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(Localizations.localeOf(context).languageCode == 'en'
                      ? 'Your current address will not change until EKEFLICKS Support reviews your request.'
                      : 'Votre adresse actuelle ne change pas pendant l’examen de la demande par le support EKEFLICKS.'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _newEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: Localizations.localeOf(context).languageCode == 'en' ? 'New email address' : 'Nouvelle adresse e-mail', border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _emailReasonController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(labelText: Localizations.localeOf(context).languageCode == 'en' ? 'Additional details (optional)' : 'Précisions (facultatif)', border: const OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _sendingEmailChange ? null : _sendEmailChangeRequest,
                    icon: const Icon(Icons.mark_email_read_outlined),
                    label: Text(_sendingEmailChange ? (Localizations.localeOf(context).languageCode == 'en' ? 'Sending…' : 'Envoi…') : (Localizations.localeOf(context).languageCode == 'en' ? 'Send request to Support' : 'Envoyer la demande au support')),
                  ),
                  const SizedBox(height: 24),
                  Text(Localizations.localeOf(context).languageCode == 'en' ? 'My requests' : 'Mes demandes', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  if (_loadingRequests) const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator()),
                  if (!_loadingRequests && _requests.isEmpty) Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(Localizations.localeOf(context).languageCode == 'en' ? 'No support requests yet.' : 'Aucune demande au support pour le moment.'),
                  ),
                  ..._requests.map((request) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.support_agent_outlined),
                      title: Text(request['subject']?.toString() ?? ''),
                      subtitle: Text([_statusLabel(request['status']?.toString() ?? ''), if ((request['staff_reply']?.toString() ?? '').isNotEmpty) request['staff_reply'].toString()].join(' • ')),
                      trailing: Text((request['created_at']?.toString() ?? '').split('T').first),
                    ),
                  )),
                  ..._emailRequests.map((request) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.alternate_email),
                      title: Text(Localizations.localeOf(context).languageCode == 'en' ? 'Email change: ${request['requested_email'] ?? ''}' : 'Changement d’e-mail : ${request['requested_email'] ?? ''}'),
                      subtitle: Text(_statusLabel(request['status']?.toString() ?? '')),
                      trailing: Text((request['created_at']?.toString() ?? '').split('T').first),
                    ),
                  )),
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
                    onTap: () => _launchUrl(
                      'tel:${l10n.contactPhoneFr.replaceAll(' ', '')}',
                    ),
                  ),
                  _buildContactInfo(
                    icon: Icons.phone,
                    label: l10n.contactPhoneCiLabel,
                    value: l10n.contactPhoneCi,
                    onTap: () => _launchUrl(
                      'tel:${l10n.contactPhoneCi.replaceAll(' ', '')}',
                    ),
                  ),
                  _buildContactInfo(
                    icon: Icons.chat,
                    label: l10n.contactWhatsAppLabel,
                    value: l10n.contactWhatsApp,
                    onTap: () => _launchUrl(
                      'https://wa.me/${l10n.contactWhatsApp.replaceAll(' ', '')}',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      );
    if (widget.embedded) return content;
    return ProducerPageShell(
      title: l10n.helpCenterTitle,
      showBack: true,
      maxWidth: 1280,
      padding: EdgeInsets.zero,
      child: content,
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
                  Text(value, style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
