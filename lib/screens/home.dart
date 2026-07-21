import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tazk_application/models/note_item.dart';
import 'package:tazk_application/models/task.dart';
import 'package:tazk_application/services/notification_service.dart';
import 'dart:ui';
import 'add_task.dart';
import 'category_notes.dart';
import 'note_detail.dart';
import 'settings.dart';
import 'package:tazk_application/services/settings_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;
  int _selectedBottomTab = 0;
  List<NoteItem> _notes = [];
  bool _isSearching = false;
  String _searchQuery = '';
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNotes = prefs.getStringList('notes') ?? [];
    final loadedNotes = savedNotes
        .map((jsonString) => NoteItem.fromJsonString(jsonString))
        .toList();
    final syncedNotes = await NotificationService().syncNotificationsForNotes(
      loadedNotes,
    );
    final sortedNotes = NoteItem.sortNotes(syncedNotes);
    await prefs.setStringList(
      'notes',
      sortedNotes.map((note) => note.toJsonString()).toList(),
    );
    setState(() {
      _notes = sortedNotes;
    });
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final sortedNotes = NoteItem.sortNotes(_notes);
    await prefs.setStringList(
      'notes',
      sortedNotes.map((note) => note.toJsonString()).toList(),
    );
    setState(() {
      _notes = sortedNotes;
    });
  }

  Future<void> _openAddTask() async {
    final result = await Navigator.of(
      context,
    ).push<NoteItem>(MaterialPageRoute(builder: (_) => const AddTaskPage()));

    if (result != null) {
      setState(() {
        _notes = NoteItem.sortNotes([..._notes, result]);
      });
      await _saveNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final activeAccentColor = isDarkMode
        ? const Color(0xFFD8E2FF)
        : Theme.of(context).primaryColor;
    final inactiveColor = isDarkMode ? Colors.white70 : Colors.black54;
    final activeNotes = _notes
        .where((note) => note.status != 'Completed')
        .toList();
    final completedNotes = _notes
        .where((note) => note.status == 'Completed')
        .toList();
    final searchResults = _searchQuery.isEmpty
        ? activeNotes
        : _notes.where((note) => note.matchesQuery(_searchQuery)).toList();

    return Scaffold(
      resizeToAvoidBottomInset: !_isSearching,
      appBar: AppBar(
        centerTitle: false,
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              )
            : null,
        title: _isSearching
            ? TextField(
                focusNode: _searchFocusNode,
                controller: _searchController,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontSize: 18,
                ),
                cursorColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                decoration: InputDecoration(
                  hintText: 'Search for Notes',
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black45,
                    fontSize: 18,
                  ),
                  border: InputBorder.none,
                ),
              )
            : Text(
                _selectedBottomTab == 1 ? 'Insights' : 'Tazk',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: _isSearching
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                      _searchFocusNode.requestFocus();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                    await SettingsService().refreshDeletedCount();
                    await _loadNotes();
                  },
                ),
              ],
      ),
      body: _isSearching
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _searchQuery.isEmpty
                      ? Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildNotesPanel(searchResults),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedBottomTab == 0) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => setState(() => _selectedTab = 0),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 0,
                              ),
                              minimumSize: const Size(0, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Notes',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: _selectedTab == 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _selectedTab == 0
                                    ? activeAccentColor
                                    : inactiveColor,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () => setState(() => _selectedTab = 1),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 0,
                              ),
                              minimumSize: const Size(0, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Categories',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: _selectedTab == 1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _selectedTab == 1
                                    ? activeAccentColor
                                    : inactiveColor,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () => setState(() => _selectedTab = 2),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 0,
                              ),
                              minimumSize: const Size(0, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Completed',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: _selectedTab == 2
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _selectedTab == 2
                                    ? activeAccentColor
                                    : inactiveColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 16),
                ],
                Expanded(
                  child: IndexedStack(
                    index: _selectedBottomTab,
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_selectedTab == 0)
                              _buildNotesPanel(searchResults)
                            else if (_selectedTab == 1)
                              _buildCategoriesPanel(context)
                            else
                              _buildCompletedPanel(completedNotes),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInsightsPanel(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _isSearching
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _selectedBottomTab = 0),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(0, 52),
                        backgroundColor: Colors.transparent,
                      ),
                      icon: Icon(
                        Icons.home,
                        size: 20,
                        color: _selectedBottomTab == 0
                            ? activeAccentColor
                            : inactiveColor,
                      ),
                      label: Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 18,
                          color: _selectedBottomTab == 0
                              ? activeAccentColor
                              : inactiveColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _openAddTask,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: const Color(0xFFD8E2FF),
                      foregroundColor: const Color(0xFF2A2F5A),
                      elevation: 4,
                      shadowColor: const Color(0x803F51B5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      minimumSize: const Size(56, 56),
                    ),
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _selectedBottomTab = 1),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: const Size(0, 52),
                        backgroundColor: Colors.transparent,
                      ),
                      icon: Icon(
                        Icons.insights,
                        size: 20,
                        color: _selectedBottomTab == 1
                            ? activeAccentColor
                            : inactiveColor,
                      ),
                      label: Text(
                        'Insights',
                        style: TextStyle(
                          fontSize: 18,
                          color: _selectedBottomTab == 1
                              ? activeAccentColor
                              : inactiveColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNotesPanel(List<NoteItem> notes) {
    if (_isSearching && notes.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No search result',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: notes.isEmpty
          ? SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'No notes. Tap + to create a note.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: notes
                  .map(
                    (note) => GestureDetector(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => NoteDetailPage(note: note),
                          ),
                        );
                        await _loadNotes();
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
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
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildCategoriesPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 6,
                children:
                    [
                      _buildCategoryTile(
                        context,
                        Icons.person,
                        'Personal',
                        Colors.orange,
                      ),
                      _buildCategoryTile(
                        context,
                        Icons.work,
                        'Work',
                        Colors.purple,
                      ),
                      _buildCategoryTile(
                        context,
                        Icons.school,
                        'Study',
                        Colors.blue,
                      ),
                      _buildCategoryTile(
                        context,
                        Icons.health_and_safety,
                        'Health',
                        Colors.green,
                      ),
                      _buildCategoryTile(
                        context,
                        Icons.event,
                        'Events',
                        Colors.teal,
                      ),
                      _buildCategoryTile(
                        context,
                        Icons.more_horiz,
                        'Others',
                        Colors.grey,
                      ),
                    ].map((tile) {
                      return SizedBox(width: itemWidth, child: tile);
                    }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedPanel(List<NoteItem> completedNotes) {
    final sortedCompletedNotes = NoteItem.sortCompletedNotes(completedNotes);

    if (sortedCompletedNotes.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'No completed notes. Complete one to see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: sortedCompletedNotes.map((note) {
          return GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => NoteDetailPage(note: note)),
              );
              await _loadNotes();
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
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
        }).toList(),
      ),
    );
  }

  Widget _buildInsightsPanel() {
    final tasks = _notes
        .map(
          (note) => Task(
            id: note.title,
            title: note.title,
            description: note.description,
            isCompleted: note.status == 'Completed',
            dueDate: note.completedAt != null
                ? DateTime.tryParse(note.completedAt!)
                : null,
          ),
        )
        .toList();

    final totalTasks = tasks.length;
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final inProgressTasks = _notes
        .where((note) => note.status == 'In-Progress')
        .length;
    final pendingTasks = _notes
        .where((note) => note.status == 'Pending')
        .length;
    final completionRate = totalTasks == 0
        ? 0.0
        : (completedTasks / totalTasks) * 100;

    final stats = [
      {'label': 'Total Tasks', 'value': '$totalTasks'},
      {'label': 'Completed', 'value': '$completedTasks'},
      {'label': 'In Progress', 'value': '$inProgressTasks'},
      {'label': 'Pending', 'value': '$pendingTasks'},
      {
        'label': 'Completion Rate',
        'value': '${completionRate.toStringAsFixed(1)}%',
      },
    ];

    final productivityData = _buildProductivityData(tasks);
    final productivityValues = productivityData.values.toList();
    final maxProductivityValue = productivityValues.isEmpty
        ? 1
        : productivityValues.reduce((a, b) => a > b ? a : b);
    final chartLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final productivityStreak = _buildProductivityStreak(tasks);

    final weeklyCompletedTasks = productivityValues.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final mostProductiveEntry = productivityData.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    final positiveProductivityEntries = productivityData.entries
        .where((entry) => entry.value > 0)
        .toList();
    final leastProductiveEntry = positiveProductivityEntries.isNotEmpty
        ? positiveProductivityEntries.reduce(
            (a, b) => a.value <= b.value ? a : b,
          )
        : null;
    final averageTasksPerDay = weeklyCompletedTasks / 7;
    final mostProductiveText = weeklyCompletedTasks > 0
        ? '${_fullWeekdayLabel(mostProductiveEntry.key)} • ${mostProductiveEntry.value} ${mostProductiveEntry.value == 1 ? 'task completed' : 'tasks completed'}'
        : 'Not enough data this week';
    final leastProductiveText = leastProductiveEntry != null
        ? '${_fullWeekdayLabel(leastProductiveEntry.key)} • ${leastProductiveEntry.value} ${leastProductiveEntry.value == 1 ? 'task completed' : 'tasks completed'}'
        : 'Not enough data this week';
    final averageTasksText = weeklyCompletedTasks > 0
        ? '${averageTasksPerDay.toStringAsFixed(1)} tasks'
        : 'Not enough data this week';

    final categories = [
      'Personal',
      'Work',
      'Study',
      'Health',
      'Events',
      'Others',
    ];
    final categoryCounts = {
      for (final category in categories)
        category: _notes.where((note) => note.category == category).length,
    };
    final maxCategoryCount = categoryCounts.values.isEmpty
        ? 1
        : categoryCounts.values.reduce((a, b) => a > b ? a : b);

    final chartTextColor =
        Theme.of(context).textTheme.bodyMedium?.color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            children: [
              ...stats.asMap().entries.expand((entry) {
                final stat = entry.value;
                final widgets = <Widget>[
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      title: Text(stat['label']!),
                      trailing: Text(
                        stat['value']!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ];

                if (stat['label'] == 'Completion Rate') {
                  widgets.add(
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: const Text('Productivity Streak'),
                        trailing: Text(
                          '$productivityStreak ${productivityStreak == 1 ? 'day' : 'days'}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return widgets;
              }),
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Task Productivity',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color ??
                                    (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'See how productive you\'ve been each day',
                        style: TextStyle(
                          fontSize: 14,
                          color: chartTextColor,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 240,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: productivityValues.asMap().entries.map((
                            entry,
                          ) {
                            final index = entry.key;
                            final value = entry.value;
                            final barFillHeight =
                                (value > 0
                                        ? (160 * (value / maxProductivityValue))
                                              .clamp(12, 160)
                                        : 4.0)
                                    as double;
                            const barColor = Color(0xFF7C70EA);

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (value > 0)
                                  Text(
                                    value.toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: chartTextColor,
                                    ),
                                  )
                                else
                                  const SizedBox(height: 18),
                                const SizedBox(height: 6),
                                Container(
                                  width: 28,
                                  height: barFillHeight,
                                  decoration: BoxDecoration(
                                    color: barColor,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  chartLabels[index],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: chartTextColor,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Task Distribution',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color ??
                                    (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'See which categories keep you busiest',
                        style: TextStyle(
                          fontSize: 14,
                          color: chartTextColor,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 240,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: categoryCounts.entries.map((entry) {
                            final category = entry.key;
                            final count = entry.value;
                            final barFillHeight =
                                (count > 0
                                        ? (160 * (count / maxCategoryCount))
                                              .clamp(12, 160)
                                        : 4.0)
                                    as double;
                            const barColor = Color(0xFF7C70EA);

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (count > 0)
                                  Text(
                                    count.toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: chartTextColor,
                                    ),
                                  )
                                else
                                  const SizedBox(height: 18),
                                const SizedBox(height: 6),
                                Container(
                                  width: 28,
                                  height: barFillHeight,
                                  decoration: BoxDecoration(
                                    color: barColor,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: chartTextColor,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Highlights',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color ??
                                    (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildHighlightRow(
                        context,
                        Icons.emoji_events,
                        'Most Productive Day',
                        mostProductiveText,
                        chartTextColor,
                      ),
                      const SizedBox(height: 12),
                      _buildHighlightRow(
                        context,
                        Icons.trending_down,
                        'Least Productive Day',
                        leastProductiveText,
                        chartTextColor,
                      ),
                      const SizedBox(height: 12),
                      _buildHighlightRow(
                        context,
                        Icons.calculate,
                        'Average Tasks per Day',
                        averageTasksText,
                        chartTextColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _currentWeekStart() {
    final now = DateTime.now().toLocal();
    final mondayOffset = now.weekday - DateTime.monday;
    final monday = now.subtract(Duration(days: mondayOffset));
    return DateTime(monday.year, monday.month, monday.day);
  }

  int _buildProductivityStreak(List<Task> tasks) {
    final completedDays = tasks
        .where((task) => task.isCompleted && task.dueDate != null)
        .map((task) => task.dueDate!.toLocal())
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet();

    if (completedDays.isEmpty) {
      return 0;
    }

    var currentDay = completedDays.reduce((a, b) => a.isAfter(b) ? a : b);
    var streak = 0;

    while (completedDays.contains(currentDay)) {
      streak += 1;
      currentDay = currentDay.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Map<String, int> _buildProductivityData(List<Task> tasks) {
    final weekStart = _currentWeekStart();
    final currentWeekDates = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );

    final dayLabelByDate = {
      for (final date in currentWeekDates)
        DateTime(date.year, date.month, date.day): _weekdayLabel(date.weekday),
    };

    final counts = {
      for (final date in currentWeekDates) _weekdayLabel(date.weekday): 0,
    };

    for (final task in tasks) {
      if (!task.isCompleted || task.dueDate == null) continue;
      final completedDate = task.dueDate!.toLocal();
      final normalizedDate = DateTime(
        completedDate.year,
        completedDate.month,
        completedDate.day,
      );
      final label = dayLabelByDate[normalizedDate];
      if (label != null) {
        counts[label] = counts[label]! + 1;
      }
    }

    return counts;
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }

  String _fullWeekdayLabel(String shortLabel) {
    switch (shortLabel) {
      case 'Mon':
        return 'Monday';
      case 'Tue':
        return 'Tuesday';
      case 'Wed':
        return 'Wednesday';
      case 'Thu':
        return 'Thursday';
      case 'Fri':
        return 'Friday';
      case 'Sat':
        return 'Saturday';
      case 'Sun':
        return 'Sunday';
      default:
        return shortLabel;
    }
  }

  Widget _buildHighlightRow(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    Color valueColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 28, color: const Color(0xFF7C70EA)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      Theme.of(context).textTheme.bodyMedium?.color ??
                      (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black),
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 14, color: valueColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    final categoryNotes = _notes
        .where((note) => note.category == label)
        .toList();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDarkMode
        ? const Color(0xFFD8E2FF)
        : Colors.black.withValues(alpha: 0.85);
    final subtitleColor = isDarkMode
        ? Colors.grey.shade400
        : Colors.black.withValues(alpha: 0.6);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CategoryNotesPage(category: label),
              ),
            );
            await _loadNotes();
          },
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${categoryNotes.length} notes',
                    style: TextStyle(color: subtitleColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
