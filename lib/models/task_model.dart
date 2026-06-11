// lib/models/task_model.dart
// Modèle représentant une tâche dans l'application

class Task {
  final String id;
  String title;
  String description;
  String category;
  int priority; // 1 = Basse, 2 = Moyenne, 3 = Haute
  bool isCompleted;
  DateTime createdAt;
  DateTime? dueDate;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'Général',
    this.priority = 1,
    this.isCompleted = false,
    required this.createdAt,
    this.dueDate,
  });

  // Convertir un objet Task en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  // Créer un objet Task depuis une Map SQLite
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      category: map['category'] ?? 'Général',
      priority: map['priority'] ?? 1,
      isCompleted: map['isCompleted'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
    );
  }

  // Copier un Task avec des modifications
  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    int? priority,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? dueDate,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  String get priorityLabel {
    switch (priority) {
      case 3:
        return 'Haute';
      case 2:
        return 'Moyenne';
      default:
        return 'Basse';
    }
  }
}
