import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class ClaimsManagementPage extends StatefulWidget {
  const ClaimsManagementPage({super.key});

  @override
  State<ClaimsManagementPage> createState() => _ClaimsManagementPageState();
}

class _ClaimsManagementPageState extends State<ClaimsManagementPage> {
  final List<Map<String, dynamic>> _allClaims = [];
  List<Map<String, dynamic>> _filteredClaims = [];
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'all';
  bool _isAdminView = true;
  List<String> _selectedClaims = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterClaims);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _loadSampleClaims();
      _initialized = true;
    }
  }

  void _loadSampleClaims() {
    try {
      final l10n = AppLocalizations.of(context)!;
      
      setState(() {
        _allClaims.addAll([
          {
            'id': '001',
            'title': l10n.payment_not_received,
            'status': 'pending',
            'statusLabel': l10n.claim_status_in_progress,
            'date': '15/08/2023',
            'description': l10n.payment_issue_desc,
            'priority': 'high',
            'priorityLabel': l10n.high_priority,
            'clientEmail': 'client1@example.com',
            'response': '',
            'attachments': [],
          },
          {
            'id': '002',
            'title': l10n.video_rejected,
            'status': 'resolved',
            'statusLabel': l10n.claim_status_resolved,
            'date': '10/08/2023',
            'description': l10n.rejection_issue_desc,
            'priority': 'medium',
            'priorityLabel': l10n.medium_priority,
            'clientEmail': 'client2@example.com',
            'response': l10n.rejection_response,
            'attachments': ['document.pdf'],
          },
        ]);
        _filteredClaims = List.from(_allClaims);
      });
    } catch (e) {
      debugPrint('Error loading claims: $e');
      setState(() {
        _filteredClaims = [];
      });
    }
  }

  void _filterClaims() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClaims = _allClaims.where((claim) {
        final matchesSearch = claim['title'].toLowerCase().contains(query) ||
            claim['description'].toLowerCase().contains(query) ||
            claim['clientEmail'].toLowerCase().contains(query);
        
        final matchesStatus = _filterStatus == 'all' || 
            claim['status'] == _filterStatus;
        
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _updateClaimStatus(String claimId, String newStatus) {
    setState(() {
      final claim = _allClaims.firstWhere((c) => c['id'] == claimId);
      claim['status'] = newStatus;
      claim['statusLabel'] = _getStatusLabel(newStatus);
      _filterClaims();
    });
  }

  String _getStatusLabel(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'pending': return l10n.claim_status_in_progress;
      case 'resolved': return l10n.claim_status_resolved;
      case 'rejected': return l10n.claim_status_rejected;
      default: return status;
    }
  }

  void _navigateToCommunicationPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CommunicationPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.claims_management, style: AppTheme.textTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            tooltip: l10n.communication_tooltip,
            onPressed: _navigateToCommunicationPage,
          ),
        ],
        backgroundColor: AppTheme.cardBackground,
        elevation: 1,
      ),
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.paddingMedium),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: AppDecorations.inputDecoration.copyWith(
                    hintText: l10n.search_claims,
                    prefixIcon: Icon(Icons.search, color: AppTheme.primary),
                  ),
                  style: AppTheme.textBody,
                ),
                const SizedBox(height: 12),
                if (_isAdminView)
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filterStatus,
                          items: [
                            DropdownMenuItem(
                              value: 'all',
                              child: Text(l10n.all_statuses),
                            ),
                            DropdownMenuItem(
                              value: 'pending',
                              child: Text(l10n.claim_status_in_progress),
                            ),
                            DropdownMenuItem(
                              value: 'resolved',
                              child: Text(l10n.claim_status_resolved),
                            ),
                            DropdownMenuItem(
                              value: 'rejected',
                              child: Text(l10n.claim_status_rejected),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filterStatus = value!;
                              _filterClaims();
                            });
                          },
                          decoration: InputDecoration(
                            labelText: l10n.filter_by_status,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: _filteredClaims.isEmpty
                ? Center(child: Text(l10n.no_claims_found))
                : ListView.builder(
                    itemCount: _filteredClaims.length,
                    itemBuilder: (_, index) {
                      final claim = _filteredClaims[index];
                      return _buildClaimCard(context, claim);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _isAdminView
          ? null
          : FloatingActionButton(
              onPressed: () => _showNewClaimDialog(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildClaimCard(BuildContext context, Map<String, dynamic> claim) {
    final l10n = AppLocalizations.of(context)!;
    
    Color statusColor;
    IconData statusIcon;
    switch (claim['status']) {
      case 'resolved':
        statusColor = AppTheme.success;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = AppTheme.warning;
        statusIcon = Icons.access_time;
        break;
      case 'rejected':
        statusColor = AppTheme.error;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppTheme.disabled;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium, 
        vertical: AppTheme.paddingSmall,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDecorations.borderRadiusMedium),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDecorations.borderRadiusMedium),
        onTap: () => _showClaimDetails(context, claim),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                claim['title'],
                style: AppTheme.textSubtitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                claim['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.textCaption,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    claim['date'],
                    style: AppTheme.textCaption,
                  ),
                  const Spacer(),
                  Icon(Icons.priority_high, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    claim['priorityLabel'],
                    style: AppTheme.textCaption,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, 
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          claim['statusLabel'],
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (_isAdminView && claim['status'] == 'pending')
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, size: 20),
                          color: AppTheme.success,
                          onPressed: () => _updateClaimStatus(claim['id'], 'resolved'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          color: AppTheme.error,
                          onPressed: () => _updateClaimStatus(claim['id'], 'rejected'),
                        ),
                      ],
                    ),
                ],
              ),
              if (claim['status'] == 'resolved' && claim['response'].isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Divider(color: AppTheme.divider),
                    const SizedBox(height: 8),
                    Text(
                      l10n.support_response,
                      style: AppTheme.textBodyBold.copyWith(
                        color: AppTheme.success,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      claim['response'],
                      style: AppTheme.textBodyItalic,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClaimDetails(BuildContext context, Map<String, dynamic> claim) {
    final l10n = AppLocalizations.of(context)!;
    final responseController = TextEditingController(text: claim['response']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDecorations.borderRadiusLarge),
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppTheme.paddingMedium,
            right: AppTheme.paddingMedium,
            top: AppTheme.paddingMedium,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.divider.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                claim['title'],
                style: AppTheme.textTitle,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(context, l10n.status, claim['statusLabel']),
              _buildDetailRow(context, l10n.date, claim['date']),
              _buildDetailRow(context, l10n.priority, claim['priorityLabel']),
              _buildDetailRow(context, l10n.email, claim['clientEmail']),
              const SizedBox(height: 16),
              Text(
                l10n.description,
                style: AppTheme.textSubtitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                claim['description'],
                style: AppTheme.textBody,
              ),
              if (claim['attachments'].isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.attachments,
                  style: AppTheme.textSubtitle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: claim['attachments'].map<Widget>((file) {
                    return Chip(
                      label: Text(file),
                      onDeleted: () {
                        // TODO: Implement attachment deletion
                      },
                    );
                  }).toList(),
                ),
              ],
              if (_isAdminView) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.response,
                  style: AppTheme.textSubtitle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: responseController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: l10n.enter_response,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ] else if (claim['status'] == 'resolved' && claim['response'].isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.support_response,
                  style: AppTheme.textBodyBold.copyWith(
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(AppDecorations.borderRadiusSmall),
                  ),
                  child: Text(
                    claim['response'],
                    style: AppTheme.textBodyItalic,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_isAdminView)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            claim['response'] = responseController.text;
                            if (claim['status'] != 'resolved' && responseController.text.isNotEmpty) {
                              claim['status'] = 'resolved';
                              claim['statusLabel'] = l10n.claim_status_resolved;
                            }
                          });
                          Navigator.pop(context);
                        },
                        child: Text(l10n.save),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.close),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: AppTheme.textBodyBold,
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.textBody,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showNewClaimDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String priority = 'medium';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.new_claim,
          style: AppTheme.textSubtitle,
        ),
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDecorations.borderRadiusMedium),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: AppDecorations.inputDecoration.copyWith(
                    labelText: l10n.claim_title,
                  ),
                  validator: (value) =>
                      value!.isEmpty ? l10n.required_field : null,
                  style: AppTheme.textBody,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: AppDecorations.inputDecoration.copyWith(
                    labelText: l10n.claim_description,
                    alignLabelWithHint: true,
                  ),
                  validator: (value) =>
                      value!.isEmpty ? l10n.required_field : null,
                  style: AppTheme.textBody,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: priority,
                  items: [
                    DropdownMenuItem(
                      value: 'high',
                      child: Text(l10n.high_priority),
                    ),
                    DropdownMenuItem(
                      value: 'medium',
                      child: Text(l10n.medium_priority),
                    ),
                    DropdownMenuItem(
                      value: 'low',
                      child: Text(l10n.low_priority),
                    ),
                  ],
                  decoration: AppDecorations.inputDecoration.copyWith(
                    labelText: l10n.priority,
                  ),
                  onChanged: (value) => priority = value!,
                  style: AppTheme.textBody,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: AppTheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newClaim = {
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'title': titleController.text,
                  'status': 'pending',
                  'statusLabel': l10n.claim_status_in_progress,
                  'date': '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  'description': descriptionController.text,
                  'priority': priority,
                  'priorityLabel': priority == 'high'
                      ? l10n.high_priority
                      : priority == 'medium'
                          ? l10n.medium_priority
                          : l10n.low_priority,
                  'clientEmail': 'current_user@example.com',
                  'response': '',
                  'attachments': [],
                };

                setState(() {
                  _allClaims.add(newClaim);
                  _filterClaims();
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.claim_submitted,
                      style: AppTheme.textBody,
                    ),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDecorations.borderRadiusMedium),
                    ),
                  ),
                );
              }
            },
            style: AppDecorations.elevatedButtonStyle,
            child: Text(
              l10n.submit,
              style: AppTheme.textBodyBold,
            ),
          ),
        ],
      ),
    );
  }
}

