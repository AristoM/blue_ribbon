import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late Dio _dio;
  static const String baseUrl = 'http://10.250.70.138:8080/api/v1';

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));

    _dio.interceptors.add(LoggingInterceptor());
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  Future<Response> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['success']) {
        final token = response.data['data']['access_token'];
        if (token != null) {
          await _saveToken(token);
        }
      }
      return response;
    } on DioException {
      rethrow;
    }
  }

  Future<Response> logout(String refreshToken) async {
    // Mocking the API call locally for now as no endpoint was provided
    await Future.delayed(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');

    return Response(
      requestOptions: RequestOptions(path: '/admin/auth/logout'),
      statusCode: 200,
      data: {
        "success": true,
        "message": "Logged out successfully",
      },
    );
  }

  Future<Response> getUpcomingOrders() async {
    return await _dio.get('/technician/my-jobs');
  }

  Future<Response> getOrderDetails(String orderId) async {
    return await _dio.get('/orders/$orderId');
  }

  Future<Response> sendChatMessage(
      String message, String conversationId) async {
    try {
      return await _dio.post('/chat/job/JOB-2026-5678', data: {
        'message': message,
        'conversation_id': conversationId,
      });
    } catch (e) {
      // Mocking the API call locally
      await Future.delayed(const Duration(seconds: 2));

      return Response(
        requestOptions: RequestOptions(path: '/chat/job/JOB-2026-5678'),
        statusCode: 200,
        data: {
          "success": true,
          "data": {
            "job_id": "JOB-2026-5678",
            "conversation_id": conversationId,
            "message_id": "MSG-AI-002",
            "response":
                "For the LG 500L Refrigerator you're installing, the manual specifies:\n\n• Minimum 2 inches (5cm) clearance on both sides",
            "context_used": {
              "product_manual": true,
              "customer_questionnaire": true,
              "job_details": true
            },
            "sources": [
              {
                "type": "manual",
                "page": 12,
                "section": "Installation Requirements"
              },
              {"type": "questionnaire", "field": "space_measurements"}
            ],
            "related_suggestions": [
              "How to level the refrigerator?",
              "Water line connection steps",
              "Power requirements"
            ],
            "timestamp": DateTime.now().toIso8601String()
          }
        },
      );
    }
  }

  Future<Response> getUpsellProducts(String jobId) async {
    return await _dio.get('/technician/jobs/$jobId/upsell-products');
  }

  Stream<String> streamJobChat(String jobId, String message) async* {
    try {
      final response = await _dio.post(
        '/chat/job/$jobId',
        data: {'message': message},
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data.stream as Stream<List<int>>;
      yield* stream.map((chunk) => utf8.decode(chunk));
    } catch (e) {
      // Mock streaming for development
      final mockResponse =
          "To properly level the LG refrigerator, you should adjust the leveling legs at the front base. Rotate them clockwise to raise and counter-clockwise to lower. Ensure a slight backward tilt so the doors close automatically.";
      final chunks = mockResponse.split(' ');
      for (final chunk in chunks) {
        await Future.delayed(const Duration(milliseconds: 100));
        yield "$chunk ";
      }
    }
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('--> okhttp ${options.method} ${options.uri}');
    print('Headers: ${options.headers}');
    if (options.data != null) {
      try {
        final prettyJson =
            const JsonEncoder.withIndent('  ').convert(options.data);
        print('Body: $prettyJson');
      } catch (_) {
        print('Body: ${options.data}');
      }
    }
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('<-- okhttp ${response.statusCode} ${response.requestOptions.uri}');
    if (response.data != null) {
      try {
        final prettyJson =
            const JsonEncoder.withIndent('  ').convert(response.data);
        print('Response Body:\n$prettyJson');
      } catch (_) {
        print('Data: ${response.data}');
      }
    }
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print(
        '<-- okhttp ERROR [${err.response?.statusCode}] ${err.requestOptions.uri}');
    print('Message: ${err.message}');
    if (err.response?.data != null) {
      try {
        final prettyJson =
            const JsonEncoder.withIndent('  ').convert(err.response?.data);
        print('Error Data:\n$prettyJson');
      } catch (_) {
        print('Error Data: ${err.response?.data}');
      }
    }
    return super.onError(err, handler);
  }
}
