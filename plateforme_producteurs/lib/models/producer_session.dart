class ProducerUser {
  final String id;
  final String? email;
  final String firstname;
  final String lastname;
  final String? phone;
  final String? countryCode;
  final bool isActive;
  final bool isVerified;
  final bool isProducer;
  final String? producerCompany;

  const ProducerUser({
    required this.id,
    this.email,
    required this.firstname,
    required this.lastname,
    this.phone,
    this.countryCode,
    required this.isActive,
    required this.isVerified,
    required this.isProducer,
    this.producerCompany,
  });

  factory ProducerUser.fromJson(Map<String, dynamic> json) {
    return ProducerUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString(),
      firstname: json['firstname']?.toString() ?? '',
      lastname: json['lastname']?.toString() ?? '',
      phone: json['phone']?.toString(),
      countryCode: json['country_code']?.toString(),
      isActive: json['is_active'] == true,
      isVerified: json['is_verified'] == true,
      isProducer: json['is_producer'] == true,
      producerCompany: json['producer_company']?.toString(),
    );
  }
}

class ProducerSession {
  final String accessToken;
  final ProducerUser user;

  const ProducerSession({required this.accessToken, required this.user});
}
