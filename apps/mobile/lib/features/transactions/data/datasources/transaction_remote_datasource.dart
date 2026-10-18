import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/normalized_transaction.dart';
import 'package:autobank_mobile/core/config/app_config.dart';

class TransactionRemoteDataSource {
  final String baseUrl;

  TransactionRemoteDataSource({
    String? customBaseUrl,
  }) : baseUrl = customBaseUrl ?? AppConfig.apiBaseUrl;

  /// Đồng bộ giao dịch lên NestJS API (kèm theo email tài khoản của người dùng)
  Future<bool> syncTransaction(
    NormalizedTransaction transaction, {
    String? userEmail,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/transactions');
      final cleanEmail = (userEmail ?? '').trim().toLowerCase();
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bankCode': transaction.bankCode,
          'accountNumber': transaction.accountNumber,
          'amount': transaction.amount,
          'type': transaction.type.name,
          'content': transaction.content,
          'orderCode': transaction.orderCode,
          'transactionTime': transaction.transactionTime.toIso8601String(),
          'rawContent': transaction.rawContent,
          'fingerprint': transaction.fingerprint,
          'userEmail': cleanEmail.isNotEmpty ? cleanEmail : null,
          'category': transaction.category,
          'note': transaction.note,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Đồng bộ giao dịch lên Server thành công (User: $cleanEmail): ${transaction.fingerprint}');
        return true;
      } else {
        debugPrint('Lỗi server khi đồng bộ: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Không thể kết nối đến server để đồng bộ (App vẫn hoạt động offline): $e');
      return false;
    }
  }

  /// Tải toàn bộ giao dịch đã lưu trên MySQL theo tài khoản (Google email)
  Future<List<NormalizedTransaction>> fetchTransactionsByUser(String userEmail) async {
    final cleanEmail = userEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty) return [];

    try {
      final url = Uri.parse('$baseUrl/transactions?userEmail=${Uri.encodeComponent(cleanEmail)}&limit=200');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map<NormalizedTransaction>((item) {
            return NormalizedTransaction.fromJson(item as Map<String, dynamic>);
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải giao dịch của tài khoản từ server: $e');
    }
    return [];
  }

  /// Xóa giao dịch theo ID hoặc Fingerprint trên MySQL server
  Future<bool> deleteTransaction(String idOrFingerprint, {String? userEmail}) async {
    final cleanId = idOrFingerprint.trim();
    if (cleanId.isEmpty) return false;
    try {
      final cleanEmail = (userEmail ?? '').trim().toLowerCase();
      var urlStr = '$baseUrl/transactions/${Uri.encodeComponent(cleanId)}';
      if (cleanEmail.isNotEmpty) {
        urlStr += '?userEmail=${Uri.encodeComponent(cleanEmail)}';
      }
      final response = await http.delete(Uri.parse(urlStr)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('Đã xóa giao dịch trên Server thành công: $cleanId');
        return true;
      }
    } catch (e) {
      debugPrint('Lỗi xóa giao dịch trên server: $e');
    }
    return false;
  }

  /// Xóa toàn bộ giao dịch của tài khoản trên MySQL server
  Future<bool> clearAllTransactions(String userEmail) async {
    final cleanEmail = userEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty) return false;
    try {
      final url = Uri.parse('$baseUrl/transactions?userEmail=${Uri.encodeComponent(cleanEmail)}');
      final response = await http.delete(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('Đã xóa toàn bộ lịch sử giao dịch trên Server cho user: $cleanEmail');
        return true;
      }
    } catch (e) {
      debugPrint('Lỗi xóa toàn bộ giao dịch trên server: $e');
    }
    return false;
  }
}
