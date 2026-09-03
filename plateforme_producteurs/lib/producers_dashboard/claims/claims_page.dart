import 'package:flutter/material.dart';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';

class ClaimsPage extends StatelessWidget {
  const ClaimsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final claims = [
      {
        'title': l10n.payment_not_received,
        'status': l10n.claim_status_in_progress,
        'date': '15/08/2023',
        'description': l10n.payment_issue_desc,
        'priority': l10n.high_priority,
        'response': '',
      },
      {
        'title': l10n.video_rejected,
        'status': l10n.claim_status_resolved,
        'date': '10/08/2023',
        'description': l10n.rejection_issue_desc,
        'priority': l10n.medium_priority,
        'response': l10n.rejection_response,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.my_claims, style: AppTheme.textTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.textPrimary),
            onPressed: () => _showNewClaimDialog(context),
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
            child: TextField(
              decoration: AppDecorations.inputDecoration.copyWith(
                hintText: l10n.search_claims,
                prefixIcon: Icon(Icons.search, color: AppTheme.primary),
              ),
              style: AppTheme.textBody,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: claims.length,
              itemBuilder: (_, index) {
                final claim = claims[index];
                return _buildClaimCard(context, claim);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimCard(BuildContext context, Map<String, String> claim) {
    final l10n = AppLocalizations.of(context)!;

    Color statusColor;
    IconData statusIcon;
    switch (claim['status']) {
      case 'Résolu':
      case 'Resolved':
        statusColor = AppTheme.success;
        statusIcon = Icons.check_circle;
        break;
      case 'En cours':
      case 'In Progress':
        statusColor = AppTheme.warning;
        statusIcon = Icons.access_time;
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
      color: AppTheme.cardBackground,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDecorations.borderRadiusMedium),
        onTap: () => _showClaimDetails(context, claim),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      claim['title']!,
                      style: AppTheme.textSubtitle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          claim['status']!,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                claim['description']!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.textCaption,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(claim['date']!, style: AppTheme.textCaption),
                  const Spacer(),
                  Icon(
                    Icons.priority_high,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(claim['priority']!, style: AppTheme.textCaption),
                ],
              ),
              if (claim['status'] == l10n.claim_status_resolved &&
                  claim['response']!.isNotEmpty)
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
                    Text(claim['response']!, style: AppTheme.textBodyItalic),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClaimDetails(BuildContext context, Map<String, String> claim) {
    final l10n = AppLocalizations.of(context)!;

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
                    color: AppTheme.divider.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(claim['title']!, style: AppTheme.textTitle),
              const SizedBox(height: 16),
              _buildDetailRow(context, l10n.status, claim['status']!),
              _buildDetailRow(context, l10n.date, claim['date']!),
              _buildDetailRow(context, l10n.priority, claim['priority']!),
              const SizedBox(height: 16),
              Text(
                l10n.description,
                style: AppTheme.textSubtitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(claim['description']!, style: AppTheme.textBody),
              if (claim['status'] == l10n.claim_status_resolved &&
                  claim['response']!.isNotEmpty) ...[
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
                    borderRadius: BorderRadius.circular(
                      AppDecorations.borderRadiusSmall,
                    ),
                  ),
                  child: Text(
                    claim['response']!,
                    style: AppTheme.textBodyItalic,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: AppDecorations.elevatedButtonStyle,
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
          Text('$label : ', style: AppTheme.textBodyBold),
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
    String priority = l10n.medium_priority;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.new_claim, style: AppTheme.textSubtitle),
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            AppDecorations.borderRadiusMedium,
          ),
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
                  items:
                      [
                            l10n.high_priority,
                            l10n.medium_priority,
                            l10n.low_priority,
                          ]
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text(p, style: AppTheme.textBody),
                            ),
                          )
                          .toList(),
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
            child: Text(l10n.cancel, style: TextStyle(color: AppTheme.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
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
                      borderRadius: BorderRadius.circular(
                        AppDecorations.borderRadiusMedium,
                      ),
                    ),
                  ),
                );
              }
            },
            style: AppDecorations.elevatedButtonStyle,
            child: Text(l10n.submit, style: AppTheme.textBodyBold),
          ),
        ],
      ),
    );
  }
}
