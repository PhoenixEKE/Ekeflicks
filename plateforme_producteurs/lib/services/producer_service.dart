import 'package:plateforme_producteurs/models/producer_onboarding.dart';
import 'package:plateforme_producteurs/services/api_client.dart';

class ProducerService {
  ProducerService._();

  static final ProducerService instance = ProducerService._();

  final ApiClient _api = ApiClient.instance;

  Future<ProducerAccount> getOnboarding() async {
    final response = await _api.get(
      '/api/v1/auth/producer/onboarding/',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de récupérer le dossier Producteur.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse Producteur invalide.');
    }

    return ProducerAccount.fromJson(data);
  }

  Future<ProducerAccount> updateOnboarding({
    required String companyName,
    required String legalName,
    required String legalForm,
    required String registrationNumber,
    String? taxNumber,
    String? countryCode,
    String? address,
    String? city,
    String? phone,
    required String representativeName,
    String? representativeRole,
  }) async {
    final response = await _api.patch(
      '/api/v1/auth/producer/onboarding/',
      authenticated: true,
      body: {
        'company_name': companyName.trim(),
        'legal_name': legalName.trim(),
        'legal_form': legalForm.trim(),
        'registration_number': registrationNumber.trim(),
        'tax_number': taxNumber?.trim() ?? '',
        'country_code': countryCode?.trim().toUpperCase() ?? '',
        'address': address?.trim() ?? '',
        'city': city?.trim() ?? '',
        'phone': phone?.trim() ?? '',
        'representative_name': representativeName.trim(),
        'representative_role': representativeRole?.trim() ?? '',
      },
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback:
              'Impossible d’enregistrer les informations professionnelles.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse Producteur invalide.');
    }

    return ProducerAccount.fromJson(data);
  }

  Future<void> resendEmailVerification() async {
    final response = await _api.post(
      '/api/v1/auth/resend-email-verification/',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de renvoyer l’email de vérification.',
        ),
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> verifyEmail(String token) async {
    final response = await _api.get(
      '/api/v1/auth/verify-email/?token=${Uri.encodeQueryComponent(token)}',
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Lien de vérification invalide ou expiré.',
        ),
        statusCode: response.statusCode,
      );
    }
  }

  Future<ProducerAgreement> getCurrentAgreement() async {
    final response = await _api.get(
      '/api/v1/auth/producer/agreement/',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de récupérer le contrat EKEFLICKS.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse contrat invalide.');
    }

    final agreementData = data['agreement'];

    if (agreementData is Map) {
      final merged = <String, dynamic>{
        ...data,
        ...Map<String, dynamic>.from(agreementData),
      };

      return ProducerAgreement.fromJson(merged);
    }

    return ProducerAgreement.fromJson(data);
  }

  Future<List<int>> downloadAgreement({
    bool download = true,
    bool signed = false,
  }) async {
    final params = <String>[];

    if (signed) {
      params.add('signed=1');
    }

    if (download) {
      params.add('download=1');
    }

    final query = params.isEmpty ? '' : '?${params.join('&')}';

    final path = '/api/v1/auth/producer/agreement/document/$query';

    final response = await _api.getBytes(path, authenticated: true);

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de télécharger le contrat EKEFLICKS.',
        ),
        statusCode: response.statusCode,
      );
    }

    return response.bodyBytes;
  }

  Future<ProducerAgreement> signAgreement() async {
    final response = await _api.post(
      '/api/v1/auth/producer/agreement/sign/',
      authenticated: true,
      body: const {'accepted': true},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de signer le contrat EKEFLICKS.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse de signature invalide.');
    }

    final agreementData = data['agreement'];

    if (agreementData is Map) {
      return ProducerAgreement.fromJson(
        Map<String, dynamic>.from(agreementData),
      );
    }

    return ProducerAgreement.fromJson(data);
  }
}
