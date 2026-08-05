import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_ekeflicks/src/openapi.dart';
import 'package:app_ekeflicks/src/models/profile.dart';
import 'package:app_ekeflicks/src/models/profile_create.dart';

class ProfileProvider extends ChangeNotifier {
  final Openapi apiClient;

  ProfileProvider(this.apiClient);

  List<Profile> _availableProfiles = [];
  List<Profile> get availableProfiles => _availableProfiles;

  Profile? _currentProfile;
  Profile? get currentProfile => _currentProfile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Charge tous les profils pour l'utilisateur connecté (sans dépendance à UserProvider)
  Future<void> loadProfiles() async {
    await loadProfilesGlobal();
  }

  /// Version globale de loadProfiles sans BuildContext (interne)
  Future<void> loadProfilesGlobal() async {
    _isLoading = true;
    notifyListeners();
    await _initPrefs();

    try {
      final response = await apiClient.getProfilesApi().profilesList();
      _availableProfiles = response.data?.results?.toList() ?? [];

      // Restaurer dernier profil sélectionné ou définir le profil "main"
      if (_availableProfiles.isNotEmpty) {
        final lastProfileId = _prefs?.getString('last_profile_id');
        _currentProfile = lastProfileId != null
            ? getProfileById(lastProfileId)
            : _availableProfiles.firstWhere(
                (profile) => profile.type?.name == 'main',
                orElse: () => _availableProfiles.first,
              );
      } else {
        _currentProfile = null;
      }
    } catch (e) {
      debugPrint('Error loading profiles: $e');
      _availableProfiles = [];
      _currentProfile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectProfile(Profile profile) async {
    _currentProfile = profile;
    notifyListeners();
    await _initPrefs();
    if (profile.id != null) await _prefs?.setString('last_profile_id', profile.id!);
  }

  Future<Profile> createProfile({
    required String name,
    required String type,
    String? avatar,
    String? country,
    int? age,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final profileData = ProfileCreate(
        (b) => b
          ..name = name
          ..type = ProfileCreateTypeEnum.valueOf(type)
          ..avatar = avatar
          ..country = country != null ? ProfileCreateCountryEnum.valueOf(country) : null
          ..age = age
          ..phone = phone,
      );

      await apiClient.getProfilesApi().profilesCreate(data: profileData);
      await loadProfilesGlobal();

      final newProfile = _availableProfiles.lastWhere(
        (profile) => profile.name == name,
        orElse: () => _availableProfiles.last,
      );

      if (_currentProfile == null) _currentProfile = newProfile;
      notifyListeners();
      return newProfile;
    } catch (e) {
      debugPrint('Error creating profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Profile?> updateProfile(String profileId, ProfileCreate profileData) async {
    try {
      final existingProfile = getProfileById(profileId);
      if (existingProfile == null) throw Exception('Profil non trouvé');

      final updatedProfile = Profile(
        (b) => b
          ..id = profileId
          ..user = existingProfile.user
          ..name = profileData.name
          ..type = profileData.type != null
              ? ProfileTypeEnum.valueOf(profileData.type!.name)
              : existingProfile.type
          ..avatar = profileData.avatar ?? existingProfile.avatar
          ..avatarUrl = existingProfile.avatarUrl
          ..country = profileData.country != null
              ? ProfileCountryEnum.valueOf(profileData.country!.name)
              : existingProfile.country
          ..age = profileData.age ?? existingProfile.age
          ..phone = profileData.phone ?? existingProfile.phone
          ..isActive = existingProfile.isActive,
      );

      final response =
          await apiClient.getProfilesApi().profilesUpdate(id: profileId, data: updatedProfile);
      return _handleProfileUpdate(response.data, profileId);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  Future<void> deleteProfile(String profileId) async {
    try {
      await apiClient.getProfilesApi().profilesDelete(id: profileId);
      _availableProfiles.removeWhere((profile) => profile.id == profileId);
      if (_currentProfile?.id == profileId) {
        _currentProfile = _availableProfiles.isNotEmpty ? _availableProfiles.first : null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting profile: $e');
      rethrow;
    }
  }

  Profile? _handleProfileUpdate(Profile? updatedProfile, String profileId) {
    if (updatedProfile != null) {
      final index = _availableProfiles.indexWhere((p) => p.id == profileId);
      if (index != -1) {
        _availableProfiles[index] = updatedProfile;
        if (_currentProfile?.id == profileId) _currentProfile = updatedProfile;
        notifyListeners();
      }
    }
    return updatedProfile;
  }

  Profile? getProfileById(String id) {
    try {
      return _availableProfiles.firstWhere((profile) => profile.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> reset() async {
    _availableProfiles = [];
    _currentProfile = null;
    notifyListeners();
  }

  bool get hasProfiles => _availableProfiles.isNotEmpty;
  bool get hasMainProfile => _availableProfiles.any((profile) => profile.type?.name == 'main');
  
  Profile? get mainProfile =>
      _availableProfiles.isNotEmpty
          ? _availableProfiles.firstWhere(
              (profile) => profile.type?.name == 'main',
              orElse: () => _availableProfiles.first)
          : null;
          
  bool isChildProfile(Profile profile) => profile.type?.name == 'child';
}
