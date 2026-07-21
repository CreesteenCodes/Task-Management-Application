import 'dart:convert';

class NoteItem {
  static const List<String> statusOrder = [
    'Pending',
    'In-Progress',
    'Completed',
  ];

  final String title;
  final String dueDate;
  final String description;
  final String category;
  final String status;
  final String? completedAt;
  final String? deletedAt;
  final int? notificationId;

  const NoteItem({
    required this.title,
    required this.dueDate,
    this.description = '',
    this.category = 'Personal',
    this.status = 'Pending',
    this.completedAt,
    this.deletedAt,
    this.notificationId,
  });

  NoteItem copyWith({
    String? title,
    String? dueDate,
    String? description,
    String? category,
    String? status,
    String? completedAt,
    String? deletedAt,
    int? notificationId,
  }) {
    return NoteItem(
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'dueDate': dueDate,
      'description': description,
      'category': category,
      'status': status,
      'completedAt': completedAt,
      'deletedAt': deletedAt,
      'notificationId': notificationId,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static int _compareDueDates(NoteItem a, NoteItem b) {
    final aDate = parseDueDate(a.dueDate);
    final bDate = parseDueDate(b.dueDate);

    if (aDate != null && bDate != null) {
      final dateComparison = aDate.compareTo(bDate);
      if (dateComparison != 0) {
        return dateComparison;
      }
    } else if (aDate != null && bDate == null) {
      return -1;
    } else if (aDate == null && bDate != null) {
      return 1;
    }

    final titleComparison = a.title.toLowerCase().compareTo(
      b.title.toLowerCase(),
    );
    if (titleComparison != 0) {
      return titleComparison;
    }

    return a.dueDate.toLowerCase().compareTo(b.dueDate.toLowerCase());
  }

  static List<NoteItem> sortNotes(List<NoteItem> notes) {
    final sortedNotes = List<NoteItem>.from(notes);
    sortedNotes.sort(_compareDueDates);
    return sortedNotes;
  }

  static List<NoteItem> sortCompletedNotes(List<NoteItem> notes) {
    final sortedNotes = List<NoteItem>.from(notes);
    sortedNotes.sort((a, b) {
      final aDate = a.completedAt != null
          ? DateTime.tryParse(a.completedAt!)
          : null;
      final bDate = b.completedAt != null
          ? DateTime.tryParse(b.completedAt!)
          : null;

      if (aDate != null && bDate != null) {
        return bDate.compareTo(aDate);
      }
      if (aDate != null && bDate == null) {
        return -1;
      }
      if (aDate == null && bDate != null) {
        return 1;
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return sortedNotes;
  }

  static List<NoteItem> sortDeletedNotes(List<NoteItem> notes) {
    final sortedNotes = List<NoteItem>.from(notes);
    sortedNotes.sort((a, b) {
      final aDate = a.deletedAt != null
          ? DateTime.tryParse(a.deletedAt!)
          : null;
      final bDate = b.deletedAt != null
          ? DateTime.tryParse(b.deletedAt!)
          : null;

      if (aDate != null && bDate != null) {
        return bDate.compareTo(aDate);
      }
      if (aDate != null && bDate == null) {
        return -1;
      }
      if (aDate == null && bDate != null) {
        return 1;
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return sortedNotes;
  }

  bool matchesQuery(String query) {
    if (query.trim().isEmpty) {
      return true;
    }

    final lowerQuery = query.toLowerCase().trim();
    return title.toLowerCase().contains(lowerQuery);
  }

  static DateTime? parseDueDate(String dueDate) {
    final trimmedDueDate = dueDate.trim();
    if (trimmedDueDate.isEmpty) {
      return null;
    }

    final match = RegExp(
      r'^(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{1,2}),\s*(\d{4})$',
    ).firstMatch(trimmedDueDate);

    if (match == null) {
      return null;
    }

    final month = _monthNumber(match.group(1)!);
    final day = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);

    return DateTime(year, month, day);
  }

  static int _monthNumber(String monthName) {
    switch (monthName.toLowerCase()) {
      case 'january':
        return 1;
      case 'february':
        return 2;
      case 'march':
        return 3;
      case 'april':
        return 4;
      case 'may':
        return 5;
      case 'june':
        return 6;
      case 'july':
        return 7;
      case 'august':
        return 8;
      case 'september':
        return 9;
      case 'october':
        return 10;
      case 'november':
        return 11;
      default:
        return 12;
    }
  }

  static List<String> allowedStatuses(String currentStatus) {
    final currentIndex = statusOrder.indexOf(currentStatus);
    if (currentIndex < 0) {
      return statusOrder;
    }
    return statusOrder.sublist(currentIndex);
  }

  static DateTime minimumValidDueDate({DateTime? now}) {
    final baseDate = (now ?? DateTime.now()).toLocal();
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
    ).add(const Duration(days: 1));
  }

  static bool isValidDueDate(DateTime? dueDate, {DateTime? now}) {
    if (dueDate == null) {
      return false;
    }

    final normalizedDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final minimumDate = minimumValidDueDate(now: now);
    return normalizedDate.isAtSameMomentAs(minimumDate) ||
        normalizedDate.isAfter(minimumDate);
  }

  static bool canTransitionTo(String currentStatus, String nextStatus) {
    final allowed = allowedStatuses(currentStatus);
    return allowed.contains(nextStatus);
  }

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      title: json['title'] as String? ?? '',
      dueDate: json['dueDate'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Personal',
      status: json['status'] as String? ?? 'Pending',
      completedAt: json['completedAt'] as String?,
      deletedAt: json['deletedAt'] as String?,
      notificationId: json['notificationId'] as int?,
    );
  }

  factory NoteItem.fromJsonString(String jsonString) {
    return NoteItem.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
