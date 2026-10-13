import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/normalized_transaction.dart';

class TransactionRemoteDataSource {
  // 10.0.2.2 là localhost trên Android Emulator, localhost cho Windows Desktop
  final String baseUrl;

  TransactionRemoteDataSource({
    String? customBaseUrl,
  }) : baseUrl = customBaseUrl ?? (defaultTargetPlatform == TargetPlatform.android ? 'http://10.0.2.2:3000' : 'http://localhost:3000');

  /// Đồng bộ giao dịch lên NestJS API
  Future<bool> syncTransaction(NormalizedTransaction transaction) async {
    try {
      final url = Uri.parse('$baseUrl/transactions');
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
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Đồng bộ giao dịch lên Server thành công: ${transaction.fingerprint}');
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
}
