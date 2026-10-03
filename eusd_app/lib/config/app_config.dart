import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// 全局配置
/// 首次安装使用内置默认地址，用户可在登录页修改并保存
class AppConfig {
  static const String _keyBaseUrl = 'app_base_url';
  static const String _keyAdminBaseUrl = 'app_admin_base_url';

  /// 内置默认服务器地址（用户可在 App 内改）
  static const String defaultBaseUrl = 'http://36.37.133.244:18080/api';
  static const String defaultAdminBaseUrl = 'http://36.37.133.244:18080/api/admin';

  static String _baseUrl = defaultBaseUrl;
  static String _adminBaseUrl = defaultAdminBaseUrl;
  static bool _loaded = false;

  static String get baseUrl => _baseUrl;
  static String get adminBaseUrl => _adminBaseUrl;
  static bool get isLoaded => _loaded;

  /// App 启动时调用
  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _baseUrl = p.getString(_keyBaseUrl) ?? defaultBaseUrl;
    _adminBaseUrl = p.getString(_keyAdminBaseUrl) ?? defaultAdminBaseUrl;
    _loaded = true;
  }

  /// 用户手动设置服务器地址
  /// 传入 "http://1.2.3.4:8080" 会自动补 /api
  static Future<void> setBaseUrl(String url) async {
    final clean = url.trim().replaceAll(RegExp(r'/+$'), '');
    _baseUrl = clean.endsWith('/api') ? clean : '$clean/api';
    _adminBaseUrl = '$_baseUrl/admin';
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyBaseUrl, _baseUrl);
    await p.setString(_keyAdminBaseUrl, _adminBaseUrl);
  }

  /// 还原默认
  static Future<void> reset() async {
    _baseUrl = defaultBaseUrl;
    _adminBaseUrl = defaultAdminBaseUrl;
    final p = await SharedPreferences.getInstance();
    await p.remove(_keyBaseUrl);
    await p.remove(_keyAdminBaseUrl);
  }

  /// 检测当前地址是否可连（登录页用）
  static Future<bool> testConnection() async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('$_baseUrl/cards/ping');
      final req = await client.getUrl(uri).timeout(const Duration(seconds: 5));
      final resp = await req.close().timeout(const Duration(seconds: 5));
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
