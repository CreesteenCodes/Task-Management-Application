import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tazk_application/models/note_item.dart';
import 'package:tazk_application/services/notification_service.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<_TextHistoryEntry> _undoStack = [];
  final List<_TextHistoryEntry> _redoStack = [];
  bool _isApplyingHistory = false;
  late TextEditingValue _lastTitleValue;
  late TextEditingValue _lastDescriptionValue;
  DateTime? _selectedDate;
  int _selectedCategoryIndex = 0;

  static const List<_CategoryOption> _categories = [
    _CategoryOption(icon: Icons.person, label: 'Personal'),
    _CategoryOption(icon: Icons.work, label: 'Work'),
    _CategoryOption(icon: Icons.school, label: 'Study'),
    _CategoryOption(icon: Icons.health_and_safety, label: 'Health'),
    _CategoryOption(icon: Icons.event, label: 'Events'),
    _CategoryOption(icon: Icons.more_horiz, label: 'Others'),
  ];

  String get _dueDateLabel {
    if (_selectedDate == null) {
      return 'Select due date';
    }

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

    final month = monthNames[_selectedDate!.month - 1];
    return '$month ${_selectedDate!.day}, ${_selectedDate!.year}';
  }

  Future<void> _pickDueDate() async {
    final minimumDate = NoteItem.minimumValidDueDate();
    final initialDate =
        _selectedDate != null && NoteItem.isValidDueDate(_selectedDate)
        ? _selectedDate!
        : minimumDate;

    final chosenDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minimumDate,
      lastDate: DateTime(minimumDate.year + 5, 12, 31),
      selectableDayPredicate: (day) => NoteItem.isValidDueDate(day),
    );

    if (chosenDate != null) {
      setState(() {
        _selectedDate = DateTime(
          chosenDate.year,
          chosenDate.month,
          chosenDate.day,
        );
      });
    }
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title.')));
      return;
    }

    if (_selectedDate == null || !NoteItem.isValidDueDate(_selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date.')),
      );
      return;
    }

    final note = NoteItem(
      title: title,
      dueDate: _dueDateLabel,
      description: _descriptionController.text.trim(),
      category: _categories[_selectedCategoryIndex].label,
      status: 'Pending',
    );
    final scheduledNote = await NotificationService().syncNotificationForNote(
      note,
    );
    final prefs = await SharedPreferences.getInstance();
    final savedNotes = prefs.getStringList('notes') ?? [];
    final notes =
        savedNotes
            .map((jsonString) => NoteItem.fromJsonString(jsonString))
            .toList()
          ..add(scheduledNote);
    final sortedNotes = NoteItem.sortNotes(notes);
    await prefs.setStringList(
      'notes',
      sortedNotes.map((item) => item.toJsonString()).toList(),
    );

    if (mounted) {
      Navigator.of(context).pop(scheduledNote);
    }
  }

  @override
  void initState() {
    super.initState();
    _lastTitleValue = _titleController.value;
    _lastDescriptionValue = _descriptionController.value;
    _titleController.addListener(_updateTitleHistory);
    _descriptionController.addListener(_updateDescriptionHistory);
  }

  void _updateTitleHistory() {
    _trackHistory('title', _titleController, _lastTitleValue);
    _lastTitleValue = _titleController.value;
  }

  void _updateDescriptionHistory() {
    _trackHistory('description', _descriptionController, _lastDescriptionValue);
    _lastDescriptionValue = _descriptionController.value;
  }

  void _trackHistory(
    String field,
    TextEditingController controller,
    TextEditingValue lastValue,
  ) {
    if (_isApplyingHistory) return;
    final currentValue = controller.value;
    if (currentValue != lastValue) {
      _undoStack.add(_TextHistoryEntry(field, lastValue));
      _redoStack.clear();
    }
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final entry = _undoStack.removeLast();
    final controller = _controllerForField(entry.field);
    _redoStack.add(_TextHistoryEntry(entry.field, controller.value));
    _applyHistoryEntry(entry);
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    final entry = _redoStack.removeLast();
    final controller = _controllerForField(entry.field);
    _undoStack.add(_TextHistoryEntry(entry.field, controller.value));
    _applyHistoryEntry(entry);
  }

  TextEditingController _controllerForField(String field) {
    return field == 'title' ? _titleController : _descriptionController;
  }

  void _applyHistoryEntry(_TextHistoryEntry entry) {
    final controller = _controllerForField(entry.field);
    _isApplyingHistory = true;
    controller.value = entry.value;
    _isApplyingHistory = false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dueDateColor = isDarkMode
        ? Colors.grey.shade400
        : (_selectedDate == null ? Colors.grey.shade600 : Colors.black87);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
              icon: const Text(
                '<',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Back',
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: _undo,
                  tooltip: 'Undo',
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  onPressed: _redo,
                  tooltip: 'Redo',
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _saveNote,
                  tooltip: 'Save',
                ),
              ],
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'Input title',
                      hintStyle: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 56,
                  height: 44,
                  child: Center(
                    child: DropdownButton<int>(
                      value: _selectedCategoryIndex,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      icon: const SizedBox.shrink(),
                      items: List.generate(
                        _categories.length,
                        (index) => DropdownMenuItem<int>(
                          value: index,
                          child: Icon(_categories[index].icon),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategoryIndex = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDueDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      constraints: const BoxConstraints(minHeight: 44),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _dueDateLabel,
                        style: TextStyle(color: dueDateColor, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 56,
                  height: 44,
                  child: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickDueDate,
                    tooltip: 'Pick due date',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _descriptionController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 18, height: 1.4),
                decoration: const InputDecoration(
                  hintText: 'Add notes here...',
                  hintStyle: TextStyle(fontSize: 18),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextHistoryEntry {
  final String field;
  final TextEditingValue value;

  const _TextHistoryEntry(this.field, this.value);
}

class _CategoryOption {
  final IconData icon;
  final String label;

  const _CategoryOption({required this.icon, required this.label});
}
