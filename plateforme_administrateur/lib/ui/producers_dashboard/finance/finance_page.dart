import 'package:flutter/material.dart';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/gen/app_localizations.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  runApp(const MaterialApp(home: FinancePage()));
}

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  bool _accessGranted = false;
  final _codeController = TextEditingController();
  double _availableBalance = 1250.0;
  int _totalSubscribers = 1245;
  int _totalViews = 8560;
  String _selectedTimePeriod = 'Mois';
  String _selectedProducer = 'Tous';

  final List<RevenueData> _monthlyRevenue = [
    RevenueData('Jan', 1200),
    RevenueData('Fév', 1800),
    RevenueData('Mar', 1500),
    RevenueData('Avr', 2200),
    RevenueData('Mai', 1900),
    RevenueData('Juin', 2500),
  ];

  final List<ProducerRevenue> _producerRevenues = [
    ProducerRevenue('Farm Fresh', 850, 3200),
    ProducerRevenue('Organic Valley', 620, 2800),
    ProducerRevenue('Green Fields', 450, 1900),
    ProducerRevenue('Happy Farm', 380, 1500),
    ProducerRevenue('Eco Producer', 290, 1200),
  ];

  final List<WithdrawalRequest> _withdrawalRequests = [
    WithdrawalRequest(
      id: '1',
      producerName: 'Farm Fresh',
      amount: 850.0,
      method: 'MTN',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    WithdrawalRequest(
      id: '2',
      producerName: 'Organic Valley',
      amount: 620.0,
      method: 'RIB',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

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
            borderRadius: BorderRadius.circular(AppDecorations.borderRadiusMedium),
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
                  borderRadius: BorderRadius.circular(AppDecorations.borderRadiusMedium),
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

  void _showRevenueDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDecorations.borderRadiusLarge),
        ),
      ),
      builder: (context) => RevenueDetailsModal(
        monthlyRevenue: _monthlyRevenue,
        producerRevenues: _producerRevenues,
      ),
    );
  }

  void _showWithdrawalRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WithdrawalRequestsPage(
          requests: _withdrawalRequests,
          onRequestProcessed: (request, approved) {
            setState(() {
              final index = _withdrawalRequests.indexWhere((r) => r.id == request.id);
              if (index != -1) {
                _withdrawalRequests[index] = _withdrawalRequests[index].copyWith(
                  status: approved ? 'Approuvé' : 'Rejeté',
                  processedDate: DateTime.now(),
                );
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (!_accessGranted) {
      return AccessControlScreen(
        codeController: _codeController,
        onVerifyCode: _verifyCode,
        l10n: l10n,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.my_finances, style: AppTheme.textTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.background,
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart, color: AppTheme.primary),
            onPressed: _showRevenueDetails,
          ),
          IconButton(
            icon: Icon(Icons.list_alt, color: AppTheme.primary),
            onPressed: _showWithdrawalRequests,
          ),
        ],
      ),
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          children: [
            StatisticsSection(
              selectedTimePeriod: _selectedTimePeriod,
              totalSubscribers: _totalSubscribers,
              totalViews: _totalViews,
              monthlyRevenue: _monthlyRevenue,
              onTimePeriodChanged: (value) => setState(() => _selectedTimePeriod = value!),
            ),
            const SizedBox(height: 16),
            BalanceSection(
              availableBalance: _availableBalance,
              l10n: l10n,
            ),
            const SizedBox(height: 16),
            ProducersRevenueSection(
              selectedProducer: _selectedProducer,
              producerRevenues: _producerRevenues,
              onProducerChanged: (value) => setState(() => _selectedProducer = value!),
            ),
            const SizedBox(height: 16),
            PendingPaymentsSection(l10n: l10n),
            const SizedBox(height: 24),
            WithdrawalButton(
              onPressed: _showWithdrawalModal,
              l10n: l10n,
            ),
          ],
        ),
      ),
    );
  }
}

// Widgets séparés pour une meilleure organisation

class AccessControlScreen extends StatelessWidget {
  final TextEditingController codeController;
  final VoidCallback onVerifyCode;
  final AppLocalizations l10n;

