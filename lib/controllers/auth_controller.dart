// lib/controllers/auth_controller.dart
// Contrôleur gérant l'authentification (login/register/logout)

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../utils/database_helper.dart';

class AuthController {
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;
  AuthController._internal();

  final DatabaseHelper _db = DatabaseHelper();
  final Uuid _uuid = const Uuid();

  User? _currentUser;
  User? get currentUser => _currentUser;

  // Hasher le mot de passe avec SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // Enregistrement d'un nouvel utilisateur
  Future<String?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    // Vérification si l'email existe déjà
    final existing = await _db.getUserByEmail(email.toLowerCase().trim());
    if (existing != null) {
      return 'Un compte avec cet email existe déjà.';
    }

    final user = User(
      id: _uuid.v4(),
      username: username.trim(),
      email: email.toLowerCase().trim(),
      passwordHash: _hashPassword(password),
      createdAt: DateTime.now(),
    );

    await _db.insertUser(user);
    _currentUser = user;
    await _saveSession(user.id);
    return null; // null = succès
  }

  // Connexion d'un utilisateur
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final user = await _db.getUserByEmail(email.toLowerCase().trim());
    if (user == null) {
      return 'Aucun compte trouvé avec cet email.';
    }

    if (user.passwordHash != _hashPassword(password)) {
      return 'Mot de passe incorrect.';
    }

    _currentUser = user;
    await _saveSession(user.id);
    return null; // null = succès
  }

  // Déconnexion
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }

  // Sauvegarder la session
  Future<void> _saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  // Restaurer la session au démarrage
  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return false;

    final user = await _db.getUserById(userId);
    if (user == null) return false;

    _currentUser = user;
    return true;
  }

  // Validation de l'email
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validation du mot de passe
  bool isValidPassword(String password) {
    return password.length >= 6;
  }
}
