class Task {
  String id;
  String title;
  String description;
  bool isCompleted;
  DateTime? dueDate;
  DateTime? deletedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.dueDate,
    this.deletedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'dueDate': dueDate?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      isCompleted: json['isCompleted'],
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'])
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'])
          : null,
    );
  }
}