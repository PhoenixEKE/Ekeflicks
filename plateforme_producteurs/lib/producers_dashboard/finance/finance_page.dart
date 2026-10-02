import 'package:flutter/material.dart';
import 'dart:async';
import 'package:plateforme_producteurs/core/core.dart';
import 'package:plateforme_producteurs/services/producer_service.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  final _pin = TextEditingController();
  final _code = TextEditingController();
  final _newPin = TextEditingController();
  final _service = ProducerService.instance;
  Map<String, dynamic> _security = const {};
  Map<String, dynamic> _balance = const {};
  List<Map<String, dynamic>> _payouts = const [];
  String? _challengeOperation;
  bool _recovering = false;
  bool _loading = true;
  bool _working = false;
  String? _error;
  Timer? _refreshTimer;

  String _s(BuildContext context, String fr, String en) =>
      Localizations.localeOf(context).languageCode == 'en' ? en : fr;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) => _refreshUnlockedData());
  }

  @override
  void dispose() {
    _pin.dispose();
    _code.dispose();
    _newPin.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshUnlockedData() async {
    if (_loading || _working || _security['unlocked'] != true) return;
    try {
      final security = await _service.getFinanceAccess();
      if (security['unlocked'] != true) {
        if (!mounted) return;
        setState(() => _security = security);
        return;
      }
      final balance = await _service.getProducerBalance();
      final payouts = await _service.getPayoutRequests();
      if (!mounted) return;
      setState(() { _security = security; _balance = balance; _payouts = payouts; });
    } catch (_) {
      // The next refresh or user initiated retry will recover transient failures.
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final security = await _service.getFinanceAccess();
      Map<String, dynamic> balance = const {};
      List<Map<String, dynamic>> payouts = const [];
      if (security['unlocked'] == true) {
        balance = await _service.getProducerBalance();
        payouts = await _service.getPayoutRequests();
      }
      if (!mounted) return;
      setState(() {
        _security = security;
        _balance = balance;
        _payouts = payouts;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _error = error.toString(); _loading = false; });
    }
  }

  Future<void> _sendCode(String operation, {String? pin}) async {
    setState(() => _working = true);
    try {
      await _service.financeAccessAction(operation, pin: pin);
      if (!mounted) return;
      setState(() {
        _challengeOperation = operation == 'setup' ? 'confirm_setup' :
            operation == 'forgot' ? 'reset' : 'confirm_login';
        _recovering = operation == 'forgot';
        _working = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_s(context, 'Un code a été envoyé à votre adresse e-mail.', 'A code has been sent to your email address.')),
      ));
    } catch (error) {
      if (!mounted) return;
      setState(() => _working = false);
      _showError(error);
    }
  }

  Future<void> _confirmCode() async {
    final operation = _challengeOperation;
    if (operation == null) return;
    setState(() => _working = true);
    try {
      await _service.financeAccessAction(
        operation,
        code: _code.text.trim(),
        pin: _recovering ? _newPin.text.trim() : null,
      );
      if (!mounted) return;
      _code.clear();
      _newPin.clear();
      _pin.clear();
      setState(() { _challengeOperation = null; _recovering = false; _working = false; });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _working = false);
      _showError(error);
    }
  }

  void _showError(Object error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString()), backgroundColor: AppTheme.error),
      );

  String _money(dynamic value, {bool local = false}) {
    final number = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    final currency = (_balance['currency'] ?? 'EUR').toString();
    final amount = number.toStringAsFixed(currency == 'XOF' || currency == 'XAF' ? 0 : 2);
    return local ? '$amount $currency' : '$amount €';
  }

  InputDecoration _input(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      );

  Widget _pinEntry() {
    final configured = _security['pin_configured'] == true;
    final challenge = _challengeOperation != null;
    final title = challenge
        ? _s(context, 'Confirmer par e-mail', 'Confirm by email')
        : configured
            ? _s(context, 'Accès sécurisé à Finance', 'Secure Finance access')
            : _s(context, 'Créer votre code Finance', 'Create your Finance PIN');
    final emailHint = _security['email_hint']?.toString() ?? '';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 48),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                challenge
                    ? _s(context, 'Saisissez le code reçu à $emailHint.', 'Enter the code sent to $emailHint.')
                    : configured
                        ? _s(context, 'Saisissez votre code à 4 chiffres. Un code de vérification sera ensuite envoyé par e-mail.', 'Enter your 4-digit PIN. A verification code will then be emailed to you.')
                        : _s(context, 'Choisissez un code personnel à 4 chiffres. Il sera confirmé par e-mail.', 'Choose a personal 4-digit PIN. You will confirm it by email.'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (!challenge)
                TextField(
                  controller: _pin,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: _input(_s(context, 'Code à 4 chiffres', '4-digit PIN')),
                )
              else ...[
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: _input(_s(context, 'Code reçu par e-mail', 'Email code')),
                ),
                if (_recovering) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newPin,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: _input(_s(context, 'Nouveau code à 4 chiffres', 'New 4-digit PIN')),
                  ),
                ],
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _working
                      ? null
                      : challenge
                          ? _confirmCode
                          : () {
                              if (_pin.text.length != 4) {
                                _showError(_s(context, 'Le code doit contenir 4 chiffres.', 'The PIN must contain 4 digits.'));
                                return;
                              }
                              _sendCode(configured ? 'verify' : 'setup', pin: _pin.text);
                            },
                  child: _working
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(challenge ? _s(context, 'Confirmer', 'Confirm') : configured ? _s(context, 'Continuer', 'Continue') : _s(context, 'Créer et confirmer', 'Create and confirm')),
                ),
              ),
              if (configured && !challenge)
                TextButton(
                  onPressed: _working ? null : () => _sendCode('forgot'),
                  child: Text(_s(context, 'Code oublié ?', 'Forgot PIN?')),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _requestPayout() async {
    final method = TextEditingController(text: 'Wave');
    final account = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_s(context, 'Demander un paiement', 'Request a payout')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: method, decoration: _input(_s(context, 'Moyen de paiement', 'Payout method'))),
          const SizedBox(height: 12),
          TextField(controller: account, decoration: _input(_s(context, 'Téléphone ou compte', 'Phone or account'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(_s(context, 'Annuler', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(_s(context, 'Envoyer', 'Submit')),
          ),
        ],
      ),
    );
    if (result != true || !mounted) return;
    setState(() => _working = true);
    try {
      await _service.requestPayout(method: method.text.trim(), account: account.text.trim());
      await _load();
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Widget _summaryCard(String title, String value, IconData icon) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title), const SizedBox(height: 5), Text(value, style: Theme.of(context).textTheme.titleLarge)])),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!), const SizedBox(height: 12), FilledButton(onPressed: _load, child: Text(_s(context, 'Réessayer', 'Retry')))]));
    }
    if (_security['unlocked'] != true) return _pinEntry();

    final earnings = (_balance['content_earnings'] as List? ?? const [])
        .whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    final views = _balance['eligible_views'] ?? 0;
    final demoMode = _balance['demo_mode'] == true;
    final minimum = _money(_balance['minimum_payout_local'] ?? _balance['minimum_payout_eur'], local: true);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        Text(_s(context, 'Mes finances', 'My finances'), style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        _summaryCard(demoMode ? _s(context, 'Solde de démonstration', 'Demo balance') : _s(context, 'Solde disponible', 'Available balance'), _money(_balance['amount_local'] ?? _balance['amount_eur'], local: true), Icons.account_balance_wallet_outlined),
        if (demoMode) Card(color: Colors.amber.withValues(alpha: .12), child: Padding(padding: const EdgeInsets.all(16), child: Text(_s(context, 'Données fictives de démonstration. Elles ne sont pas payables et peuvent être supprimées avec seed_producer_demo_data --clear.', 'Synthetic demo data. These amounts are not payable and can be removed with seed_producer_demo_data --clear.')))),
        _summaryCard(_s(context, 'Vues éligibles non payées', 'Unpaid eligible views'), '$views', Icons.visibility_outlined),
        _summaryCard(_s(context, 'Seuil minimum de paiement', 'Minimum payout threshold'), minimum, Icons.payments_outlined),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(
          _s(context,
            'Barème actuel : ${_money(_balance['rate_per_1000_views_local'] ?? _balance['rate_per_1000_views_eur'], local: true)} pour 1 000 vues éligibles • visionnage minimum : ${_balance['eligible_progress_percent']} % de la durée • publicité : ${_balance['advertising_share_percent']} % des revenus nets.',
            'Current rate: ${_money(_balance['rate_per_1000_views_local'] ?? _balance['rate_per_1000_views_eur'], local: true)} per 1,000 eligible views • minimum watched: ${_balance['eligible_progress_percent']}% of runtime • advertising: ${_balance['advertising_share_percent']}% of net revenue.',
          ),
        ))),
        const SizedBox(height: 12),
        Text(_s(context, 'Rémunérations par contenu', 'Earnings by content'), style: Theme.of(context).textTheme.titleLarge),
        if (earnings.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(_s(context, 'Aucune rémunération enregistrée pour le moment.', 'No earnings have been recorded yet.')))),
        ...earnings.map((item) => Card(child: ListTile(
          title: Text(item['title']?.toString() ?? ''),
          subtitle: Text('${item['eligible_views'] ?? 0} ${_s(context, 'vues', 'views')} • ${_s(context, 'vues', 'views')}: ${_money(item['view_revenue_local'] ?? item['view_revenue_eur'], local: true)} • ${_s(context, 'publicité', 'ads')}: ${_money(item['advertising_revenue_local'] ?? item['advertising_revenue_eur'], local: true)}'),
          trailing: Text(_money(item['total_local'] ?? item['total_eur'], local: true)),
        ))),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: demoMode || _working || (double.tryParse('${_balance['amount_eur']}') ?? 0) < (double.tryParse('${_balance['minimum_payout_eur']}') ?? 0) ? null : _requestPayout,
          icon: const Icon(Icons.payments_outlined),
          label: Text(_s(context, 'Demander un paiement', 'Request a payout')),
        ),
        const SizedBox(height: 20),
        Text(_s(context, 'Historique des paiements', 'Payout history'), style: Theme.of(context).textTheme.titleLarge),
        if (_payouts.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(16), child: Text(_s(context, 'Aucune demande de paiement.', 'No payout requests yet.')))),
        ..._payouts.map((row) => Card(child: ListTile(
          title: Text('${_money(row['amount_local'] ?? row['amount_eur'], local: true)} • ${row['status'] ?? ''}'),
          subtitle: Text('${row['payout_method'] ?? ''} ${row['created_at'] ?? ''}'),
        ))),
      ]),
    );
  }
}
