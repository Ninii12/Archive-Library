import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:the_archieve/main.dart';

void main() {
  testWidgets('saving a book stores it and it survives a restart',
      (tester) async {
    tester.view.physicalSize = const Size(2000, 1250);
    tester.view.devicePixelRatio = 1.25;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ArchiveApp());
    await tester.pumpAndSettle();

    // Add a book through the dialog.
    await tester.tap(find.text('Add a Book'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'My Book');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Book'));
    await tester.pumpAndSettle();

    // It was written to storage...
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('saved_books');
    expect(stored, isNotNull);
    expect(stored, contains('My Book'));

    // ...and it is visible in the room (on the floor as "Want to read").
    expect(find.text('My Book'), findsOneWidget);

    // Restart the app against the same storage: the book stays.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const ArchiveApp());
    await tester.pumpAndSettle();
    expect(find.text('My Book'), findsOneWidget);
  });

  testWidgets('adding a vinyl favorite stores it and it survives a restart',
      (tester) async {
    tester.view.physicalSize = const Size(2000, 1250);
    tester.view.devicePixelRatio = 1.25;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ArchiveApp());
    await tester.pumpAndSettle();

    // Tap the first empty slot on the vinyl wall.
    final emptySlot = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter is VinylPainter &&
          (widget.painter as VinylPainter).empty,
    );
    await tester.tap(emptySlot.first);
    await tester.pumpAndSettle();

    // Add a favorite through the dialog.
    await tester.enterText(find.byType(TextField).first, 'My Favorite');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // It was written to storage...
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('saved_vinyls');
    expect(stored, isNotNull);
    expect(stored, contains('My Favorite'));

    // ...and the label shows under the record.
    expect(find.text('My Favorite'), findsOneWidget);

    // Restart the app against the same storage: the favorite stays.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const ArchiveApp());
    await tester.pumpAndSettle();
    expect(find.text('My Favorite'), findsOneWidget);
  });
}
