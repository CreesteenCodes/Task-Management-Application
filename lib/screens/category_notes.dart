import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tazk_application/models/note_item.dart';
import 'note_detail.dart';

class CategoryNotesPage extends StatefulWidget {
  final String category;

  const CategoryNotesPage({super.key, required this.category});

  @override
  State<CategoryNotesPage> createState() => _CategoryNotesPageState();
}

class _CategoryNotesPageState extends State<CategoryNotesPage> {
  List<NoteItem> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNotes = prefs.getStringList('notes') ?? [];
    final allNotes = savedNotes
        .map((jsonString) => NoteItem.fromJsonString(jsonString))
        .toList();

    setState(() {
      _notes = NoteItem.sortNotes(allNotes)
          .where((note) => note.category == widget.category)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.category),
      ),
      body: _notes.isEmpty
          ? SafeArea(
              child: Center(
                child: Text(
                  'No notes in ${widget.category}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.black.withValues(alpha: 0.8),
                  ),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ListView.separated(
                itemCount: _notes.length,
                separatorBuilder: (context, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  return GestureDetector(
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NoteDetailPage(note: note),
                        ),
                      );
                      await _loadNotes();
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 0),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              note.dueDate,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
