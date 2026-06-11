// lib/utils/database_helper.dart
// Gestionnaire de la base de données SQLite locale

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'taskapp.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Table des utilisateurs
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        passwordHash TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Table des tâches
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT,
        priority INTEGER DEFAULT 1,
        isCompleted INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        dueDate TEXT,
        userId TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users(id)
      )
    ''');
  }

  // ─── CRUD Utilisateurs ───────────────────────────────────────────────────

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps =
        await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> getUserById(String id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  // ─── CRUD Tâches ─────────────────────────────────────────────────────────

  Future<int> insertTask(Task task, String userId) async {
    final db = await database;
    final map = task.toMap();
    map['userId'] = userId;
    return await db.insert('tasks', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Task>> getTasksByUser(String userId) async {
    final db = await database;
    final maps = await db.query('tasks',
        where: 'userId = ?', whereArgs: [userId], orderBy: 'createdAt DESC');
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db
        .update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<int> deleteTask(String id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> getTaskStats(String userId) async {
    final db = await database;
    final all = await db
        .query('tasks', where: 'userId = ?', whereArgs: [userId]);
    final completed = all.where((t) => t['isCompleted'] == 1).length;
    return {
      'total': all.length,
      'completed': completed,
      'pending': all.length - completed,
    };
  }
}
