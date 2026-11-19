// focus_utils.dart
import 'package:flutter/material.dart';

/// Service de gestion du focus pour la navigation TV
class FocusUtils {
  /// Crée un indicateur de focus visuel pour les éléments TV
  static Widget buildFocusIndicator({
    required Widget child,
    required FocusNode focusNode,
    Color focusColor = Colors.orange,
    Color unfocusedColor = Colors.transparent,
    double borderWidth = 2.0,
    double borderRadius = 8.0,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return Focus(
      focusNode: focusNode,
      onFocusChange: (hasFocus) {
        // Optional: Add focus change callbacks if needed
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: focusNode.hasFocus ? focusColor : unfocusedColor,
            width: borderWidth,
          ),
          color:
              focusNode.hasFocus
                  ? focusColor.withValues(alpha: 0.1)
                  : Colors.transparent,
        ),
        child: child,
      ),
    );
  }

  /// Anime le focus (effet de pulsation)
  static Widget buildPulsatingFocus({
    required Widget child,
    required FocusNode focusNode,
    Color focusColor = Colors.orange,
    Duration duration = const Duration(milliseconds: 500),
    double minBorderWidth = 2.0,
    double maxBorderWidth = 4.0,
  }) {
    return Focus(
      focusNode: focusNode,
      child: AnimatedContainer(
        duration: duration,
        decoration: BoxDecoration(
          border: Border.all(
            color: focusNode.hasFocus ? focusColor : Colors.transparent,
            width: focusNode.hasFocus ? maxBorderWidth : minBorderWidth,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: child,
      ),
    );
  }
}

/// Mixin pour gérer le focus entre plusieurs éléments
mixin FocusManagementMixin<T extends StatefulWidget> on State<T> {
  final List<FocusNode> _focusNodes = [];
  int _currentFocusIndex = 0;

  /// Ajoute un nœud de focus à la gestion
  FocusNode registerFocusNode([String? debugLabel]) {
    final node = FocusNode(debugLabel: debugLabel);
    _focusNodes.add(node);
    return node;
  }

  /// Ajoute un nœud de focus existant
  void addExistingFocusNode(FocusNode node) {
    if (!_focusNodes.contains(node)) {
      _focusNodes.add(node);
    }
  }

  /// Passe au focus suivant
  void nextFocus() {
    if (_focusNodes.isEmpty) return;

    _focusNodes[_currentFocusIndex].unfocus();
    _currentFocusIndex = (_currentFocusIndex + 1) % _focusNodes.length;
    _focusNodes[_currentFocusIndex].requestFocus();
  }

  /// Passe au focus précédent
  void previousFocus() {
    if (_focusNodes.isEmpty) return;

    _focusNodes[_currentFocusIndex].unfocus();
    _currentFocusIndex = (_currentFocusIndex - 1) % _focusNodes.length;
    if (_currentFocusIndex < 0) _currentFocusIndex = _focusNodes.length - 1;
    _focusNodes[_currentFocusIndex].requestFocus();
  }

  /// Définit le focus sur un index spécifique
  void setFocus(int index) {
    if (index >= 0 && index < _focusNodes.length) {
      _focusNodes[_currentFocusIndex].unfocus();
      _currentFocusIndex = index;
      _focusNodes[_currentFocusIndex].requestFocus();
    }
  }

  /// Obtient le nœud de focus actuel
  FocusNode? get currentFocusNode =>
      _focusNodes.isNotEmpty ? _focusNodes[_currentFocusIndex] : null;

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    _focusNodes.clear();
    super.dispose();
  }
}
