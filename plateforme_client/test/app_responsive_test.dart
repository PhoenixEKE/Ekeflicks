import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_ekeflicks/core/app_responsive.dart';

void main() {
  testWidgets('responsive helpers adapt from phone to TV viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late bool isPhone;
    late bool isTelevision;
    late int columns;

    Future<void> pumpResponsiveView() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isPhone = AppResponsive.isMobile(context);
              isTelevision = AppResponsive.isTVSize(context);
              columns = AppResponsive.contentGridColumns(context);
              return const SizedBox.expand();
            },
          ),
        ),
      );
    }

    await pumpResponsiveView();
    expect(isPhone, isTrue);
    expect(isTelevision, isFalse);
    expect(columns, 2);

    tester.view.physicalSize = const Size(1920, 1080);
    await pumpResponsiveView();
    expect(isPhone, isFalse);
    expect(isTelevision, isTrue);
    expect(columns, 6);
  });
}
