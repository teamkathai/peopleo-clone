import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_endpoints.dart';
import 'api_client.dart';

class ExpenseService {
  final _api = ApiClient.instance;

  /// POST /add-expenses (multipart) { client_id, amount, date, remark, image }
  Future<Map<String, dynamic>> addExpense({
    required String clientId,
    required String amount,
    required String date,
    required String remark,
    File? receipt,
  }) async {
    final form = FormData.fromMap({
      'client_id': clientId,
      'amount': amount,
      'date': date,
      'remark': remark,
      if (receipt != null)
        'image': await MultipartFile.fromFile(receipt.path, filename: 'receipt.jpg'),
    });
    final res = await _api.postForm(Endpoints.addExpenses, form);
    return res.data as Map<String, dynamic>;
  }
}
