import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    // Jika dijalankan di Windows desktop:
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return 'http://localhost:8080';
    }
    // Jika dijalankan di Android Emulator:
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    // Default fallback
    return 'http://10.0.2.2:8080';
  }

  final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient({String? baseUrl})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? defaultBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        )) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final accessToken = await _storage.read(key: 'access_token');
            if (accessToken != null && accessToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $accessToken';
            }
          } catch (_) {}
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshToken = await _storage.read(key: 'refresh_token');
            if (refreshToken != null) {
              try {
                final refreshResponse = await Dio(BaseOptions(baseUrl: dio.options.baseUrl)).post(
                  '/auth/refresh',
                  data: {'refresh_token': refreshToken},
                );

                if (refreshResponse.statusCode == 200 && refreshResponse.data['success'] == true) {
                  final newAccess = refreshResponse.data['data']['access_token'];
                  final newRefresh = refreshResponse.data['data']['refresh_token'];
                  await _storage.write(key: 'access_token', value: newAccess);
                  await _storage.write(key: 'refresh_token', value: newRefresh);

                  // Retry the original request
                  final opts = error.requestOptions;
                  opts.headers['Authorization'] = 'Bearer $newAccess';
                  final cloneReq = await dio.request(
                    opts.path,
                    options: Options(method: opts.method, headers: opts.headers),
                    data: opts.data,
                    queryParameters: opts.queryParameters,
                  );
                  return handler.resolve(cloneReq);
                }
              } catch (_) {
                await _storage.deleteAll();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  Future<String?> getAccessToken() => _storage.read(key: 'access_token');
}
