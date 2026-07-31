// lib/producers_dashboard/users/models/user_model.dart

enum UserStatus { active, inactive, pending }
enum PaymentMethod { creditCard, paypal, bankTransfer, crypto }
enum TransactionStatus { pending, completed, failed, refunded }

class User {
  final int id;
  final String name;
  final String email;
  final String password;
  final String phone;
  final String? profileImage;
  final String subscription;
  final String country;
  final DateTime joinDate;
  final DateTime? subscriptionStart; 
  final DateTime? subscriptionEnd;  
  final UserStatus status;
  final List<Transaction> transactions;
  final List<LinkedProfile> linkedProfiles;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    this.profileImage,
    required this.subscription,
    required this.country,
    required this.joinDate,
    this.subscriptionStart,  
    this.subscriptionEnd,
    required this.status,
    this.transactions = const [],
    this.linkedProfiles = const [],
  });
}

class LinkedProfile {
  final String id;
  final String type;
  final String name;
  final String relation;
  final String accessLevel;
  final bool? parentalControl;
  final String? viewingTime; 

  LinkedProfile({
    required this.id,
    required this.type,
    required this.name,
    required this.relation,
    required this.accessLevel,
    this.parentalControl,  
    this.viewingTime,
  });
}

class Transaction {
  final String id;
  final double amount;
  final PaymentMethod method;
  final TransactionStatus status;
  final DateTime date;

  Transaction({
    required this.id,
    required this.amount,
    required this.method,
    required this.status,
    required this.date,
  });
}