  const AccessControlScreen({
    super.key,
    required this.codeController,
    required this.onVerifyCode,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.secure_access,
                style: AppTheme.textTitle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.enter_pin,
                textAlign: TextAlign.center,
                style: AppTheme.textCaption,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: codeController,
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
                  onPressed: onVerifyCode,
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
}

class StatisticsSection extends StatelessWidget {
  final String selectedTimePeriod;
  final int totalSubscribers;
  final int totalViews;
  final List<RevenueData> monthlyRevenue;
  final ValueChanged<String?> onTimePeriodChanged;

  const StatisticsSection({
    super.key,
    required this.selectedTimePeriod,
    required this.totalSubscribers,
    required this.totalViews,
    required this.monthlyRevenue,
    required this.onTimePeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDecorations.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Statistiques',
                  style: AppTheme.textSubtitle.copyWith(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: selectedTimePeriod,
                  items: ['Jour', 'Semaine', 'Mois', 'Année'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: onTimePeriodChanged,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Abonnés', '$totalSubscribers', Icons.people),
                _buildStatCard('Vues', '$totalViews', Icons.remove_red_eye),
                _buildStatCard('Revenus', '${monthlyRevenue.last.amount} €', Icons.euro),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppTheme.primary),
        const SizedBox(height: 8),
        Text(title, style: AppTheme.textCaption),
        Text(value, style: AppTheme.textBodyBold),
      ],
    );
  }
}

class BalanceSection extends StatelessWidget {
  final double availableBalance;
  final AppLocalizations l10n;

  const BalanceSection({
    super.key,
    required this.availableBalance,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDecorations.borderRadiusMedium),
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
              '$availableBalance €',
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
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.textCaption,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.textBodyBold,
        ),
      ],
    );
  }
}

class ProducersRevenueSection extends StatelessWidget {
  final String selectedProducer;
  final List<ProducerRevenue> producerRevenues;
  final ValueChanged<String?> onProducerChanged;

  const ProducersRevenueSection({
    super.key,
    required this.selectedProducer,
    required this.producerRevenues,
    required this.onProducerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDecorations.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Revenus par producteur',
                  style: AppTheme.textSubtitle.copyWith(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: selectedProducer,
                  items: ['Tous', ...producerRevenues.map((p) => p.name)].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: onProducerChanged,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <CartesianSeries>[
                  BarSeries<ProducerRevenue, String>(
                    dataSource: selectedProducer == 'Tous' 
                        ? producerRevenues 
                        : producerRevenues.where((p) => p.name == selectedProducer).toList(),
                    xValueMapper: (ProducerRevenue revenue, _) => revenue.name,
                    yValueMapper: (ProducerRevenue revenue, _) => revenue.revenue,
                    color: AppTheme.primary,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PendingPaymentsSection extends StatelessWidget {
  final AppLocalizations l10n;

  const PendingPaymentsSection({
    super.key,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDecorations.borderRadiusMedium),
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
            color: AppTheme.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppDecorations.borderRadiusSmall),
          ),
          child: Icon(
            Icons.pending_actions,
            color: AppTheme.orange,
          ),
        ),
        title: Text(
          l10n.pending_payments,
          style: AppTheme.textBodyBold,
        ),
        subtitle: Text(l10n.available_in_48h, style: AppTheme.textCaption),
        trailing: Text(
          '500 €',
          style: AppTheme.textBodyBold,
        ),
      ),
    );
  }
}

class WithdrawalButton extends StatelessWidget {
  final VoidCallback onPressed;
  final AppLocalizations l10n;

  const WithdrawalButton({
    super.key,
    required this.onPressed,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(Icons.monetization_on, color: AppTheme.textPrimary),
        label: Text(l10n.request_withdrawal, style: AppTheme.textBodyBold),
        style: AppDecorations.elevatedButtonStyle,
      ),
    );
  }
}

class RevenueDetailsModal extends StatelessWidget {
  final List<RevenueData> monthlyRevenue;
  final List<ProducerRevenue> producerRevenues;

  const RevenueDetailsModal({
    super.key,
    required this.monthlyRevenue,
    required this.producerRevenues,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppTheme.paddingMedium,
        right: AppTheme.paddingMedium,
        top: AppTheme.paddingMedium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Détails des revenus',
            style: AppTheme.textTitle,
          ),
          const SizedBox(height: 16),
          _buildRevenueChart(),
          const SizedBox(height: 16),
          _buildRevenueTable(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return SizedBox(
      height: 250,
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        series: <CartesianSeries>[
          ColumnSeries<RevenueData, String>(
            dataSource: monthlyRevenue,
            xValueMapper: (RevenueData revenue, _) => revenue.month,
            yValueMapper: (RevenueData revenue, _) => revenue.amount,
            color: AppTheme.primary,
          )
        ],
      ),
    );
  }

