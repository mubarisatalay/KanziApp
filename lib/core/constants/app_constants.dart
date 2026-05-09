/// Application-wide constants
class AppConstants {
  AppConstants._();

  /// App name
  static const String appName = 'Kanzi';

  /// Room code length
  static const int roomCodeLength = 6;

  /// Maximum image upload size in MB
  static const int maxImageSizeMB = 5;

  /// Image compression quality (0-100)
  static const int imageCompressionQuality = 85;

  /// Maximum image width for compression
  static const int maxImageWidth = 1080;

  /// Minimum username length
  static const int minUsernameLength = 3;

  /// Maximum username length
  static const int maxUsernameLength = 20;

  /// Challenge duration in hours
  static const int challengeDurationHours = 24;

  /// Date format for display
  static const String dateFormat = 'MMM dd, yyyy';

  /// Time format for display
  static const String timeFormat = 'HH:mm';
}
