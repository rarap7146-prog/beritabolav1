import 'package:logger/logger.dart';

/// Centralized logging utility for the application
/// 
/// Usage:
/// ```dart
/// AppLogger.info('User logged in');
/// AppLogger.error('Failed to fetch data', error: exception, stackTrace: stackTrace);
/// AppLogger.debug('Cache hit', data: {'key': 'value'});
/// ```
class AppLogger {
  static final Logger _logger = Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static bool _isEnabled = true;

  /// Enable/disable logging (useful for production)
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Log verbose messages (lowest priority)
  static void verbose(String message, {dynamic data}) {
    if (_isEnabled) {
      _logger.t(data != null ? '$message: $data' : message);
    }
  }

  /// Log debug messages
  static void debug(String message, {dynamic data}) {
    if (_isEnabled) {
      _logger.d(data != null ? '$message: $data' : message);
    }
  }

  /// Log info messages
  static void info(String message, {dynamic data}) {
    if (_isEnabled) {
      _logger.i(data != null ? '$message: $data' : message);
    }
  }

  /// Log warning messages
  static void warning(String message, {dynamic data, dynamic error}) {
    if (_isEnabled) {
      _logger.w(data != null ? '$message: $data' : message, error: error);
    }
  }

  /// Log error messages
  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    dynamic data,
  }) {
    if (_isEnabled) {
      _logger.e(
        data != null ? '$message: $data' : message,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Log fatal/critical errors
  static void fatal(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (_isEnabled) {
      _logger.f(message, error: error, stackTrace: stackTrace);
    }
  }
}