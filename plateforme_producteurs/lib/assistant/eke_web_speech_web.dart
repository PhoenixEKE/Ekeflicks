import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<bool> speakWithGender(String text, String language, String gender) async {
  final synthesis = web.window.speechSynthesis;
  var voices = synthesis.getVoices().toDart;
  if (voices.isEmpty) {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    voices = synthesis.getVoices().toDart;
  }
  final lang = language.toLowerCase();
  final feminine = gender == 'female';
  final markers = feminine
      ? ['female', 'femme', 'woman', 'girl', 'samantha', 'karen', 'amelie', 'julie', 'audrey', 'claire', 'zira', 'hazel', 'victoria', 'monica', 'ava']
      : ['male', 'homme', 'man', 'boy', 'thomas', 'daniel', 'paul', 'nicolas', 'david', 'mark', 'antoine', 'henri', 'fred'];
  final localeVoices = voices.where((voice) => voice.lang.toLowerCase().startsWith(lang.split('-').first)).toList();
  bool matches(web.SpeechSynthesisVoice voice) {
    final name = voice.name.toLowerCase();
    if (feminine && name.contains('male') && !name.contains('female')) return false;
    if (!feminine && (name.contains('female') || name.contains('woman') || name.contains('femme'))) return false;
    return markers.any(name.contains);
  }
  web.SpeechSynthesisVoice? selected;
  for (final voice in localeVoices) {
    if (matches(voice)) { selected = voice; break; }
  }
  if (selected == null) {
    for (final voice in voices) {
      if (matches(voice)) { selected = voice; break; }
    }
  }
  if (selected == null) return false;
  final utterance = web.SpeechSynthesisUtterance(text);
  utterance.lang = language;
  utterance.voice = selected;
  synthesis.cancel();
  synthesis.speak(utterance);
  return true;
}
