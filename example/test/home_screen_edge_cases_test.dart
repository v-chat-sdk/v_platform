import 'dart:async';

import 'package:example/main.dart';
import 'package:example/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v_platform/v_platform.dart';

void main() {
  testWidgets('disables duplicate picks while a request is pending', (
    tester,
  ) async {
    final result = Completer<List<VPlatformFile>>();
    var calls = 0;

    await tester.pumpWidget(
      MediaPickerApp(
        home: HomeScreen(
          pickFiles: () {
            calls++;
            return result.future;
          },
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Pick files'));
    await tester.pump();

    expect(calls, 1);
    expect(find.text('Picking…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.tap(find.byType(FilledButton));
    expect(calls, 1);

    result.complete(<VPlatformFile>[]);
    await tester.pumpAndSettle();

    expect(find.text('Pick files'), findsOneWidget);
    expect(find.text('No files selected.'), findsOneWidget);
  });

  testWidgets('clears an error after a successful retry', (tester) async {
    var calls = 0;
    final file = VPlatformFile.fromBytes(
      name: 'recovered.txt',
      bytes: <int>[1],
    );

    await tester.pumpWidget(
      MediaPickerApp(
        home: HomeScreen(
          pickFiles: () async {
            calls++;
            if (calls == 1) throw StateError('temporary failure');
            return <VPlatformFile>[file];
          },
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Pick files'));
    await tester.pumpAndSettle();
    expect(find.textContaining('temporary failure'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Pick files'));
    await tester.pumpAndSettle();

    expect(find.textContaining('temporary failure'), findsNothing);
    expect(find.text('recovered.txt'), findsOneWidget);
  });

  testWidgets('ignores a picker result after the screen is disposed', (
    tester,
  ) async {
    final result = Completer<List<VPlatformFile>>();

    await tester.pumpWidget(
      MediaPickerApp(home: HomeScreen(pickFiles: () => result.future)),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Pick files'));
    await tester.pump();

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    result.complete(<VPlatformFile>[
      VPlatformFile.fromBytes(name: 'late.txt', bytes: <int>[1]),
    ]);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