  Widget _buildRevenueTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Producteur', style: AppTheme.textBodyBold)),
          DataColumn(label: Text('Vues', style: AppTheme.textBodyBold)),
          DataColumn(label: Text('Revenus (€)', style: AppTheme.textBodyBold)),
        ],
        rows: producerRevenues.map((producer) {
          return DataRow(cells: [
            DataCell(Text(producer.name)),
            DataCell(Text(producer.views.toString())),
            DataCell(Text(producer.revenue.toStringAsFixed(2))),
          ]);
        }).toList(),
      ),
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
            Text(
              l10n.withdrawal_request,
              style: AppTheme.textTitle,
            ),
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
                  return l10n.amount_exceeds_balance(widget.availableBalance.toStringAsFixed(2));
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
                  if (_selectedMethod != 'RIB' && (value == null || value.isEmpty)) {
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
                      prefixIcon: Icon(Icons.account_balance, color: AppTheme.primary),
                    ),
                    validator: (value) {
                      if (_selectedMethod == 'RIB' && (value == null || value.isEmpty)) {
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
                      if (_selectedMethod == 'RIB' && (value == null || value.isEmpty)) {
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

class WithdrawalRequestsPage extends StatefulWidget {
  final List<WithdrawalRequest> requests;
  final Function(WithdrawalRequest, bool) onRequestProcessed;

  const WithdrawalRequestsPage({
    super.key,
    required this.requests,
    required this.onRequestProcessed,
  });

  @override
  State<WithdrawalRequestsPage> createState() => _WithdrawalRequestsPageState();
}

class _WithdrawalRequestsPageState extends State<WithdrawalRequestsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.withdrawal_requests, style: AppTheme.textTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.background,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.paddingMedium),
        itemCount: widget.requests.length,
        itemBuilder: (context, index) {
          final request = widget.requests[index];
          return WithdrawalRequestCard(
            request: request,
            onProcessed: widget.onRequestProcessed,
          );
        },
      ),
    );
  }
}

class WithdrawalRequestCard extends StatelessWidget {
  final WithdrawalRequest request;
  final Function(WithdrawalRequest, bool) onProcessed;

  const WithdrawalRequestCard({
    super.key,
    required this.request,
    required this.onProcessed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDecorations.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  request.producerName,
                  style: AppTheme.textSubtitle.copyWith(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(
                    request.status,
                    style: AppTheme.textCaption.copyWith(
                      color: request.status == 'En attente'
                          ? AppTheme.orange
                          : request.status == 'Approuvé'
                              ? AppTheme.success
                              : AppTheme.error,
                    ),
                  ),
                  backgroundColor: request.status == 'En attente'
                      ? AppTheme.orange.withOpacity(0.2)
                      : request.status == 'Approuvé'
                          ? AppTheme.success.withOpacity(0.2)
                          : AppTheme.error.withOpacity(0.2),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.amount}: ${request.amount} €',
              style: AppTheme.textBodyBold,
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.method}: ${request.method}',
              style: AppTheme.textBody,
            ),
            const SizedBox(height: 4),
            if (request.phoneNumber != null)
              Text(
                '${l10n.phone_number}: ${request.phoneNumber}',
                style: AppTheme.textBody,
              ),
            if (request.iban != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.iban}: ${request.iban}',
                    style: AppTheme.textBody,
                  ),
                  Text(
                    '${l10n.beneficiary_name}: ${request.beneficiaryName}',
                    style: AppTheme.textBody,
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              '${l10n.date}: ${request.date.day}/${request.date.month}/${request.date.year}',
              style: AppTheme.textCaption,
            ),
            if (request.processedDate != null)
              Text(
                'Traité le: ${request.processedDate!.day}/${request.processedDate!.month}/${request.processedDate!.year}',
                style: AppTheme.textCaption,
              ),
            if (request.status == 'En attente')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => onProcessed(request, false),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.error,
                    ),
                    child: Text(l10n.reject),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => onProcessed(request, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                    ),
                    child: Text(l10n.approve),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// Modèles de données

class RevenueData {
  final String month;
  final double amount;

  RevenueData(this.month, this.amount);
}

class ProducerRevenue {
  final String name;
  final int views;
  final double revenue;

  ProducerRevenue(this.name, this.views, this.revenue);
}

class WithdrawalRequest {
  final String id;
  final String producerName;
  final double amount;
  final String method;
  final DateTime date;
  String status;
  final String? phoneNumber;
  final String? iban;
  final String? beneficiaryName;
  DateTime? processedDate;

  WithdrawalRequest({
    required this.id,
    required this.producerName,
    required this.amount,
    required this.method,
    required this.date,
    this.status = 'En attente',
    this.phoneNumber,
    this.iban,
    this.beneficiaryName,
    this.processedDate,
  });

  WithdrawalRequest copyWith({
    String? status,
    DateTime? processedDate,
  }) {
    return WithdrawalRequest(
      id: id,
      producerName: producerName,
      amount: amount,
      method: method,
      date: date,
      status: status ?? this.status,
      phoneNumber: phoneNumber,
      iban: iban,
      beneficiaryName: beneficiaryName,
      processedDate: processedDate ?? this.processedDate,
    );
  }
}