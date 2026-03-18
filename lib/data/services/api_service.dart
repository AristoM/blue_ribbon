import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio _dio;
  bool _initialized = false;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Ensure Base URL is loaded
        if (options.baseUrl.isEmpty || options.baseUrl == 'http://localhost') {
          options.baseUrl = await SettingsService.getBaseUrl();
        }

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

  /// Force refresh the Dio instance with the latest Base URL
  void reset() {
    _initialized = false;
    _dio.options.baseUrl = ''; // Trigger reload on next request
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

  Future<Response> getJobDetails(String jobId) async {
    return await _dio.get('/technician/jobs/$jobId');
  }

  Future<Response> sendJobChatMessage(String jobId, String message) async {
    return await _dio.post('/chat/job/$jobId', data: {'message': message});
  }

  Future<Response> sendChatMessage(String message) async {
    // Legacy method, forwarding to a default job ID or could be removed if unused elsewhere
    return await sendJobChatMessage(
        '1aca6967-a44e-4cda-a24f-9f4919a1a966', message);
  }

  Future<Response> getUpsellProducts(String jobId) async {
    return await _dio.get('/technician/jobs/$jobId/upsell-products');
  }

  Stream<Map<String, dynamic>> streamJobChat(String jobId, String message) async* {
    try {
      final response = await _dio.post(
        '/chat/job/$jobId',
        data: {
          'message': message,
          'additionalProperty': 'anything', // Added as per sample request
        },
        options: Options(responseType: ResponseType.stream),
      );

      final stream = (response.data.stream as Stream).cast<List<int>>();
      yield* stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .where((line) => line.trim().startsWith('data: '))
          .map((line) {
        String data = line.trim().substring(6).trim();

        // Handle nested "data: " format
        while (data.startsWith('data: ')) {
          data = data.substring(6).trim();
        }

        if (data == '[DONE]' || data == '[done]') {
          return {'type': '[done]', 'payload': {}};
        }

        try {
          final decoded = jsonDecode(data);
          if (decoded is Map<String, dynamic>) {
            // If the payload itself contains a 'content' field that is another SSE-like 'data: {...}' string,
            // we should probably let the UI handle it or parse it recursively if it's consistent.
            // Based on the sample: data: {"type": "md_content", "payload": {"content": "data: {\"type\": \"status\", ...}"}}
            // This looks like double wrapping. Let's try to unwrap if it's a string starting with "data: ".
            if (decoded['type'] == 'md_content' &&
                decoded['payload'] is Map &&
                decoded['payload']['content'] is String) {
              String nestedContent = decoded['payload']['content'];
              if (nestedContent.trim().startsWith('data: ')) {
                String nestedData = nestedContent.trim().substring(6).trim();
                try {
                  final nestedDecoded = jsonDecode(nestedData);
                  if (nestedDecoded is Map<String, dynamic>) {
                    return nestedDecoded;
                  }
                } catch (_) {
                  // Fallback to original decoded if nested fails
                }
              }
            }
            return decoded;
          }
          return {'type': 'text', 'payload': {'content': data}};
        } catch (_) {
          return {'type': 'text', 'payload': {'content': data}};
        }
      });
    } catch (e) {
      yield {
        'type': 'error',
        'payload': {'message': e.toString()}
      };
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
