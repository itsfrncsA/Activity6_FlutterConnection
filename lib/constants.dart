class AppConstants {
  // DummyJSON API Endpoints
  static const String dummyJsonBaseUrl = 'https://dummyjson.com';
  static const String dummyJsonLoginUrl = 'https://dummyjson.com/auth/login';
  static const String dummyJsonUsersUrl = 'https://dummyjson.com/users';
  static const String dummyJsonAddUserUrl = 'https://dummyjson.com/users/add';
  static const String dummyJsonAuthMeUrl = 'https://dummyjson.com/auth/me';

  // SharedPreferences Keys
  static const String keyToken = 'auth_token';
  static const String keyRefreshToken = 'auth_refresh_token';
  static const String keyUserData = 'user_data';
  static const String keyLoginType = 'login_type';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyThemeMode = 'theme_mode';

  // Login Type Identifiers
  static const String loginTypeFirebase = 'FIREBASE';
  static const String loginTypeDummyJson = 'DUMMY_JSON';
}
