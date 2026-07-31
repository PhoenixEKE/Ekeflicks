import 'package:flutter/material.dart';

class KeyboardTextManager {
  final TextEditingController controller;
  int cursorPosition = 0;
  final ValueNotifier<int> cursorNotifier = ValueNotifier<int>(0);

  KeyboardTextManager(this.controller) {
    // Initialiser la position du curseur
    cursorPosition = controller.selection.baseOffset;
    if (cursorPosition == -1) {
      cursorPosition = controller.text.length;
    }
    cursorNotifier.value = cursorPosition;

    // Écouter les changements de sélection
    controller.addListener(_updateCursorPosition);
  }

  // Méthode interne pour mettre à jour la position du curseur
  void _updateCursorPosition() {
    cursorPosition = controller.selection.baseOffset;
    if (cursorPosition == -1) {
      cursorPosition = controller.text.length;
    }
    cursorNotifier.value = cursorPosition;
  }

  /// Méthode publique appelée depuis les écrans pour forcer la mise à jour du curseur
  void updateCursorPosition() {
    _updateCursorPosition();
  }

  void insertText(String text) {
    final currentText = controller.text;
    final safeCursorPosition = cursorPosition.clamp(0, currentText.length);

    final newText = currentText.substring(0, safeCursorPosition) +
        text +
        currentText.substring(safeCursorPosition);

    controller.text = newText;

    final newPosition = safeCursorPosition + text.length;
    cursorPosition = newPosition;

    controller.selection = TextSelection.collapsed(offset: newPosition);
    cursorNotifier.value = newPosition;
  }

  void backspace() {
    if (cursorPosition > 0 && controller.text.isNotEmpty) {
      final currentText = controller.text;
      final safeCursorPosition = cursorPosition.clamp(0, currentText.length);

      if (safeCursorPosition > 0) {
        final newText = currentText.substring(0, safeCursorPosition - 1) +
            currentText.substring(safeCursorPosition);

        controller.text = newText;

        final newPosition = safeCursorPosition - 1;
        cursorPosition = newPosition;

        controller.selection = TextSelection.collapsed(offset: newPosition);
        cursorNotifier.value = newPosition;
      }
    }
  }

  void moveCursorLeft() {
    if (cursorPosition > 0) {
      final newPosition = cursorPosition - 1;
      cursorPosition = newPosition;
      controller.selection = TextSelection.collapsed(offset: newPosition);
      cursorNotifier.value = newPosition;
    }
  }

  void moveCursorRight() {
    if (cursorPosition < controller.text.length) {
      final newPosition = cursorPosition + 1;
      cursorPosition = newPosition;
      controller.selection = TextSelection.collapsed(offset: newPosition);
      cursorNotifier.value = newPosition;
    }
  }

  void clear() {
    controller.clear();
    cursorPosition = 0;
    controller.selection = TextSelection.collapsed(offset: 0);
    cursorNotifier.value = 0;
  }

  void dispose() {
    controller.removeListener(_updateCursorPosition);
    cursorNotifier.dispose();
  }

  void safeUpdateSelection(int position) {
    final safePosition = position.clamp(0, controller.text.length);
    cursorPosition = safePosition;
    controller.selection = TextSelection.collapsed(offset: safePosition);
    cursorNotifier.value = safePosition;
  }

  // Méthodes supplémentaires pour la compatibilité
  String get currentText => controller.text;
  
  set currentText(String value) {
    controller.text = value;
    cursorPosition = value.length;
    controller.selection = TextSelection.collapsed(offset: value.length);
    cursorNotifier.value = value.length;
  }
  
  void addText(String text) {
    insertText(text);
  }
  
  void removeLastCharacter() {
    backspace();
  }
}