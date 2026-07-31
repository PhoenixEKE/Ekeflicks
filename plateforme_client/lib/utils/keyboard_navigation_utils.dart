// keyboard_navigation_utils.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service de gestion de la navigation par télécommande/clavier
class KeyboardNavigationService {
  /// Vérifie si l'événement est une touche de navigation
  static bool isNavigationKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return false;
    
    return [
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.select,
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.backspace,
      LogicalKeyboardKey.escape,
      LogicalKeyboardKey.tab,
    ].contains(event.logicalKey);
  }

  /// Gère les événements de navigation de base
  static KeyEventResult handleBasicNavigation(
    RawKeyEvent event, {
    VoidCallback? onSelect,
    VoidCallback? onBack,
    VoidCallback? onUp,
    VoidCallback? onDown,
    VoidCallback? onLeft,
    VoidCallback? onRight,
    bool allowArrowNavigation = true,
  }) {
    if (event is RawKeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowRight:
          if (allowArrowNavigation) onRight?.call();
          return onRight != null ? KeyEventResult.handled : KeyEventResult.ignored;
        
        case LogicalKeyboardKey.arrowLeft:
          if (allowArrowNavigation) onLeft?.call();
          return onLeft != null ? KeyEventResult.handled : KeyEventResult.ignored;
        
        case LogicalKeyboardKey.arrowUp:
          if (allowArrowNavigation) onUp?.call();
          return onUp != null ? KeyEventResult.handled : KeyEventResult.ignored;
        
        case LogicalKeyboardKey.arrowDown:
          if (allowArrowNavigation) onDown?.call();
          return onDown != null ? KeyEventResult.handled : KeyEventResult.ignored;
        
        case LogicalKeyboardKey.select:
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.space:
          onSelect?.call();
          return onSelect != null ? KeyEventResult.handled : KeyEventResult.ignored;
        
        case LogicalKeyboardKey.backspace:
        case LogicalKeyboardKey.escape:
          onBack?.call();
          return onBack != null ? KeyEventResult.handled : KeyEventResult.ignored;
        
        case LogicalKeyboardKey.tab:
          // Handle tab navigation if needed
          return KeyEventResult.ignored;
        
        default:
          return KeyEventResult.ignored;
      }
    }
    return KeyEventResult.ignored;
  }

  /// Gère les événements de navigation pour les listes et grilles
  static KeyEventResult handleListNavigation(
    RawKeyEvent event, {
    required int currentIndex,
    required int itemCount,
    required Function(int) onIndexChange,
    int columns = 1,
    VoidCallback? onSelect,
    VoidCallback? onBack,
  }) {
    if (event is RawKeyDownEvent) {
      int newIndex = currentIndex;

      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowRight:
          if (columns > 1) {
            // Navigation horizontale dans une grille
            if ((currentIndex + 1) % columns != 0 && currentIndex < itemCount - 1) {
              newIndex = currentIndex + 1;
            }
          } else if (currentIndex < itemCount - 1) {
            newIndex = currentIndex + 1;
          }
          break;
        
        case LogicalKeyboardKey.arrowLeft:
          if (columns > 1) {
            // Navigation horizontale dans une grille
            if (currentIndex % columns != 0 && currentIndex > 0) {
              newIndex = currentIndex - 1;
            }
          } else if (currentIndex > 0) {
            newIndex = currentIndex - 1;
          }
          break;
        
        case LogicalKeyboardKey.arrowDown:
          if (columns > 1) {
            // Navigation verticale dans une grille
            newIndex = (currentIndex + columns).clamp(0, itemCount - 1);
          } else if (currentIndex < itemCount - 1) {
            newIndex = currentIndex + 1;
          }
          break;
        
        case LogicalKeyboardKey.arrowUp:
          if (columns > 1) {
            // Navigation verticale dans une grille
            newIndex = (currentIndex - columns).clamp(0, itemCount - 1);
          } else if (currentIndex > 0) {
            newIndex = currentIndex - 1;
          }
          break;
        
        case LogicalKeyboardKey.select:
        case LogicalKeyboardKey.enter:
        case LogicalKeyboardKey.space:
          onSelect?.call();
          return KeyEventResult.handled;
        
        case LogicalKeyboardKey.backspace:
        case LogicalKeyboardKey.escape:
          onBack?.call();
          return KeyEventResult.handled;
        
        default:
          return KeyEventResult.ignored;
      }

      if (newIndex != currentIndex) {
        onIndexChange(newIndex);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
}

/// Mixin pour ajouter la navigation clavier
mixin KeyboardNavigationMixin<T extends StatefulWidget> on State<T> {
  final Map<LogicalKeyboardKey, VoidCallback> _keyHandlers = {};
  final FocusNode _focusNode = FocusNode();

  /// Ajoute un gestionnaire de touche
  void addKeyHandler(LogicalKeyboardKey key, VoidCallback handler) {
    _keyHandlers[key] = handler;
  }

  /// Supprime un gestionnaire de touche
  void removeKeyHandler(LogicalKeyboardKey key) {
    _keyHandlers.remove(key);
  }

  /// Gère les événements clavier
  KeyEventResult handleKeyEvent(FocusNode node, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final handler = _keyHandlers[event.logicalKey];
      if (handler != null) {
        handler();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _keyHandlers.clear();
    super.dispose();
  }
}

/// Widget wrapper pour la navigation clavier
class KeyboardNavigator extends StatefulWidget {
  final Widget child;
  final FocusNode? focusNode;
  final Map<LogicalKeyboardKey, VoidCallback> keyHandlers;
  final bool autofocus;
  final ValueChanged<bool>? onFocusChange;

  const KeyboardNavigator({
    super.key,
    required this.child,
    this.focusNode,
    this.keyHandlers = const {},
    this.autofocus = false,
    this.onFocusChange,
  });

  @override
  State<KeyboardNavigator> createState() => _KeyboardNavigatorState();
}

class _KeyboardNavigatorState extends State<KeyboardNavigator> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    widget.onFocusChange?.call(_focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKey: (node, event) {
        if (event is RawKeyDownEvent) {
          final handler = widget.keyHandlers[event.logicalKey];
          if (handler != null) {
            handler();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}