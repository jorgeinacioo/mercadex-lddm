class AppConfig {
  const AppConfig._();

  static const apiUrl = String.fromEnvironment('API_URL');

  static final useMockData = const bool.hasEnvironment('USE_MOCK_DATA')
      ? const bool.fromEnvironment('USE_MOCK_DATA')
      : apiUrl.isEmpty;
}
