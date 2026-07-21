import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tazk_application/models/note_item.dart';
import 'package:tazk_application/services/settings_service.dart';
import 'package:tazk_application/services/notification_service.dart';
import 'recently_deleted.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settings = SettingsService();
  static const List<String> _scheduleOptions = [
    '3 days before the due date',
    '2 days before the due date',
    '1 day before the due date',
    'On the due date',
  ];

  String _formatTime(BuildContext context, TimeOfDay time) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(time, alwaysUse24HourFormat: false);
  }

  Color _getPickerTextColor(BuildContext context, {required bool isSelected}) {
    if (isSelected) {
      return Theme.of(context).colorScheme.primary;
    }
    return CupertinoColors.systemGrey2.resolveFrom(context);
  }

  Future<void> _resyncStoredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNotes = prefs.getStringList('notes') ?? [];
    final loadedNotes = savedNotes
        .map((jsonString) => NoteItem.fromJsonString(jsonString))
        .toList();
    final syncedNotes = await NotificationService().syncNotificationsForNotes(
      loadedNotes,
    );
    await prefs.setStringList(
      'notes',
      syncedNotes.map((note) => note.toJsonString()).toList(),
    );
  }

  Future<void> _pickNotificationTime() async {
    final initialTime = _settings.notificationTime.value;
    int selectedHour = initialTime.hourOfPeriod == 0 ? 12 : initialTime.hourOfPeriod;
    int selectedMinute = initialTime.minute;
    int selectedPeriod = initialTime.period == DayPeriod.am ? 0 : 1;
    final hourController = FixedExtentScrollController(initialItem: selectedHour - 1);
    final minuteController = FixedExtentScrollController(initialItem: selectedMinute);
    final periodController = FixedExtentScrollController(initialItem: selectedPeriod);

    try {
      final picked = await showCupertinoModalPopup<TimeOfDay>(
        context: context,
        builder: (context) {
          return _buildBottomPopupCard(
            context,
            height: 300,
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              final hour24 = selectedPeriod == 0
                                  ? (selectedHour == 12 ? 0 : selectedHour)
                                  : (selectedHour == 12 ? 12 : selectedHour + 12);
                              await _settings.setNotificationsEnabled(true);
                                if (!context.mounted) {
                                  return;
                                }
                              Navigator.of(context).pop(
                                TimeOfDay(hour: hour24, minute: selectedMinute),
                              );
                            },
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final horizontalGap = (constraints.maxWidth * 0.015)
                              .clamp(3.0, 5.0)
                              .toDouble();

                          return Row(
                            children: [
                              Expanded(
                                child: CupertinoPicker(
                                  backgroundColor: Colors.transparent,
                                  selectionOverlay: const SizedBox.shrink(),
                                  itemExtent: 44,
                                  diameterRatio: 1.1,
                                  squeeze: 1.0,
                                  useMagnifier: true,
                                  magnification: 1.02,
                                  scrollController: hourController,
                                  onSelectedItemChanged: (index) {
                                    setModalState(() {
                                      selectedHour = index + 1;
                                    });
                                  },
                                  children: List.generate(12, (index) {
                                    final value = index + 1;
                                    final isSelected = value == selectedHour;
                                    return _timePickerWheelItem(
                                      context,
                                      label: value.toString(),
                                      suffix: isSelected ? 'H' : null,
                                      isSelected: isSelected,
                                    );
                                  }),
                                ),
                              ),
                              SizedBox(width: horizontalGap),
                              Expanded(
                                child: CupertinoPicker(
                                  backgroundColor: Colors.transparent,
                                  selectionOverlay: const SizedBox.shrink(),
                                  itemExtent: 44,
                                  diameterRatio: 1.1,
                                  squeeze: 1.0,
                                  useMagnifier: true,
                                  magnification: 1.02,
                                  scrollController: minuteController,
                                  onSelectedItemChanged: (index) {
                                    setModalState(() {
                                      selectedMinute = index;
                                    });
                                  },
                                  children: List.generate(60, (index) {
                                    final isSelected = index == selectedMinute;
                                    return _timePickerWheelItem(
                                      context,
                                      label: index.toString().padLeft(2, '0'),
                                      suffix: isSelected ? 'M' : null,
                                      isSelected: isSelected,
                                    );
                                  }),
                                ),
                              ),
                              SizedBox(width: horizontalGap),
                              Expanded(
                                child: CupertinoPicker(
                                  backgroundColor: Colors.transparent,
                                  selectionOverlay: const SizedBox.shrink(),
                                  itemExtent: 44,
                                  diameterRatio: 1.1,
                                  squeeze: 1.0,
                                  useMagnifier: true,
                                  magnification: 1.02,
                                  scrollController: periodController,
                                  onSelectedItemChanged: (index) {
                                    setModalState(() {
                                      selectedPeriod = index;
                                    });
                                  },
                                  children: List.generate(2, (index) {
                                    final isSelected = index == selectedPeriod;
                                    return _timePickerWheelItem(
                                      context,
                                      label: index == 0 ? 'AM' : 'PM',
                                      isSelected: isSelected,
                                    );
                                  }),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );

      if (picked != null) {
        await _settings.setNotificationTime(picked);
        await _resyncStoredNotifications();
      }
    } finally {
      hourController.dispose();
      minuteController.dispose();
      periodController.dispose();
    }
  }

  Future<void> _pickNotificationSchedule() async {
    final selectedValue = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) {
        var currentSelection = _settings.notificationSchedule.value;
        final initialIndex = _scheduleOptions.indexOf(currentSelection);
        final scheduleController = FixedExtentScrollController(
          initialItem: initialIndex < 0 ? 0 : initialIndex,
        );

        return _buildBottomPopupCard(
          context,
          height: 300,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            scheduleController.dispose();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            scheduleController.dispose();
                            Navigator.of(context).pop(currentSelection);
                          },
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoPicker(
                      backgroundColor: Colors.transparent,
                      selectionOverlay: const SizedBox.shrink(),
                      itemExtent: 44,
                      diameterRatio: 1.12,
                      squeeze: 1.0,
                      useMagnifier: true,
                      magnification: 1.02,
                      scrollController: scheduleController,
                      onSelectedItemChanged: (index) {
                        setModalState(() {
                          currentSelection = _scheduleOptions[index];
                        });
                      },
                      children: _scheduleOptions.map((option) {
                        final isSelected = option == currentSelection;
                        final textColor = _getPickerTextColor(context, isSelected: isSelected);

                        return Center(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: textColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (selectedValue != null) {
      await _settings.setNotificationSchedule(selectedValue);
      await _resyncStoredNotifications();
    }
  }

  Widget _timePickerWheelItem(
    BuildContext context, {
    required String label,
    String? suffix,
    required bool isSelected,
  }) {
    final textColor = _getPickerTextColor(context, isSelected: isSelected);

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: label.length > 2 ? 24 : 29,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
          ),
          if (suffix != null) ...[
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                suffix,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomPopupCard(
    BuildContext context, {
    required Widget child,
    required double height,
  }) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            elevation: 16,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: double.infinity,
              height: height,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _setNotificationsEnabled(bool value) async {
    await _settings.setNotificationsEnabled(value);
    await _resyncStoredNotifications();
  }

  @override
  void initState() {
    super.initState();
    _settings.deletedCount.addListener(_onDeletedCountChanged);
  }

  @override
  void dispose() {
    _settings.deletedCount.removeListener(_onDeletedCountChanged);
    super.dispose();
  }

  void _onDeletedCountChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Preference',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Divider(height: 1, thickness: 1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text('Theme', style: TextStyle(fontSize: 18)),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _settings.isDark,
                  builder: (context, value, child) => Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: value,
                      onChanged: (v) => _settings.setDark(v),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text('Eye Comfort Shield', style: TextStyle(fontSize: 18)),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _settings.eyeComfort,
                  builder: (context, value, child) => Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: value,
                      onChanged: (v) => _settings.setEyeComfort(v),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Divider(height: 1, thickness: 1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text('Enable', style: TextStyle(fontSize: 18)),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _settings.notificationsEnabled,
                  builder: (context, value, child) => Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: value,
                      onChanged: _setNotificationsEnabled,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<bool>(
              valueListenable: _settings.notificationsEnabled,
              builder: (context, enabled, child) => InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: enabled ? _pickNotificationTime : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Time', style: TextStyle(fontSize: 18)),
                      ),
                      ValueListenableBuilder<TimeOfDay>(
                        valueListenable: _settings.notificationTime,
                        builder: (context, value, child) {
                          final textColor = enabled
                              ? Theme.of(context).textTheme.bodyMedium?.color
                              : Colors.grey;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              _formatTime(context, value),
                              style: TextStyle(color: textColor),
                            ),
                          );
                        },
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: enabled ? Colors.grey.shade500 : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<bool>(
              valueListenable: _settings.notificationsEnabled,
              builder: (context, enabled, child) => InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: enabled ? _pickNotificationSchedule : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Schedule', style: TextStyle(fontSize: 18)),
                      ),
                      ValueListenableBuilder<String>(
                        valueListenable: _settings.notificationSchedule,
                        builder: (context, value, child) => Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            value,
                            style: TextStyle(
                              color: enabled
                                  ? Theme.of(context).textTheme.bodyMedium?.color
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: enabled ? Colors.grey.shade500 : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RecentlyDeletedScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Recently Deleted', style: TextStyle(fontSize: 18)),
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: _settings.deletedCount,
                      builder: (context, value, child) => Row(
                        children: [
                          Text(
                            '$value',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
