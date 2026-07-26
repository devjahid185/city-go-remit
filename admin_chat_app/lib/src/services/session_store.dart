import 'package:admin_chat_app/src/models/chat_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  const SessionStore();

  static const _tokenKey = 'admin_token';
  static const _nameKey = 'admin_name';
  static const _emailKey = 'admin_email';

  Future<AdminSession> load() async {
    final preferences = await SharedPreferences.getInstance();
    return AdminSession(
      token: preferences.getString(_tokenKey) ?? '',
      admin: AdminUser(
        name: preferences.getString(_nameKey) ?? 'Admin',
        email: preferences.getString(_emailKey) ?? '',
      ),
    );
  }

  Future<void> save({
    required String token,
    required AdminUser admin,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, token);
    await preferences.setString(_nameKey, admin.name);
    await preferences.setString(_emailKey, admin.email);
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
    await preferences.remove(_nameKey);
    await preferences.remove(_emailKey);
  }
}

class AdminSession {
  const AdminSession({
    required this.token,
    required this.admin,
  });

  final String token;
  final AdminUser admin;

  bool get isLoggedIn => token.trim().isNotEmpty;
}
