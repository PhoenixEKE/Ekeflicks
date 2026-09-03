import 'package:flutter/material.dart';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  bool _accessGranted = false;
  final _codeController = TextEditingController();
  double _availableBalance = 1250.0;

  void _verifyCode() {
    if (_codeController.text == '1234') {
      setState(() => _accessGranted = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.invalid_code,
            style: AppTheme.textBody,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppDecorations.borderRadiusMedium,
            ),
          ),
        ),
      );
    }
  }

  void _showWithdrawalModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return WithdrawalForm(
          availableBalance: _availableBalance,
          onWithdraw: (amount) {
            setState(() {
              _availableBalance -= amount;
            });
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${AppLocalizations.of(context)!.request_withdrawal} ${amount.toStringAsFixed(2)} € ${AppLocalizations.of(context)!.success}',
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
          },
        );
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDecorations.borderRadiusLarge),
        ),
      ),
      backgroundColor: AppTheme.cardBackground,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_accessGranted) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(AppTheme.paddingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: AppTheme.primary),
                const SizedBox(height: 24),
                Text(
                  l10n.secure_access,
                  style: AppTheme.textTitle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.enter_pin,
                  textAlign: TextAlign.center,
                  style: AppTheme.textCaption,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _codeController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    letterSpacing: 4,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: AppDecorations.inputDecoration.copyWith(
                    hintText: '••••',
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _verifyCode,
                    style: AppDecorations.elevatedButtonStyle,
                    child: Text(
                      l10n.validate.toUpperCase(),
                      style: AppTheme.textBodyBold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.my_finances, style: AppTheme.textTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.background,
      ),
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppDecorations.borderRadiusMedium,
                ),
              ),
              color: AppTheme.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingLarge),
                child: Column(
                  children: [
                    Text(
                      l10n.available_balance.toUpperCase(),
                      style: AppTheme.textCaption,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_availableBalance €',
                      style: AppTheme.textTitle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.success,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.divider),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoItem(l10n.last_withdrawal, '250 €'),
                        _buildInfoItem(l10n.date, '01/08/2025'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppDecorations.borderRadiusMedium,
                ),
              ),
              color: AppTheme.cardBackground,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                      AppDecorations.borderRadiusSmall,
                    ),
                  ),
                  child: Icon(Icons.pending_actions, color: AppTheme.orange),
                ),
                title: Text(
                  l10n.pending_payments,
                  style: AppTheme.textBodyBold,
                ),
                subtitle: Text(
                  l10n.available_in_48h,
                  style: AppTheme.textCaption,
                ),
                trailing: Text('500 €', style: AppTheme.textBodyBold),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showWithdrawalModal,
                icon: Icon(Icons.monetization_on, color: AppTheme.textPrimary),
                label: Text(
                  l10n.request_withdrawal,
                  style: AppTheme.textBodyBold,
                ),
                style: AppDecorations.elevatedButtonStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.textCaption),
        const SizedBox(height: 4),
        Text(value, style: AppTheme.textBodyBold),
      ],
    );
  }
}

class WithdrawalForm extends StatefulWidget {
  final double availableBalance;
  final Function(double) onWithdraw;

  const WithdrawalForm({
    super.key,
    required this.availableBalance,
    required this.onWithdraw,
  });

  @override
  State<WithdrawalForm> createState() => _WithdrawalFormState();
}

class _WithdrawalFormState extends State<WithdrawalForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ibanController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedMethod = 'MTN';
  bool _isLoading = false;

  final List<String> _paymentMethods = ['MTN', 'Wave', 'Orange', 'Moov', 'RIB'];

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _ibanController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 2), () {
      final amount = double.parse(_amountController.text);
      widget.onWithdraw(amount);
      setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppTheme.paddingMedium,
        right: AppTheme.paddingMedium,
        top: AppTheme.paddingMedium,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.withdrawal_request, style: AppTheme.textTitle),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: AppDecorations.inputDecoration.copyWith(
                labelText: l10n.amount,
                prefixIcon: Icon(Icons.euro, color: AppTheme.primary),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.enter_amount;
                }
                final amount = double.tryParse(value) ?? 0;
                if (amount <= 0) {
                  return l10n.amount_positive;
                }
                if (amount > widget.availableBalance) {
                  return l10n.amount_exceeds_balance(
                    widget.availableBalance.toStringAsFixed(2),
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              items: _paymentMethods.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method, style: AppTheme.textBody),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedMethod = value!);
              },
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: AppDecorations.inputDecoration.copyWith(
                labelText: l10n.payment_method,
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedMethod != 'RIB')
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: AppDecorations.inputDecoration.copyWith(
                  labelText: l10n.phone_number,
                  prefixIcon: Icon(Icons.phone, color: AppTheme.primary),
                ),
                validator: (value) {
                  if (_selectedMethod != 'RIB' &&
                      (value == null || value.isEmpty)) {
                    return l10n.enter_number;
                  }
                  return null;
                },
              ),
            if (_selectedMethod == 'RIB')
              Column(
                children: [
                  TextFormField(
                    controller: _ibanController,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: AppDecorations.inputDecoration.copyWith(
                      labelText: l10n.iban,
                      prefixIcon: Icon(
                        Icons.account_balance,
                        color: AppTheme.primary,
                      ),
                    ),
                    validator: (value) {
                      if (_selectedMethod == 'RIB' &&
                          (value == null || value.isEmpty)) {
                        return l10n.enter_iban;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: AppTheme.textPrimary),
                    decoration: AppDecorations.inputDecoration.copyWith(
                      labelText: l10n.beneficiary_name,
                      prefixIcon: Icon(Icons.person, color: AppTheme.primary),
                    ),
                    validator: (value) {
                      if (_selectedMethod == 'RIB' &&
                          (value == null || value.isEmpty)) {
                        return l10n.enter_name;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: AppDecorations.elevatedButtonStyle,
                child: _isLoading
                    ? CircularProgressIndicator(color: AppTheme.textPrimary)
                    : Text(
                        l10n.confirm_withdrawal.toUpperCase(),
                        style: AppTheme.textBodyBold,
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
