// lib/models/user_model.dart
// Modèle représentant un utilisateur

class User {
  final String id;
  String username;
  String email;
  String passwordHash;
  DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'passwordHash': passwordHash,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      passwordHash: map['passwordHash'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
