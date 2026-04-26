import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/api_constants.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource;
  final FlutterSecureStorage secureStorage;

  AuthRepositoryImpl({
    required this.remoteDatasource,
    required this.secureStorage,
  });

  @override
  Future<AuthResult> login(String email, String password) async {
    final result = await remoteDatasource.login(email, password);

    // Store user data locally
    await secureStorage.write(
      key: ApiConstants.userKey,
      value: jsonEncode((result.user as UserModel).toJson()),
    );

    if (result.technician != null) {
      await secureStorage.write(
        key: ApiConstants.technicianKey,
        value: jsonEncode((result.technician as TechnicianModel).toJson()),
      );
    }

    return result;
  }

  @override
  Future<void> logout() async {
    await remoteDatasource.logout();
    await secureStorage.delete(key: ApiConstants.tokenKey);
    await secureStorage.delete(key: ApiConstants.userKey);
    await secureStorage.delete(key: ApiConstants.technicianKey);
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await secureStorage.read(key: ApiConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<User?> getCurrentUser() async {
    final userData = await secureStorage.read(key: ApiConstants.userKey);
    if (userData != null) {
      return UserModel.fromJson(jsonDecode(userData));
    }
    return null;
  }

  @override
  Future<Technician?> getCurrentTechnician() async {
    final techData = await secureStorage.read(key: ApiConstants.technicianKey);
    if (techData != null) {
      return TechnicianModel.fromJson(jsonDecode(techData));
    }
    return null;
  }
}
