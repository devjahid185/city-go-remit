import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService()
    : _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  final GoogleSignIn _googleSignIn;

  Future<String?> signInAndGetEmail() async {
    final account = await _googleSignIn.signIn();
    return account?.email;
  }
}
