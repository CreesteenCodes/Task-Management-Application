import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tazk_application/models/note_item.dart';
import 'package:tazk_application/services/notification_service.dart';
import 'package:tazk_application/services/settings_service.dart';

class NoteDetailPage extends StatefulWidget {
  final NoteItem note;
  final bool isDeletedView;

  const NoteDetailPage({
    super.key,
    required this.note,
    this.isDeletedView = false,
  });

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late String _status;
  late NoteItem _note;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isEditing = false;

  List<String> get _availableStatuses => NoteItem.allowedStatuses(_status);

  bool get _canEditNote => !widget.isDeletedView && _status != 'Completed';

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    _status = _note.status;
    _titleController = TextEditingController(text: _note.title);
    _descriptionController = TextEditingController(text: _note.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatIsoDate(String isoDateString) {
    final parsed = DateTime.tryParse(isoDateString);
    if (parsed == null) return '';
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
    return '${monthNames[localDate.month - 1]} ${localDate.day}, ${localDate.year}';
  }

  String _buildDueDateText() {
    final dueDateText = _note.dueDate.trim();
    final completedAtText = _note.completedAt != null
        ? 'Completed ${_formatIsoDate(_note.completedAt!)}'
        : '';

    if (dueDateText.isNotEmpty && completedAtText.isNotEmpty) {
      return '$dueDateText • $completedAtText';
    }
    if (dueDateText.isNotEmpty) {
      return dueDateText;
    }
    return completedAtText;
  }

  Future<void> _saveNote() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNotes = prefs.getStringList('notes') ?? [];
    final completedAt = _status == 'Completed' && _note.status != 'Completed'
        ? DateTime.now().toUtc().toIso8601String()
        : _note.completedAt;

    final updatedNote = _note.copyWith(
      title: _titleController.text,
      status: _status,
      description: _descriptionController.text,
      completedAt: completedAt,
      dueDate: _note.dueDate,
      notificationId: _note.notificationId,
    );
    final scheduledNote = await NotificationService().syncNotificationForNote(
      updatedNote,
    );

    final updatedList = savedNotes.map((jsonString) {
      final parsed = NoteItem.fromJsonString(jsonString);
      if (parsed.title == _note.title && parsed.dueDate == _note.dueDate) {
        return scheduledNote.toJsonString();
      }
      return jsonString;
    }).toList();

    final updatedNotes = updatedList
        .map((jsonString) => NoteItem.fromJsonString(jsonString))
        .toList();
    final sortedNotes = NoteItem.sortNotes(updatedNotes);

    await prefs.setStringList(
      'notes',
      sortedNotes.map((note) => note.toJsonString()).toList(),
    );
    _note = scheduledNote;
  }

  Future<void> _deleteNote() async {
    await NotificationService().cancelNotification(_note.notificationId);
    final prefs = await SharedPreferences.getInstance();
    final savedNotes = prefs.getStringList('notes') ?? [];

    // Move the deleted note JSON to deleted_notes list
    final deletedList = prefs.getStringList('deleted_notes') ?? [];
    final deletedNote = _note.copyWith(
      deletedAt: DateTime.now().toUtc().toIso8601String(),
    );
    deletedList.insert(0, deletedNote.toJsonString());
    await prefs.setStringList('deleted_notes', deletedList);

    final filtered = savedNotes.where((jsonString) {
      final parsed = NoteItem.fromJsonString(jsonString);
      return parsed.title != _note.title || parsed.dueDate != _note.dueDate;
    }).toList();

    final remainingNotes = filtered
        .map((jsonString) => NoteItem.fromJsonString(jsonString))
        .toList();
    final sortedNotes = NoteItem.sortNotes(remainingNotes);

    await prefs.setStringList(
      'notes',
      sortedNotes.map((note) => note.toJsonString()).toList(),
    );

    // refresh settings service deleted count
    try {
      SettingsService().refreshDeletedCount();
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showStatusSelector = _canEditNote;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final statusBoxColor = const Color(0xFFD8E2FF);
    final statusBoxTextColor = Colors.black;
    final dropdownItemTextColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: null,
        actions: widget.isDeletedView
            ? null
            : _isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () async {
                    await _saveNote();
                    setState(() => _isEditing = false);
                  },
                ),
              ]
            : [
                if (showStatusSelector)
                  Container(
                    constraints: const BoxConstraints(minWidth: 80),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusBoxColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _status,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      icon: const SizedBox.shrink(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: statusBoxTextColor,
                      ),
                      selectedItemBuilder: (context) => _availableStatuses
                          .map(
                            (value) => Text(
                              value,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: statusBoxTextColor,
                              ),
                            ),
                          )
                          .toList(),
                      items: _availableStatuses
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: dropdownItemTextColor,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) async {
                        if (value == null) return;
                        if (!NoteItem.canTransitionTo(_status, value)) {
                          return;
                        }
                        setState(() => _status = value);
                        await _saveNote();
                      },
                    ),
                  ),
                if (showStatusSelector) const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _deleteNote,
                  tooltip: 'Delete',
                ),
              ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _canEditNote ? () => setState(() => _isEditing = true) : null,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _isEditing
                        ? TextField(
                            controller: _titleController,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          )
                        : Text(
                            _note.title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8E2FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _note.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2A2F5A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _buildDueDateText(),
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GestureDetector(
                onTap: _canEditNote ? () => setState(() => _isEditing = true) : null,
                child: _isEditing
                    ? TextField(
                        controller: _descriptionController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          hintText: 'Add notes...',
                          hintStyle: TextStyle(fontSize: 18),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(fontSize: 18, height: 1.5),
                      )
                    : SingleChildScrollView(
                        child: Text(
                          _note.description.isEmpty
                              ? 'No notes.'
                              : _note.description,
                          style: const TextStyle(fontSize: 18, height: 1.5),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
