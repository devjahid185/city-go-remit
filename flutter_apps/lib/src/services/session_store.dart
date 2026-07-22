import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  const SessionStore();

  static const _onboardingSeenKey = 'onboarding_seen';
  static const _loggedInKey = 'logged_in';
  static const _userNameKey = 'user_name';
  static const _userEmailKey = 'user_email';
  static const _userPhoneKey = 'user_phone';
  static const _userAddressKey = 'user_address';
  static const _userBalanceKey = 'user_balance';
  static const _referralCodeKey = 'referral_code';
  static const _referralBonusKey = 'referral_bonus_earned';
  static const _authTokenKey = 'auth_token';
  static const _homeSwipeHintSeenKey = 'home_swipe_hint_seen';

  Future<AppSession> load() async {
    final preferences = await SharedPreferences.getInstance();
    return AppSession(
      onboardingSeen: preferences.getBool(_onboardingSeenKey) ?? false,
      loggedIn: preferences.getBool(_loggedInKey) ?? false,
      userName: preferences.getString(_userNameKey) ?? 'User',
      userEmail: preferences.getString(_userEmailKey) ?? '',
      userPhone: preferences.getString(_userPhoneKey) ?? '',
      userAddress: preferences.getString(_userAddressKey) ?? '',
      userBalance: preferences.getDouble(_userBalanceKey) ?? 0,
      referralCode: preferences.getString(_referralCodeKey) ?? '',
      referralBonusEarned: preferences.getDouble(_referralBonusKey) ?? 0,
      authToken: preferences.getString(_authTokenKey),
      homeSwipeHintSeen: preferences.getBool(_homeSwipeHintSeenKey) ?? false,
    );
  }

  Future<void> markOnboardingSeen() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_onboardingSeenKey, true);
  }

  Future<void> saveLogin({
    required String userName,
    String userEmail = '',
    String userPhone = '',
    String userAddress = '',
    double userBalance = 0,
    String referralCode = '',
    double referralBonusEarned = 0,
    String? authToken,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_onboardingSeenKey, true);
    await preferences.setBool(_loggedInKey, true);
    await preferences.setString(
      _userNameKey,
      userName.trim().isEmpty ? 'User' : userName.trim(),
    );
    await preferences.setString(_userEmailKey, userEmail.trim());
    await preferences.setString(_userPhoneKey, userPhone.trim());
    await preferences.setString(_userAddressKey, userAddress.trim());
    await preferences.setDouble(_userBalanceKey, userBalance);
    await preferences.setString(_referralCodeKey, referralCode.trim());
    await preferences.setDouble(_referralBonusKey, referralBonusEarned);
    if (authToken != null && authToken.trim().isNotEmpty) {
      await preferences.setString(_authTokenKey, authToken.trim());
    }
  }

  Future<void> saveProfile({
    required String userName,
    required String userEmail,
    required String userPhone,
    required String userAddress,
    double? userBalance,
    String? referralCode,
    double? referralBonusEarned,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _userNameKey,
      userName.trim().isEmpty ? 'User' : userName.trim(),
    );
    await preferences.setString(_userEmailKey, userEmail.trim());
    await preferences.setString(_userPhoneKey, userPhone.trim());
    await preferences.setString(_userAddressKey, userAddress.trim());
    if (userBalance != null) {
      await preferences.setDouble(_userBalanceKey, userBalance);
    }
    if (referralCode != null) {
      await preferences.setString(_referralCodeKey, referralCode.trim());
    }
    if (referralBonusEarned != null) {
      await preferences.setDouble(_referralBonusKey, referralBonusEarned);
    }
  }

  Future<void> saveBalance(double userBalance) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_userBalanceKey, userBalance);
  }

  Future<void> signOut() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_loggedInKey, false);
    await preferences.remove(_userNameKey);
    await preferences.remove(_userEmailKey);
    await preferences.remove(_userPhoneKey);
    await preferences.remove(_userAddressKey);
    await preferences.remove(_userBalanceKey);
    await preferences.remove(_referralCodeKey);
    await preferences.remove(_referralBonusKey);
    await preferences.remove(_authTokenKey);
  }

  Future<void> markHomeSwipeHintSeen() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_homeSwipeHintSeenKey, true);
  }
}

class AppSession {
  const AppSession({
    required this.onboardingSeen,
    required this.loggedIn,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.userAddress,
    required this.userBalance,
    required this.referralCode,
    required this.referralBonusEarned,
    required this.homeSwipeHintSeen,
    this.authToken,
  });

  final bool onboardingSeen;
  final bool loggedIn;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String userAddress;
  final double userBalance;
  final String referralCode;
  final double referralBonusEarned;
  final bool homeSwipeHintSeen;
  final String? authToken;
}
