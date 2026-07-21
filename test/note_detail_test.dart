import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tazk_application/models/note_item.dart';
import 'package:tazk_application/screens/note_detail.dart';

void main() {
  testWidgets('keeps the due date read-only while editing a note', (
    WidgetTester tester,
  ) async {
    final note = NoteItem(
      title: 'Team sync',
      dueDate: 'July 15, 2026',
      description: 'Discuss milestones',
      category: 'Work',
      status: 'Pending',
    );

    await tester.pumpWidget(
      MaterialApp(home: NoteDetailPage(note: note)),
    );

    expect(find.text('July 15, 2026'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_today_outlined), findsNothing);

    await tester.tap(find.text('Team sync'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsWidgets);
    expect(find.text('July 15, 2026'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_today_outlined), findsNothing);
  });

  testWidgets('prevents editing a completed note', (
    WidgetTester tester,
  ) async {
    final note = NoteItem(
      title: 'Submit report',
      dueDate: 'July 15, 2026',
      description: 'Final version is done',
      category: 'Work',
      status: 'Completed',
      completedAt: '2026-07-12T10:00:00.000Z',
    );

    await tester.pumpWidget(
      MaterialApp(home: NoteDetailPage(note: note)),
    );

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Submit report'), findsOneWidget);
    expect(find.text('July 15, 2026 • Completed July 12, 2026'), findsOneWidget);

    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.byIcon(Icons.check), findsNothing);
  });
}