import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_item.dart';
import '../services/settings_service.dart';
import 'note_detail.dart';

String formatDeletedAtDisplay(String? deletedAt) {
  if (deletedAt == null || deletedAt.trim().isEmpty) {
    return 'Deleted •';
  }

  final parsed = DateTime.tryParse(deletedAt);
  if (parsed == null) {
    return 'Deleted •';
  }

  final localDate = parsed.toLocal();
  const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return 'Deleted • ${monthNames[localDate.month - 1]} ${localDate.day}, ${localDate.year}';
}

class RecentlyDeletedScreen extends StatefulWidget {
  const RecentlyDeletedScreen({super.key});

  @override
  State<RecentlyDeletedScreen> createState() => _RecentlyDeletedScreenState();
}

class _RecentlyDeletedScreenState extends State<RecentlyDeletedScreen> {
  List<NoteItem> _deletedNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeletedNotes();
  }

  Future<void> _loadDeletedNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final deletedNotes = prefs.getStringList('deleted_notes') ?? [];

    final parsedNotes = deletedNotes
        .map((jsonString) => NoteItem.fromJsonString(jsonString))
        .toList();

    final todayUtc = DateTime.now().toUtc();
    final expiryUtc = todayUtc.subtract(const Duration(days: 30));
    final filteredNotes = parsedNotes.where((note) {
      if (note.deletedAt == null) {
        return false;
      }
      final deletedAt = DateTime.tryParse(note.deletedAt!);
      return deletedAt != null && !deletedAt.isBefore(expiryUtc);
    }).toList();

    if (filteredNotes.length != parsedNotes.length) {
      final savedStrings = filteredNotes.map((note) => note.toJsonString()).toList();
      await prefs.setStringList('deleted_notes', savedStrings);
      await SettingsService().refreshDeletedCount();
    }

    if (!mounted) return;

    setState(() {
      _deletedNotes = NoteItem.sortDeletedNotes(filteredNotes);
      _isLoading = false;
    });
  }

  Future<void> _restoreNote(NoteItem note) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedNotes = prefs.getStringList('deleted_notes') ?? [];
    final remainingDeletedNotes = deletedNotes.where((jsonString) {
      final parsed = NoteItem.fromJsonString(jsonString);
      return parsed.title != note.title || parsed.dueDate != note.dueDate;
    }).toList();

    final savedNotes = prefs.getStringList('notes') ?? [];
    final updatedNotes = [...savedNotes, note.toJsonString()];
    final sortedNotes = NoteItem.sortNotes(
      updatedNotes.map((jsonString) => NoteItem.fromJsonString(jsonString)).toList(),
    );

    await prefs.setStringList('deleted_notes', remainingDeletedNotes);
    await prefs.setStringList(
      'notes',
      sortedNotes.map((item) => item.toJsonString()).toList(),
    );
    await SettingsService().refreshDeletedCount();

    if (mounted) {
      await _loadDeletedNotes();
    }
  }

  Future<void> _deleteNotePermanently(NoteItem note) async {
    final prefs = await SharedPreferences.getInstance();
    final deletedNotes = prefs.getStringList('deleted_notes') ?? [];
    final remainingDeletedNotes = deletedNotes.where((jsonString) {
      final parsed = NoteItem.fromJsonString(jsonString);
      return parsed.title != note.title || parsed.dueDate != note.dueDate;
    }).toList();

    await prefs.setStringList('deleted_notes', remainingDeletedNotes);
    await SettingsService().refreshDeletedCount();

    if (mounted) {
      await _loadDeletedNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently Deleted'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(15, 15, 15, 12),
                  child: Center(
                    child: Text(
                      'Recently deleted notes will be kept here for 30 days, after which they will be automatically and permanently deleted.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(
                  child: _deletedNotes.isEmpty
                      ? const Center(child: Text('No deleted notes yet.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          itemCount: _deletedNotes.length,
                          itemBuilder: (_, index) {
                            final note = _deletedNotes[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => NoteDetailPage(
                                        note: note,
                                        isDeletedView: true,
                                      ),
                                    ),
                                  );
                                },
                                title: Text(
                                  note.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(formatDeletedAtDisplay(note.deletedAt)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.restore),
                                      onPressed: () => _restoreNote(note),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _deleteNotePermanently(note),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
