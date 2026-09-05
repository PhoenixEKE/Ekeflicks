import 'package:flutter/material.dart';
import 'package:app_ekeflicks/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ContactFormDialog extends StatefulWidget {
  const ContactFormDialog({super.key});

  @override
  State<ContactFormDialog> createState() => _ContactFormDialogState();
}

class _ContactFormDialogState extends State<ContactFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final uri = Uri(
        scheme: 'mailto',
        path: 'support@ekeflicks.com',
        query: Uri.encodeFull(
          'subject=Contact EKEFlicks&body='
          'Nom: ${_nameController.text}\n'
          'Email: ${_emailController.text}\n\n'
          '${_messageController.text}',
        ),
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        if (mounted) Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir l\'application email'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, theme, loc),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildFormFields(loc),
                    const SizedBox(height: 20),
                    _buildSubmitButton(theme, loc),
                    if (isMobile) _buildMobileContactOptions(theme, loc),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    AppLocalizations loc,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.email, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              loc.contactUs,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(AppLocalizations loc) {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: loc.name,
            prefixIcon: const Icon(Icons.person),
          ),
          validator: (val) => val!.isEmpty ? loc.fieldRequired : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: loc.email,
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          validator: (val) => val!.contains('@') ? null : loc.invalidEmail,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _messageController,
          decoration: InputDecoration(
            labelText: loc.message,
            prefixIcon: const Icon(Icons.message_outlined),
          ),
          maxLines: 5,
          validator: (val) => val!.isEmpty ? loc.fieldRequired : null,
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme, AppLocalizations loc) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.send),
      onPressed: _submit,
      label: Text(loc.send),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: theme.primaryColor,
      ),
    );
  }

  Widget _buildMobileContactOptions(ThemeData theme, AppLocalizations loc) {
    return Column(
      children: [
        const SizedBox(height: 30),
        const Divider(),
        const SizedBox(height: 10),
        Text(loc.orContactUsMobile, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 10),
        _buildWhatsAppButton(),
        const SizedBox(height: 10),
        _buildPhoneButton(),
      ],
    );
  }

  Widget _buildWhatsAppButton() {
    return ElevatedButton.icon(
      onPressed: () => launchUrl(Uri.parse('https://wa.me/2250716096940')),
      icon: SizedBox(
        width: 24,
        height: 24,
        child: SvgPicture.asset(
          'assets/social/whatsapp.svg',
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
      label: const Text('WhatsApp : +225 07 16 09 69 40'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        minimumSize: const Size.fromHeight(50),
      ),
    );
  }

  Widget _buildPhoneButton() {
    return ElevatedButton.icon(
      onPressed: () => launchUrl(Uri.parse('tel:+2250716096940')),
      icon: const Icon(Icons.phone),
      label: const Text('Tel : +225 07 16 09 69 40'),
      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
    );
  }
}
