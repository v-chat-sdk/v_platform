import 'package:example/main.dart';
import 'package:example/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v_platform/v_platform.dart';

void main() {
  testWidgets('shows selected file metadata', (tester) async {
    final file = VPlatformFile.fromBytes(
      name: 'avatar.png',
      bytes: <int>[1, 2, 3],
    );

    await tester.pumpWidget(
      MediaPickerApp(
        home: HomeScreen(pickFiles: () async => <VPlatformFile>[file]),
      ),
    );

    expect(find.text('No files selected.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Pick files'));
    await tester.pumpAndSettle();

    expect(find.text('No files selected.'), findsNothing);
    expect(find.text('avatar.png'), findsOneWidget);
    expect(find.textContaining('image • .png'), findsOneWidget);
  });

  testWidgets('surfaces picker errors and stays usable', (tester) async {
    await tester.pumpWidget(
      MediaPickerApp(
        home: HomeScreen(
          pickFiles: () async => throw StateError('picker unavailable'),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Pick files'));
    await tester.pumpAndSettle();

    expect(find.textContaining('picker unavailable'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Pick files'), findsOneWidget);
  });
}
