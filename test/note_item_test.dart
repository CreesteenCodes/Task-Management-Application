import 'package:flutter_test/flutter_test.dart';
import 'package:tazk_application/models/note_item.dart';

void main() {
  group('NoteItem status progression', () {
    test('only allows forward progress from a current status', () {
      expect(NoteItem.allowedStatuses('Pending'), ['Pending', 'In-Progress', 'Completed']);
      expect(NoteItem.allowedStatuses('In-Progress'), ['In-Progress', 'Completed']);
      expect(NoteItem.allowedStatuses('Completed'), ['Completed']);
    });

    test('reports whether a transition is allowed', () {
      expect(NoteItem.canTransitionTo('Pending', 'In-Progress'), isTrue);
      expect(NoteItem.canTransitionTo('Pending', 'Pending'), isTrue);
      expect(NoteItem.canTransitionTo('In-Progress', 'Pending'), isFalse);
      expect(NoteItem.canTransitionTo('Completed', 'In-Progress'), isFalse);
    });

    test('sorts completed notes by completion date newest first', () {
      final older = NoteItem(
        title: 'Older',
        dueDate: 'June 10, 2026',
        status: 'Completed',
        completedAt: '2024-01-01T10:00:00.000Z',
      );
      final newer = NoteItem(
        title: 'Newer',
        dueDate: 'June 11, 2026',
        status: 'Completed',
        completedAt: '2024-02-02T10:00:00.000Z',
      );

      final sorted = NoteItem.sortCompletedNotes([older, newer]);

      expect(sorted.first.title, 'Newer');
      expect(sorted.last.title, 'Older');
    });

    test('matches search queries against note titles only', () {
      final pendingNote = NoteItem(
        title: 'Plan launch',
        dueDate: 'June 1, 2026',
        description: 'This note is urgent',
        status: 'Pending',
      );
      final inProgressNote = NoteItem(
        title: 'Refine workflow',
        dueDate: 'June 2, 2026',
        description: 'Work on this later',
        status: 'In-Progress',
      );
      final completedNote = NoteItem(
        title: 'Ship release',
        dueDate: 'June 3, 2026',
        description: 'Finished product',
        status: 'Completed',
      );

      expect(pendingNote.matchesQuery('launch'), isTrue);
      expect(inProgressNote.matchesQuery('workflow'), isTrue);
      expect(completedNote.matchesQuery('release'), isTrue);
      expect(completedNote.matchesQuery('finished'), isFalse);
      expect(completedNote.matchesQuery('completed'), isFalse);
      expect(completedNote.matchesQuery('missing'), isFalse);
    });
  });
}
