import 'package:plateforme_producteurs/models/producer_onboarding.dart';
import 'package:plateforme_producteurs/services/api_client.dart';

class ProducerService {
  ProducerService._();

  static final ProducerService instance = ProducerService._();

  final ApiClient _api = ApiClient.instance;

  Map<String, int>? _genreIdsByNameCache;
  Future<Map<String, int>>? _genreIdsByNameLoad;

  Future<Map<String, dynamic>> getTechnicalSpecification() async {
    final response = await _api.get(
      '/api/v1/technical-specification/',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de récupérer le cahier des charges technique.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map) {
      throw const ApiException(
        'Réponse du cahier des charges technique invalide.',
      );
    }

    return Map<String, dynamic>.from(data);
  }

  Future<List<int>> downloadTechnicalSpecification() async {
    final response = await _api.getBytes(
      '/api/v1/technical-specification/pdf/',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback:
              'Impossible de télécharger le cahier des charges technique.',
        ),
        statusCode: response.statusCode,
      );
    }

    return response.bodyBytes;
  }

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

  Future<Map<String, int>> _loadGenreIdsByName() async {
    final cached = _genreIdsByNameCache;

    if (cached != null) {
      return cached;
    }

    final runningLoad = _genreIdsByNameLoad;

    if (runningLoad != null) {
      return runningLoad;
    }

    final load = _fetchGenreIdsByName();
    _genreIdsByNameLoad = load;

    try {
      final genres = await load;
      _genreIdsByNameCache = genres;
      return genres;
    } finally {
      _genreIdsByNameLoad = null;
    }
  }

  Future<Map<String, int>> _fetchGenreIdsByName() async {
    final response = await _api.get('/api/v1/genres/', authenticated: true);

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de récupérer les genres.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    List<dynamic> rows;

    if (data is List) {
      rows = data;
    } else if (data is Map && data['results'] is List) {
      rows = data['results'] as List<dynamic>;
    } else {
      throw const ApiException('Réponse des genres invalide.');
    }

    final byName = <String, int>{};

    for (final row in rows) {
      if (row is! Map) {
        continue;
      }

      final rawName = row['name'];
      final rawId = row['id'];

      if (rawName is! String) {
        continue;
      }

      final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

      if (id == null) {
        continue;
      }

      byName[rawName.trim().toLowerCase()] = id;
    }

    return Map<String, int>.unmodifiable(byName);
  }

  Future<List<int>> getGenreIdsByNames(Iterable<String> names) async {
    final requestedNames = names
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (requestedNames.isEmpty) {
      return const <int>[];
    }

    final byName = await _loadGenreIdsByName();

    final ids = <int>[];
    final missing = <String>[];

    for (final name in requestedNames) {
      final id = byName[name.toLowerCase()];

      if (id == null) {
        missing.add(name);
      } else {
        ids.add(id);
      }
    }

    if (missing.isNotEmpty) {
      throw ApiException(
        'Genres introuvables sur le serveur : ${missing.join(', ')}.',
      );
    }

    return ids;
  }

  Future<Map<String, dynamic>> createContent({
    required String title,
    required String description,
    required String type,
    int? releaseYear,
    List<int> genreIds = const [],
    String? synopsis,
  }) async {
    final response = await _api.post(
      '/api/v1/contents/',
      authenticated: true,
      body: {
        'title': title.trim(),
        'description': description.trim(),
        'synopsis': synopsis?.trim() ?? description.trim(),
        'type': type,
        if (releaseYear != null) 'release_year': releaseYear,
        if (genreIds.isNotEmpty) 'genre_ids': genreIds,
      },
    );

    if (response.statusCode != 201) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de créer le contenu.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse de création de contenu invalide.');
    }

    return data;
  }

  Future<Map<String, dynamic>> updateContent({
    required String contentId,
    String? title,
    String? originalTitle,
    String? description,
    String? synopsis,
    String? type,
    int? releaseYear,
    String? availableFrom,
    int? duration,
    String? ageRating,
    List<int>? genreIds,
    String? language,
    String? country,
    List<String>? audioLanguages,
    List<String>? subtitleLanguages,
    String? directorName,
    String? screenwriterName,
    List<Map<String, dynamic>>? producerTeam,
    List<Map<String, dynamic>>? castTeam,
  }) async {
    final body = <String, dynamic>{};

    if (title != null) {
      body['title'] = title.trim();
    }

    if (originalTitle != null) {
      body['original_title'] = originalTitle.trim();
    }

    if (description != null) {
      body['description'] = description.trim();
    }

    if (synopsis != null) {
      body['synopsis'] = synopsis.trim();
    }

    if (type != null) {
      body['type'] = type;
    }

    if (releaseYear != null) {
      body['release_year'] = releaseYear;
    }

    if (availableFrom != null) {
      body['available_from'] = availableFrom.trim();
    }

    if (duration != null) {
      body['duration'] = duration;
    }

    if (ageRating != null) {
      body['age_rating'] = ageRating.trim();
    }

    if (genreIds != null) {
      body['genre_ids'] = genreIds;
    }

    if (language != null) {
      body['language'] = language.trim();
    }

    if (country != null) {
      body['country'] = country.trim();
    }

    if (audioLanguages != null) {
      body['audio_languages'] = audioLanguages;
    }

    if (subtitleLanguages != null) {
      body['subtitle_languages'] = subtitleLanguages;
    }

    if (directorName != null) {
      body['director_name'] = directorName.trim();
    }

    if (screenwriterName != null) {
      body['screenwriter_name'] = screenwriterName.trim();
    }

    if (producerTeam != null) {
      body['producer_team'] = producerTeam;
    }

    if (castTeam != null) {
      body['cast_team'] = castTeam;
    }

    final response = await _api.patch(
      '/api/v1/contents/$contentId/',
      authenticated: true,
      body: body,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de sauvegarder le brouillon.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse de sauvegarde invalide.');
    }

    return data;
  }

  Future<void> deleteDraft(String contentId) async {
    final cleanId = contentId.trim();

    if (cleanId.isEmpty) {
      throw const ApiException('Identifiant du brouillon invalide.');
    }

    final response = await _api.delete(
      '/api/v1/contents/$cleanId/',
      authenticated: true,
    );

    if (response.statusCode != 204) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de supprimer le brouillon.',
        ),
        statusCode: response.statusCode,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getMyContents({
    String? type,
    String? submissionStatus,
  }) async {
    final params = <String, String>{};

    if (type != null && type.isNotEmpty) {
      params['type'] = type;
    }

    if (submissionStatus != null && submissionStatus.isNotEmpty) {
      params['producer_status'] = submissionStatus;
    }

    final uri = Uri(
      path: '/api/v1/contents/mine/',
      queryParameters: params.isEmpty ? null : params,
    );

    final response = await _api.get(uri.toString(), authenticated: true);

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de charger vos contenus.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }

    if (data is Map<String, dynamic>) {
      final results = data['results'];

      if (results is List) {
        return results.whereType<Map<String, dynamic>>().toList();
      }
    }

    throw const ApiException('Réponse contenus invalide.');
  }

  Future<Map<String, dynamic>> getContent(String contentId) async {
    final response = await _api.get(
      '/api/v1/contents/$contentId/',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de charger le brouillon.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse contenu invalide.');
    }

    return data;
  }

  Future<String> getTeamImagePreview({
    required String contentId,
    required String temporaryPath,
  }) async {
    final cleanPath = temporaryPath.trim();

    if (cleanPath.isEmpty) {
      throw const ApiException('Le chemin temporaire de la photo est vide.');
    }

    final response = await _api.get(
      '/api/v1/contents/$contentId/team-image-preview/'
      '?path=${Uri.encodeQueryComponent(cleanPath)}',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de prévisualiser la photo du producteur.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse de prévisualisation photo invalide.');
    }

    final previewUrl = data['preview_url']?.toString().trim() ?? '';

    if (previewUrl.isEmpty) {
      throw const ApiException('URL de prévisualisation photo absente.');
    }

    return previewUrl;
  }

  Future<Map<String, dynamic>> uploadPrimaryPersonImage({
    required String contentId,
    required String role,
    required List<int> bytes,
    required String filename,
  }) async {
    if (role != 'director' && role != 'screenwriter') {
      throw const ApiException('Rôle de personne non supporté.');
    }

    if (bytes.isEmpty) {
      throw const ApiException('La photo est vide.');
    }

    final response = await _api.postMultipart(
      '/api/v1/contents/$contentId/upload-$role-image/',
      authenticated: true,
      bytes: bytes,
      filename: filename,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(response, fallback: 'Impossible d’envoyer la photo.'),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse photo invalide.');
    }

    final temporaryPath = data['temporary_path']?.toString().trim();

    if (temporaryPath == null || temporaryPath.isEmpty) {
      throw const ApiException('Réponse photo incomplète.');
    }

    return data;
  }

  Future<Map<String, dynamic>> uploadTeamImage({
    required String contentId,
    required List<int> bytes,
    required String filename,
  }) async {
    if (bytes.isEmpty) {
      throw const ApiException('La photo du membre de l’équipe est vide.');
    }

    final response = await _api.postMultipart(
      '/api/v1/contents/$contentId/upload-team-image/',
      authenticated: true,
      bytes: bytes,
      filename: filename,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible d’envoyer la photo du membre de l’équipe.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse photo équipe invalide.');
    }

    final temporaryPath = data['temporary_path']?.toString().trim();

    if (temporaryPath == null || temporaryPath.isEmpty) {
      throw const ApiException('Réponse photo équipe incomplète.');
    }

    return data;
  }

  Future<Map<String, dynamic>> uploadContentMedia({
    required String contentId,
    required String mediaType,
    required List<int> bytes,
    required String filename,
  }) async {
    final allowedTypes = {'poster', 'backdrop', 'trailer'};
    if (!allowedTypes.contains(mediaType)) {
      throw const ApiException('Type de média non supporté.');
    }

    final response = await _api.postMultipart(
      '/api/v1/contents/$contentId/upload-$mediaType/',
      authenticated: true,
      bytes: bytes,
      filename: filename,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(response, fallback: 'Impossible d’envoyer le média.'),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse média invalide.');
    }

    return data;
  }

  Future<Map<String, dynamic>> createTrailerUploadSession({
    required String contentId,
    required String filename,
    required int sizeBytes,
  }) async {
    final response = await _api.post(
      '/api/v1/contents/$contentId/trailer-upload-session/',
      authenticated: true,
      body: {'filename': filename, 'size_bytes': sizeBytes},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de préparer l’envoi du trailer.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse de session trailer invalide.');
    }

    final uploadUrl = data['upload_url'];
    final completionToken = data['completion_token'];

    if (uploadUrl is! String ||
        uploadUrl.isEmpty ||
        completionToken is! String ||
        completionToken.isEmpty) {
      throw const ApiException('Session d’upload trailer incomplète.');
    }

    return data;
  }

  Future<Map<String, dynamic>> completeTrailerUpload({
    required String contentId,
    required String completionToken,
  }) async {
    final response = await _api.post(
      '/api/v1/contents/$contentId/trailer-upload-complete/',
      authenticated: true,
      body: {'completion_token': completionToken},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de confirmer l’envoi du trailer.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse de confirmation trailer invalide.');
    }

    return data;
  }

  Future<Map<String, dynamic>> retryTrailerAnalysis({
    required String contentId,
  }) async {
    final cleanContentId = contentId.trim();

    if (cleanContentId.isEmpty) {
      throw const ApiException('Identifiant de contenu invalide.');
    }

    final response = await _api.post(
      '/api/v1/contents/$cleanContentId/trailer-analysis-retry/',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de relancer l’analyse du trailer.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse de relance trailer invalide.');
    }

    return data;
  }

  Future<Map<String, dynamic>> uploadSeasonMedia({
    required String seasonId,
    required String mediaType,
    required List<int> bytes,
    required String filename,
  }) async {
    final allowedTypes = {'poster', 'backdrop'};

    if (!allowedTypes.contains(mediaType)) {
      throw const ApiException('Type de média Saison non supporté.');
    }

    if (bytes.isEmpty) {
      throw const ApiException('Le fichier média Saison est vide.');
    }

    final cleanSeasonId = seasonId.trim();

    if (cleanSeasonId.isEmpty) {
      throw const ApiException('Identifiant de saison invalide.');
    }

    final response = await _api.postMultipart(
      '/api/v1/seasons/$cleanSeasonId/upload-$mediaType/',
      authenticated: true,
      bytes: bytes,
      filename: filename,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible d’envoyer le média de la saison.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse média Saison invalide.');
    }

    return data;
  }

  Future<Map<String, dynamic>> createSeasonTrailerUploadSession({
    required String seasonId,
    required String filename,
    required int sizeBytes,
  }) async {
    final cleanSeasonId = seasonId.trim();

    if (cleanSeasonId.isEmpty) {
      throw const ApiException('Identifiant de saison invalide.');
    }

    final response = await _api.post(
      '/api/v1/seasons/$cleanSeasonId/trailer-upload-session/',
      authenticated: true,
      body: {'filename': filename, 'size_bytes': sizeBytes},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de préparer l’envoi du trailer de la saison.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse de session trailer Saison invalide.');
    }

    final uploadUrl = data['upload_url'];
    final completionToken = data['completion_token'];

    if (uploadUrl is! String ||
        uploadUrl.isEmpty ||
        completionToken is! String ||
        completionToken.isEmpty) {
      throw const ApiException('Session d’upload trailer Saison incomplète.');
    }

    return data;
  }

  Future<Map<String, dynamic>> completeSeasonTrailerUpload({
    required String seasonId,
    required String completionToken,
  }) async {
    final cleanSeasonId = seasonId.trim();

    if (cleanSeasonId.isEmpty) {
      throw const ApiException('Identifiant de saison invalide.');
    }

    final response = await _api.post(
      '/api/v1/seasons/$cleanSeasonId/trailer-upload-complete/',
      authenticated: true,
      body: {'completion_token': completionToken},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de confirmer le trailer de la saison.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse confirmation trailer Saison invalide.');
    }

    return data;
  }

  Future<Map<String, dynamic>> retrySeasonTrailerAnalysis({
    required String seasonId,
  }) async {
    final cleanSeasonId = seasonId.trim();

    if (cleanSeasonId.isEmpty) {
      throw const ApiException('Identifiant de saison invalide.');
    }

    final response = await _api.post(
      '/api/v1/seasons/$cleanSeasonId/trailer-analysis-retry/',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de relancer l’analyse du trailer de la saison.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse de relance trailer Saison invalide.');
    }

    return data;
  }

  Future<List<Map<String, dynamic>>> getSeasons({
    required String contentId,
  }) async {
    final cleanContentId = contentId.trim();

    if (cleanContentId.isEmpty) {
      throw const ApiException('Identifiant de série invalide.');
    }

    final response = await _api.get(
      '/api/v1/seasons/?content=${Uri.encodeQueryComponent(cleanContentId)}',
      authenticated: true,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de charger les saisons.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }

    if (data is Map<String, dynamic>) {
      final results = data['results'];

      if (results is List) {
        return results.whereType<Map<String, dynamic>>().toList();
      }
    }

    throw const ApiException('Réponse saisons invalide.');
  }

  Future<Map<String, dynamic>> createSeason({
    required String contentId,
    required int seasonNumber,
    String title = '',
    String description = '',
    int episodeCount = 0,
  }) async {
    final response = await _api.post(
      '/api/v1/seasons/',
      authenticated: true,
      body: {
        'content_id': contentId.trim(),
        'season_number': seasonNumber,
        'title': title.trim(),
        'description': description.trim(),
        'episode_count': episodeCount,
      },
    );

    if (response.statusCode != 201) {
      throw ApiException(
        _api.errorMessage(response, fallback: 'Impossible de créer la saison.'),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse création saison invalide.');
    }

    return data;
  }

  Future<Map<String, dynamic>> updateSeason({
    required String seasonId,
    String? title,
    String? description,
    int? episodeCount,
  }) async {
    final body = <String, dynamic>{};

    if (title != null) {
      body['title'] = title.trim();
    }

    if (description != null) {
      body['description'] = description.trim();
    }

    if (episodeCount != null) {
      body['episode_count'] = episodeCount;
    }

    final response = await _api.patch(
      '/api/v1/seasons/${seasonId.trim()}/',
      authenticated: true,
      body: body,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de mettre à jour la saison.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse mise à jour saison invalide.');
    }

    return data;
  }

  Future<void> deleteSeason(String seasonId) async {
    final response = await _api.delete(
      '/api/v1/seasons/${seasonId.trim()}/',
      authenticated: true,
    );

    if (response.statusCode != 204) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de supprimer la saison.',
        ),
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> createEpisode({
    required String seasonId,
    required int episodeNumber,
    required String title,
    String description = '',
    int? duration,
  }) async {
    final response = await _api.post(
      '/api/v1/episodes/',
      authenticated: true,
      body: {
        'season_id': seasonId.trim(),
        'episode_number': episodeNumber,
        'title': title.trim(),
        'description': description.trim(),
        if (duration != null) 'duration': duration,
      },
    );

    if (response.statusCode != 201) {
      throw ApiException(
        _api.errorMessage(response, fallback: 'Impossible de créer l’épisode.'),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse création épisode invalide.');
    }

    return data;
  }

  Future<Map<String, dynamic>> updateEpisode({
    required String episodeId,
    String? title,
    String? description,
    int? duration,
  }) async {
    final body = <String, dynamic>{};

    if (title != null) {
      body['title'] = title.trim();
    }

    if (description != null) {
      body['description'] = description.trim();
    }

    if (duration != null) {
      body['duration'] = duration;
    }

    final response = await _api.patch(
      '/api/v1/episodes/${episodeId.trim()}/',
      authenticated: true,
      body: body,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de mettre à jour l’épisode.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse mise à jour épisode invalide.');
    }

    return data;
  }

  Future<void> deleteEpisode(String episodeId) async {
    final response = await _api.delete(
      '/api/v1/episodes/${episodeId.trim()}/',
      authenticated: true,
    );

    if (response.statusCode != 204) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de supprimer l’épisode.',
        ),
        statusCode: response.statusCode,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getMyVideoAssets({
    String? contentId,
    String? episodeId,
  }) async {
    final params = <String, String>{};

    final cleanContentId = contentId?.trim() ?? '';
    final cleanEpisodeId = episodeId?.trim() ?? '';

    if (cleanContentId.isNotEmpty) {
      params['content'] = cleanContentId;
    }

    if (cleanEpisodeId.isNotEmpty) {
      params['episode'] = cleanEpisodeId;
    }

    final uri = Uri(
      path: '/api/v1/video-assets/mine/',
      queryParameters: params.isEmpty ? null : params,
    );

    final response = await _api.get(uri.toString(), authenticated: true);

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de charger vos ressources vidéo.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }

    if (data is Map<String, dynamic>) {
      final results = data['results'];

      if (results is List) {
        return results.whereType<Map<String, dynamic>>().toList();
      }
    }

    throw const ApiException('Réponse ressources vidéo invalide.');
  }

  Future<Map<String, dynamic>> createVideoAsset({
    required String contentId,
    required String title,
    required String deliveryLevel,
    String? episodeId,
  }) async {
    final cleanEpisodeId = episodeId?.trim() ?? '';
    final cleanDeliveryLevel = deliveryLevel.trim().toLowerCase();

    if (!const {
      'premium',
      'standard',
      'distribution',
    }.contains(cleanDeliveryLevel)) {
      throw const ApiException('Niveau de livraison master invalide.');
    }

    final response = await _api.post(
      '/api/v1/video-assets/',
      authenticated: true,
      body: {
        'content_id': contentId.trim(),
        'title': title.trim(),
        'delivery_level': cleanDeliveryLevel,
        if (cleanEpisodeId.isNotEmpty) 'episode_id': cleanEpisodeId,
      },
    );

    if (response.statusCode != 201) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de créer la ressource vidéo.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse ressource vidéo invalide.');
    }

    return data;
  }

  Future<Map<String, dynamic>> updateVideoAssetDeliveryLevel({
    required String assetId,
    required String deliveryLevel,
  }) async {
    final cleanAssetId = assetId.trim();
    final cleanDeliveryLevel = deliveryLevel.trim().toLowerCase();

    if (cleanAssetId.isEmpty) {
      throw const ApiException('Identifiant de ressource vidéo invalide.');
    }

    if (!const {
      'premium',
      'standard',
      'distribution',
    }.contains(cleanDeliveryLevel)) {
      throw const ApiException('Niveau de livraison master invalide.');
    }

    final response = await _api.patch(
      '/api/v1/video-assets/$cleanAssetId/',
      authenticated: true,
      body: {'delivery_level': cleanDeliveryLevel},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de mettre à jour le niveau du master.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse ressource vidéo invalide.');
    }

    return data;
  }

  Future<Map<String, dynamic>> createSourceUploadSession({
    required String assetId,
    required String filename,
    required int sizeBytes,
  }) async {
    final response = await _api.post(
      '/api/v1/video-assets/$assetId/source-upload-session/',
      authenticated: true,
      body: {'filename': filename, 'size_bytes': sizeBytes},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de préparer l’envoi de la vidéo.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse de session d’upload invalide.');
    }

    final uploadUrl = data['upload_url'];
    final completionToken = data['completion_token'];

    if (uploadUrl is! String ||
        uploadUrl.isEmpty ||
        completionToken is! String ||
        completionToken.isEmpty) {
      throw const ApiException('Session d’upload incomplète.');
    }

    return data;
  }

  Future<Map<String, dynamic>> completeSourceUpload({
    required String assetId,
    required String completionToken,
  }) async {
    final response = await _api.post(
      '/api/v1/video-assets/$assetId/source-upload-complete/',
      authenticated: true,
      body: {'completion_token': completionToken},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de confirmer l’envoi de la vidéo.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse de confirmation d’upload invalide.');
    }

    return data;
  }

  Future<Map<String, dynamic>> uploadVideoSource({
    required String assetId,
    required Stream<List<int>> stream,
    required int length,
    required String filename,
  }) async {
    final response = await _api.postMultipartStream(
      '/api/v1/video-assets/$assetId/upload-source/',
      authenticated: true,
      stream: stream,
      length: length,
      filename: filename,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible d’envoyer la vidéo source.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse upload vidéo invalide.');
    }

    return data;
  }

  Future<Map<String, dynamic>> previewXmlMetadata({
    required List<int> bytes,
    required String filename,
    String? contentId,
  }) async {
    if (bytes.isEmpty) {
      throw const ApiException('Le fichier XML de métadonnées est vide.');
    }

    final normalizedFilename = filename.trim();

    if (normalizedFilename.isEmpty) {
      throw const ApiException('Le nom du fichier XML est invalide.');
    }

    final fields = <String, String>{};

    final normalizedContentId = contentId?.trim() ?? '';

    if (normalizedContentId.isNotEmpty) {
      fields['content_id'] = normalizedContentId;
    }

    final response = await _api.postMultipart(
      '/api/v1/contents/xml-metadata-preview/',
      bytes: bytes,
      filename: normalizedFilename,
      fieldName: 'file',
      authenticated: true,
      fields: fields.isEmpty ? null : fields,
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible d’analyser le fichier XML de métadonnées.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);

    if (data is! Map) {
      throw const ApiException('Réponse de prévisualisation XML invalide.');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> submitContent({
    required String contentId,
    String producerNotes = '',
  }) async {
    final response = await _api.post(
      '/api/v1/contents/$contentId/submit/',
      authenticated: true,
      body: {'producer_notes': producerNotes.trim()},
    );

    if (response.statusCode != 200) {
      throw ApiException(
        _api.errorMessage(
          response,
          fallback: 'Impossible de soumettre le contenu.',
        ),
        statusCode: response.statusCode,
      );
    }

    final data = _api.decode(response);
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Réponse de soumission invalide.');
    }

    return data;
  }
}
