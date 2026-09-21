import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String;
        await _apiClient.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        return {
          'success': true,
          'user': data['user'],
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Pendaftaran gagal',
      };
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? 'Gagal menghubungi server: ${e.message}';
      return {'success': false, 'message': errorMsg};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String;
        await _apiClient.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        return {
          'success': true,
          'user': data['user'],
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Login gagal',
      };
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? 'Email atau kata sandi salah / server offline';
      return {'success': false, 'message': errorMsg};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> logout() async {
    await _apiClient.clearTokens();
  }

  Future<bool> isLoggedIn() async {
    final token = await _apiClient.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get('/auth/me');
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
