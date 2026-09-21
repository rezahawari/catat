import '../../../core/network/api_client.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<List<Map<String, dynamic>>> getSpaces() async {
    try {
      final res = await _apiClient.dio.get('/spaces');
      if (res.data['success'] == true) {
        final List list = res.data['data'] ?? [];
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAccounts(String spaceId) async {
    try {
      final res = await _apiClient.dio.get('/spaces/$spaceId/accounts');
      if (res.data['success'] == true) {
        final List list = res.data['data'] ?? [];
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCategories(String spaceId) async {
    try {
      final res = await _apiClient.dio.get('/spaces/$spaceId/categories');
      if (res.data['success'] == true) {
        final List list = res.data['data'] ?? [];
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTransactions(String spaceId) async {
    try {
      final res = await _apiClient.dio.get('/spaces/$spaceId/transactions');
      if (res.data['success'] == true) {
        final List list = res.data['data'] ?? [];
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getSummary(String spaceId) async {
    try {
      final res = await _apiClient.dio.get('/spaces/$spaceId/transactions/summary');
      if (res.data['success'] == true) {
        return Map<String, dynamic>.from(res.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> createTransaction({
    required String spaceId,
    String? accountId,
    String? categoryId,
    required double amount,
    required String type,
    String? note,
    required String transactionDate,
  }) async {
    try {
      final res = await _apiClient.dio.post(
        '/spaces/$spaceId/transactions',
        data: {
          if (accountId != null) 'account_id': accountId,
          if (categoryId != null) 'category_id': categoryId,
          'amount': amount,
          'type': type,
          'note': note,
          'transaction_date': transactionDate,
        },
      );
      return res.data['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
