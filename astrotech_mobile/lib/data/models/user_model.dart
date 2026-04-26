import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.fullName,
    super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
    };
  }
}

class TechnicianModel extends Technician {
  const TechnicianModel({
    required super.id,
    required super.nom,
    required super.prenom,
    super.telephone,
    super.email,
    super.specialite,
    super.statut,
  });

  factory TechnicianModel.fromJson(Map<String, dynamic> json) {
    return TechnicianModel(
      id: json['id'] as int,
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
      specialite: json['specialite'] as String?,
      statut: json['statut'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'email': email,
      'specialite': specialite,
      'statut': statut,
    };
  }
}

class AuthResultModel extends AuthResult {
  const AuthResultModel({
    required super.token,
    required super.user,
    super.technician,
  });

  factory AuthResultModel.fromJson(Map<String, dynamic> json, String token) {
    return AuthResultModel(
      token: token,
      user: UserModel.fromJson(json['user'] ?? json),
      technician: json['technician'] != null
          ? TechnicianModel.fromJson(json['technician'])
          : null,
    );
  }
}
