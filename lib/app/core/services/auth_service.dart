import 'package:dio/dio.dart';

import '../network/dio_client.dart';
import '../network/api_endpoints.dart';

class AuthService {
  final Dio dio = DioClient.dio;

  Future<Response> login({
    required String email,
    required String password,
  }) async {
    return await dio.post(
      ApiEndpoints.login,
      data: {
        "email": email,
        "password": password,
      },
    );
  }
}