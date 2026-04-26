import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String email;
  final String? fullName;
  final String? role;

  const User({
    required this.id,
    required this.email,
    this.fullName,
    this.role,
  });

  @override
  List<Object?> get props => [id, email, fullName, role];
}

class Technician extends Equatable {
  final int id;
  final String nom;
  final String prenom;
  final String? telephone;
  final String? email;
  final String? specialite;
  final String? statut;

  const Technician({
    required this.id,
    required this.nom,
    required this.prenom,
    this.telephone,
    this.email,
    this.specialite,
    this.statut,
  });

  String get fullName => '$prenom $nom';

  @override
  List<Object?> get props => [id, nom, prenom, email];
}

class AuthResult extends Equatable {
  final String token;
  final User user;
  final Technician? technician;

  const AuthResult({
    required this.token,
    required this.user,
    this.technician,
  });

  @override
  List<Object?> get props => [token, user, technician];
}
