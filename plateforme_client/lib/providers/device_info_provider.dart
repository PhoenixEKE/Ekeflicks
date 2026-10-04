import 'package:flutter/material.dart';
import 'package:is_tv/is_tv.dart';

class DeviceInfoProvider with ChangeNotifier {
  bool _isTV = false;
  bool _isMobile = true; // Par défaut on suppose mobile
  bool _isDesktop = false;
  bool _isTablet = false;
  bool _isInitialized = false;

  bool get isTV => _isTV;
  bool get isMobile => _isMobile;
  bool get isDesktop => _isDesktop;
  bool get isTablet => _isTablet;
  bool get isInitialized => _isInitialized;

  DeviceInfoProvider() {
    init();
  }

  Future<void> init() async {
    try {
      final isTVPlugin = IsTV();
      _isTV = await isTVPlugin.check() ?? false;

      // Déterminer si c'est un desktop basé sur la taille d'écran
      // Cette logique sera complétée dans le build method
      _isMobile = !_isTV; // Pour l'instant, simple approximation
      _isDesktop = false; // Sera ajusté dynamiquement
      _isTablet = false;
    } catch (e) {
      debugPrint('Error detecting TV: $e');
      _isTV = false;
      _isMobile = true;
      _isDesktop = false;
      _isTablet = false;
    }
    _isInitialized = true;
    notifyListeners();
  }

  // Méthode pour mettre à jour le type d'appareil basé sur la taille
  void updateDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final nextDesktop = width >= 1024 && !_isTV;
    final nextMobile = width < 600 && !_isTV;
    final nextTablet = !nextDesktop && !nextMobile && !_isTV;

    if (_isDesktop == nextDesktop &&
        _isMobile == nextMobile &&
        _isTablet == nextTablet) {
      return;
    }

    _isDesktop = nextDesktop;
    _isMobile = nextMobile;
    _isTablet = nextTablet;
    notifyListeners();
  }
}
