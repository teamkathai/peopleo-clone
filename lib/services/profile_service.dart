import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_endpoints.dart';
import 'api_client.dart';

class ProfileService {
  final _api = ApiClient.instance;

  Future<dynamic> detailsByToken() async =>
      (await _api.get(Endpoints.employeeDetailsByToken)).data;

  Future<dynamic> personalDetails() async =>
      (await _api.get(Endpoints.employeePersonalDetails)).data;

  Future<Map<String, dynamic>> updatePersonal(Map<String, dynamic> fields) async {
    final res = await _api.post(Endpoints.employeePersonalDetailsUpdate, data: fields);
    return res.data as Map<String, dynamic>;
  }

  /// POST /employee-photo-update (multipart) { image }
  Future<Map<String, dynamic>> updatePhoto(File photo) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(photo.path, filename: 'profile.jpg'),
    });
    final res = await _api.postForm(Endpoints.employeePhotoUpdate, form);
    return res.data as Map<String, dynamic>;
  }
}
