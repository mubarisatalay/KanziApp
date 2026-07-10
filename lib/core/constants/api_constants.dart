/// API configuration.
///
/// Override the base URL at build/run time, e.g.:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1   (Android emulator)
///   flutter run --dart-define=API_BASE_URL=http://localhost:8080/api/v1  (iOS simulator / desktop / web)
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );
}