class CommunicationPage extends StatefulWidget {
  const CommunicationPage({super.key});

  @override
  State<CommunicationPage> createState() => _CommunicationPageState();
}

class _CommunicationPageState extends State<CommunicationPage> {
  final List<Map<String, dynamic>> _recipients = [];
  final List<String> _selectedRecipients = [];
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isEmail = true;
  bool _isGroup = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  Future<void> _loadRecipients() async {
    // Simulate async loading
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _recipients.addAll([
        {
          'email': 'user1@example.com',
          'name': 'Jean Dupont',
          'type': 'user',
        },
        {
          'email': 'producer1@example.com',
          'name': 'Farm Fresh',
          'type': 'producer',
        },
        {
          'email': 'user2@example.com',
          'name': 'Marie Martin',
          'type': 'user',
        },
        {
          'email': 'producer2@example.com',
          'name': 'Organic Valley',
          'type': 'producer',
        },
      ]);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.communication_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _selectedRecipients.isNotEmpty ? _showSendDialog : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCommunicationTypeSelector(l10n),
                _buildMessageComposer(l10n),
                _buildRecipientsList(l10n),
              ],
            ),
    );
  }

  Widget _buildCommunicationTypeSelector(AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.communication_type, style: AppTheme.textSubtitle),
            Row(
              children: [
                ChoiceChip(
                  label: Text(l10n.email),
                  selected: _isEmail,
                  onSelected: (selected) => setState(() {
                    _isEmail = true;
                    _isGroup = false;
                  }),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l10n.notification),
                  selected: !_isEmail,
                  onSelected: (selected) => setState(() => _isEmail = false),
                ),
              ],
            ),
            if (_isEmail) ...[
              const SizedBox(height: 8),
              Text(l10n.sending_mode, style: AppTheme.textSubtitle),
              Row(
                children: [
                  ChoiceChip(
                    label: Text(l10n.individual),
                    selected: !_isGroup,
                    onSelected: _isGroup ? (selected) => setState(() => _isGroup = false) : null,
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(l10n.group),
                    selected: _isGroup,
                    onSelected: !_isGroup ? (selected) => setState(() => _isGroup = true) : null,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer(AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: l10n.subject,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.message,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientsList(AppLocalizations l10n) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${_selectedRecipients.length} ${l10n.selected_recipients}',
              style: AppTheme.textCaption,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _recipients.length,
              itemBuilder: (context, index) {
                final recipient = _recipients[index];
                return CheckboxListTile(
                  title: Text(recipient['name']),
                  subtitle: Text(recipient['email']),
                  secondary: Icon(
                    recipient['type'] == 'user' ? Icons.person : Icons.agriculture,
                    color: AppTheme.primary,
                  ),
                  value: _selectedRecipients.contains(recipient['email']),
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedRecipients.add(recipient['email']);
                      } else {
                        _selectedRecipients.remove(recipient['email']);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSendDialog() {
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirm_send),
        content: Text(
          _isEmail
              ? _isGroup
                  ? l10n.confirm_group_email(_selectedRecipients.length)
                  : l10n.confirm_individual_email
              : l10n.confirm_notification(_selectedRecipients.length),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendCommunication();
            },
            child: Text(l10n.send),
          ),
        ],
      ),
    );
  }

  Future<void> _sendCommunication() async {
    if (_isEmail) {
      await _sendEmail();
    } else {
      await _sendNotification();
    }
  }

  Future<void> _sendEmail() async {
    final recipients = _isGroup 
        ? _selectedRecipients.join(',')
        : _selectedRecipients.first;

    final uri = Uri(
      scheme: 'mailto',
      path: recipients,
      queryParameters: {
        'subject': _subjectController.text.isNotEmpty 
            ? _subjectController.text 
            : 'Message de la plateforme',
        'body': _messageController.text.isNotEmpty
            ? _messageController.text
            : 'Cher destinataire,',
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      _showSuccessSnackbar();
    } else {
      _showErrorSnackbar();
    }
  }

  Future<void> _sendNotification() async {
    // Implementation with Firebase or your backend
    await Future.delayed(const Duration(seconds: 1));
    _showSuccessSnackbar();
  }

  void _showSuccessSnackbar() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEmail ? l10n.email_sent : l10n.notification_sent),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _showErrorSnackbar() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEmail ? l10n.email_error : l10n.notification_error),
        backgroundColor: AppTheme.error,
      ),
    );
  }
}