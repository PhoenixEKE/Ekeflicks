import 'package:flutter/material.dart';
import 'package:plateforme_administrateur/ui/producers_dashboard/users/models/user_model.dart';

class UserTransactionsWidget extends StatelessWidget {
  final List<Transaction> transactions;

  const UserTransactionsWidget({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Historique des transactions'),
      content: SizedBox(
        width: double.maxFinite,
        child: transactions.isEmpty
            ? const Center(child: Text('Aucune transaction'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return ListTile(
                    leading: Icon(_getMethodIcon(transaction.method)),
                    title: Text('${transaction.amount} €'),
                    subtitle: Text(
                      '${_getStatusText(transaction.status)} • ${_formatDate(transaction.date)}',
                    ),
                    trailing: Text(
                      // Sécurisation contre RangeError si id < 8 caractères
                      transaction.id.length > 8
                          ? transaction.id.substring(0, 8)
                          : transaction.id,
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.paypal:
        return Icons.payment;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
      case PaymentMethod.crypto:
        return Icons.currency_bitcoin;
    }
  }

  String _getStatusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'En attente';
      case TransactionStatus.completed:
        return 'Complété';
      case TransactionStatus.failed:
        return 'Échoué';
      case TransactionStatus.refunded:
        return 'Remboursé';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
