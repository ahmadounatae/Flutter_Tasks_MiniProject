// lib/controllers/task_controller.dart
// Contrôleur gérant toutes les opérations CRUD sur les tâches

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../utils/database_helper.dart';
import 'auth_controller.dart';

class TaskController extends ChangeNotifier {
  static final TaskController _instance = TaskController._internal();
  factory TaskController() => _instance;
  TaskController._internal();

  final DatabaseHelper _db = DatabaseHelper();
  final AuthController _auth = AuthController();
  final Uuid _uuid = const Uuid();

  List<Task> _tasks = [];
  List<Task> get tasks => _tasks;

  String _selectedCategory = 'Toutes';
  String get selectedCategory => _selectedCategory;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Catégories disponibles
  static const List<String> categories = [
    'Toutes',
    'Général',
    'Travail',
    'Personnel',
    'Santé',
    'Shopping',
    'Études',
  ];

  // Tâches filtrées selon catégorie et recherche
  List<Task> get filteredTasks {
    return _tasks.where((task) {
      final matchesCategory =
          _selectedCategory == 'Toutes' || task.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<Task> get completedTasks =>
      _tasks.where((t) => t.isCompleted).toList();
  List<Task> get pendingTasks =>
      _tasks.where((t) => !t.isCompleted).toList();

  // Charger les tâches de l'utilisateur connecté
  Future<void> loadTasks() async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    _tasks = await _db.getTasksByUser(userId);

    _isLoading = false;
    notifyListeners();
  }

  // Créer une nouvelle tâche
  Future<void> addTask({
    required String title,
    String description = '',
    String category = 'Général',
    int priority = 1,
    DateTime? dueDate,
  }) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return;

    final task = Task(
      id: _uuid.v4(),
      title: title.trim(),
      description: description.trim(),
      category: category,
      priority: priority,
      createdAt: DateTime.now(),
      dueDate: dueDate,
    );

    await _db.insertTask(task, userId);
    _tasks.insert(0, task);
    notifyListeners();
  }

  // Mettre à jour une tâche
  Future<void> updateTask(Task task) async {
    await _db.updateTask(task);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
    }
  }

  // Supprimer une tâche
  Future<void> deleteTask(String id) async {
    await _db.deleteTask(id);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // Basculer l'état complété/non-complété
  Future<void> toggleTaskComplete(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final task = _tasks[index].copyWith(
      isCompleted: !_tasks[index].isCompleted,
    );
    _tasks[index] = task;
    await _db.updateTask(task);
    notifyListeners();
  }

  // Changer le filtre de catégorie
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Mettre à jour la recherche
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Obtenir les statistiques
  Future<Map<String, int>> getStats() async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return {'total': 0, 'completed': 0, 'pending': 0};
    return await _db.getTaskStats(userId);
  }

  // Réinitialiser l'état (lors de la déconnexion)
  void reset() {
    _tasks = [];
    _selectedCategory = 'Toutes';
    _searchQuery = '';
    notifyListeners();
  }
}
