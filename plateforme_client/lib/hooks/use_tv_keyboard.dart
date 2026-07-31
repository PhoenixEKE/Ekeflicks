import 'package:flutter/material.dart';
import 'package:app_ekeflicks/utils/keyboard_text_manager.dart';

class TvKeyboardHook {
  final bool showVirtualKeyboard;
  final Function(bool) setShowVirtualKeyboard;
  final KeyboardTextManager? textManager;
  final FocusNode keyboardFocusNode;

  TvKeyboardHook({
    required this.showVirtualKeyboard,
    required this.setShowVirtualKeyboard,
    required this.textManager,
    required this.keyboardFocusNode,
  });

  void toggleVirtualKeyboard() {
    setShowVirtualKeyboard(!showVirtualKeyboard);
  }

  void handleKeyboardInput(String text) {
    textManager?.insertText(text);
  }

  void handleKeyboardBackspace() {
    textManager?.backspace();
  }
}

TvKeyboardHook useTvKeyboard({
  required bool initialShowState,
  required TextEditingController controller,
}) {
  final showVirtualKeyboard = ValueNotifier<bool>(initialShowState);
  final keyboardFocusNode = FocusNode();
  final textManager = KeyboardTextManager(controller);

  return TvKeyboardHook(
    showVirtualKeyboard: showVirtualKeyboard.value,
    setShowVirtualKeyboard: (value) => showVirtualKeyboard.value = value,
    textManager: textManager,
    keyboardFocusNode: keyboardFocusNode,
  );
}