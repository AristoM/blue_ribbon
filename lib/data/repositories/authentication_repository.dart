import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blue_ribbon/data/services/api_service.dart';
import 'package:blue_ribbon/data/models/user.dart';

enum AuthenticationStatus { unknown, authenticated, unauthenticated }

class AuthenticationRepository {
  final ApiService _apiService;
  final SharedPreferences _prefs;
  final _controller = StreamController<AuthenticationStatus>();
  User? _user;

  AuthenticationRepository({
    required ApiService apiService,
    required SharedPreferences prefs,
  })  : _apiService = apiService,
        _prefs = prefs;

  Stream<AuthenticationStatus> get status => _controller.stream;

  User? get currentUser => _user;

  Future<void> logIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.login(email, password);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final userData = data['admin'] ?? data['user'];
        _user = User.fromJson(userData);

        // Save credentials locally as requested
        await _prefs.setString('email', email);
        await _prefs.setString('password', password);
        await _prefs.setString('access_token', data['access_token']);
        await _prefs.setString('refresh_token', data['refresh_token']);

        _controller.add(AuthenticationStatus.authenticated);
      } else {
        _controller.add(AuthenticationStatus.unauthenticated);
        throw Exception('Login failed');
      }
    } catch (e) {
      _controller.add(AuthenticationStatus.unauthenticated);
      rethrow;
    }
  }

  Future<void> logOut() async {
    try {
      final refreshToken = _prefs.getString('refresh_token');
      if (refreshToken != null) {
        await _apiService.logout(refreshToken);
      }
    } catch (_) {
      // Ignore logout errors
    } finally {
      await _prefs.remove('email');
      await _prefs.remove('password');
      await _prefs.remove('access_token');
      await _prefs.remove('refresh_token');
      _user = null;
      _controller.add(AuthenticationStatus.unauthenticated);
    }
  }

  Future<void> tryAutoLogin() async {
    print('AuthRepo: Try Auto Login started');
    final email = _prefs.getString('email');
    final password = _prefs.getString('password');

    if (email != null && password != null) {
      try {
        print('AuthRepo: Found credentials, attempting login...');
        await logIn(email: email, password: password);
        print('AuthRepo: Auto login successful');
      } catch (e) {
        print('AuthRepo: Auto login failed: $e');
        _controller.add(AuthenticationStatus.unauthenticated);
      }
    } else {
      print('AuthRepo: No credentials found, unauthenticated');
      _controller.add(AuthenticationStatus.unauthenticated);
    }
  }

  void dispose() => _controller.close();
}
