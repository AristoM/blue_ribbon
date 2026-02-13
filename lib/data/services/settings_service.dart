import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _baseUrlKey = 'api_base_url';
  static const String defaultBaseUrl = 'http://192.168.29.103:8080/api/v1';

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_baseUrlKey) ?? defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url);
  }
}
