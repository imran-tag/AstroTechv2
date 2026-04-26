import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/user_model.dart';

class AuthRemoteDatasource {
  final ApiClient _apiClient;

  AuthRemoteDatasource(this._apiClient);

  Future<AuthResultModel> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data;
    final token = data['token'] as String;

    // Store token for future requests
    await _apiClient.setToken(token);

    return AuthResultModel.fromJson(data, token);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiClient.get(ApiConstants.mobileProfile);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _apiClient.clearToken();
  }
}
