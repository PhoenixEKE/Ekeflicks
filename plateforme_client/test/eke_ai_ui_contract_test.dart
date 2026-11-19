import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('spectator EKE IA UI contract is wired to public API', () {
    final service = File('lib/services/eke_ai_service.dart').readAsStringSync();

    final home = File('lib/ui/home/home_screen.dart').readAsStringSync();

    final assistant =
        File('lib/ui/pages/eke_ai_assistant_page.dart').readAsStringSync();

    final search =
        File('lib/ui/pages/eke_ai_search_page.dart').readAsStringSync();

    final baseBar =
        File('lib/widgets/app_bars/base_app_bar.dart').readAsStringSync();

    final connectBar =
        File('lib/widgets/app_bars/connect_app_bar.dart').readAsStringSync();

    expect(service, contains("'eke-ai'"));
    expect(service, contains('for-you/'));
    expect(service, contains('search/'));
    expect(service, contains('chat/'));
    expect(service, contains('explain/'));
    expect(service, contains('feedback/'));

    expect(home, contains('Pour vous — EKE IA'));
    expect(home, contains('EkeAIAssistantPage'));
    expect(home, contains('.forYou('));
    expect(home, contains('.feedback('));
    expect(home, contains('.explain('));

    expect(assistant, contains('.chat('));
    expect(assistant, contains('.feedback('));
    expect(assistant, contains('.explain('));

    expect(search, contains('.search('));
    expect(search, contains('.explain('));

    expect(baseBar, contains('EkeAISearchPage'));
    expect(connectBar, contains('EkeAISearchPage'));
  });

  test('legacy IA search delegate no longer exists', () {
    expect(
      File('lib/widgets/search/ia_search_delegate.dart').existsSync(),
      isFalse,
    );
  });

  test('no public legacy recommendations routes remain in spectator UI', () {
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final text = file.readAsStringSync();

      expect(
        text.contains('/api/v1/recommendations/'),
        isFalse,
        reason: file.path,
      );
    }
  });
}
