class ProducerAccount {
  final String id;
  final String? email;
  final String firstname;
  final String lastname;
  final bool emailVerified;

  final String companyName;
  final String? legalName;
  final String? legalForm;
  final String? registrationNumber;
  final String? taxNumber;
  final String? countryCode;
  final String? address;
  final String? city;
  final String? phone;
  final String? representativeName;
  final String? representativeRole;

  final String status;
  final String? rejectionReason;
  final String? currentContractVersion;
  final String currentAgreementStatus;
  final bool canSubmitContent;

  const ProducerAccount({
    required this.id,
    this.email,
    required this.firstname,
    required this.lastname,
    required this.emailVerified,
    required this.companyName,
    this.legalName,
    this.legalForm,
    this.registrationNumber,
    this.taxNumber,
    this.countryCode,
    this.address,
    this.city,
    this.phone,
    this.representativeName,
    this.representativeRole,
    required this.status,
    this.rejectionReason,
    this.currentContractVersion,
    required this.currentAgreementStatus,
    required this.canSubmitContent,
  });

  factory ProducerAccount.fromJson(Map<String, dynamic> json) {
    return ProducerAccount(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString(),
      firstname: json['firstname']?.toString() ?? '',
      lastname: json['lastname']?.toString() ?? '',
      emailVerified: json['email_verified'] == true,
      companyName: json['company_name']?.toString() ?? '',
      legalName: json['legal_name']?.toString(),
      legalForm: json['legal_form']?.toString(),
      registrationNumber: json['registration_number']?.toString(),
      taxNumber: json['tax_number']?.toString(),
      countryCode: json['country_code']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      phone: json['phone']?.toString(),
      representativeName: json['representative_name']?.toString(),
      representativeRole: json['representative_role']?.toString(),
      status: json['status']?.toString() ?? 'onboarding',
      rejectionReason: json['rejection_reason']?.toString(),
      currentContractVersion: json['current_contract_version']?.toString(),
      currentAgreementStatus:
          json['current_agreement_status']?.toString() ?? 'not_signed',
      canSubmitContent: json['can_submit_content'] == true,
    );
  }

  bool get isActive => status == 'active';

  bool get needsProfessionalInfo => status == 'onboarding';

  bool get needsAgreement =>
      status == 'contract_pending' && currentAgreementStatus != 'signed';

  String get displayName {
    final value = '$firstname $lastname'.trim();
    return value.isEmpty ? companyName : value;
  }
}

class ProducerAgreement {
  final String? id;

  final String contractVersion;
  final String contractTitle;
  final String contractHash;
  final String contractDocumentUrl;

  final String status;
  final String? signerName;
  final String? signerRole;
  final String? signatureMethod;

  final DateTime? acceptedAt;
  final DateTime? signedAt;
  final DateTime? effectiveDate;

  final String? producerLegalName;
  final String? producerLegalForm;
  final String? producerCountryCode;
  final String? producerAddress;
  final String? producerCity;
  final String? producerRegistrationNumber;
  final String? producerTaxNumber;
  final String? producerRepresentativeName;
  final String? producerRepresentativeRole;

  final String? signedDocumentUrl;
  final String? signedDocumentHash;

  final String? ekeflicksSignerName;
  final String? ekeflicksSignerRole;
  final DateTime? ekeflicksSignedAt;

  const ProducerAgreement({
    this.id,
    required this.contractVersion,
    required this.contractTitle,
    required this.contractHash,
    required this.contractDocumentUrl,
    required this.status,
    this.signerName,
    this.signerRole,
    this.signatureMethod,
    this.acceptedAt,
    this.signedAt,
    this.effectiveDate,
    this.producerLegalName,
    this.producerLegalForm,
    this.producerCountryCode,
    this.producerAddress,
    this.producerCity,
    this.producerRegistrationNumber,
    this.producerTaxNumber,
    this.producerRepresentativeName,
    this.producerRepresentativeRole,
    this.signedDocumentUrl,
    this.signedDocumentHash,
    this.ekeflicksSignerName,
    this.ekeflicksSignerRole,
    this.ekeflicksSignedAt,
  });

  factory ProducerAgreement.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;

      final text = value.toString().trim();

      if (text.isEmpty) {
        return null;
      }

      return DateTime.tryParse(text);
    }

    return ProducerAgreement(
      id: json['id']?.toString(),
      contractVersion: json['contract_version']?.toString() ?? '',
      contractTitle:
          json['contract_title']?.toString() ?? 'Contrat Producteur EKEFLICKS',
      contractHash: json['contract_hash']?.toString() ?? '',
      contractDocumentUrl: json['contract_document_url']?.toString() ?? '',
      status: json['status']?.toString() ?? 'not_signed',
      signerName: json['signer_name']?.toString(),
      signerRole: json['signer_role']?.toString(),
      signatureMethod: json['signature_method']?.toString(),
      acceptedAt: parseDate(json['accepted_at']),
      signedAt: parseDate(json['signed_at']),
      effectiveDate: parseDate(json['effective_date']),
      producerLegalName: json['producer_legal_name']?.toString(),
      producerLegalForm: json['producer_legal_form']?.toString(),
      producerCountryCode: json['producer_country_code']?.toString(),
      producerAddress: json['producer_address']?.toString(),
      producerCity: json['producer_city']?.toString(),
      producerRegistrationNumber: json['producer_registration_number']
          ?.toString(),
      producerTaxNumber: json['producer_tax_number']?.toString(),
      producerRepresentativeName: json['producer_representative_name']
          ?.toString(),
      producerRepresentativeRole: json['producer_representative_role']
          ?.toString(),
      signedDocumentUrl: json['signed_document_url']?.toString(),
      signedDocumentHash: json['signed_document_hash']?.toString(),
      ekeflicksSignerName: json['ekeflicks_signer_name']?.toString(),
      ekeflicksSignerRole: json['ekeflicks_signer_role']?.toString(),
      ekeflicksSignedAt: parseDate(json['ekeflicks_signed_at']),
    );
  }

  bool get isSigned => status == 'signed' && signedAt != null;

  String get documentUrl {
    if (isSigned &&
        signedDocumentUrl != null &&
        signedDocumentUrl!.trim().isNotEmpty) {
      return signedDocumentUrl!;
    }

    return contractDocumentUrl;
  }
}
