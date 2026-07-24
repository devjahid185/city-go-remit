import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService()
    : _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
      );

  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '945338558097-aalgq6jmh00pembk3hfmdr74v1u2nv7n.apps.googleusercontent.com',
  );

  final GoogleSignIn _googleSignIn;

  Future<GoogleAccountInfo?> signIn() async {
    await _googleSignIn.signOut();
    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final authentication = await account.authentication;
    final idToken = authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const GoogleSignInConfigException();
    }

    return GoogleAccountInfo(
      email: account.email,
      name: account.displayName ?? account.email.split('@').first,
      idToken: idToken,
    );
  }
}

class GoogleAccountInfo {
  const GoogleAccountInfo({
    required this.email,
    required this.name,
    required this.idToken,
  });

  final String email;
  final String name;
  final String idToken;
}

class GoogleSignInConfigException implements Exception {
  const GoogleSignInConfigException();
}
