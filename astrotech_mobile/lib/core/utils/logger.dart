import 'package:flutter/foundation.dart';

/// Centralized logging utility for the application
/// Provides different log levels with emoji prefixes for better visibility
class Logger {
  Logger._();

  /// Debug log - only shown in debug mode
  /// Use for detailed debugging information
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      print('🐛 DEBUG: $prefix$message');
    }
  }

  /// Info log - general informational messages
  /// Use for important flow information
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      print('ℹ️ INFO: $prefix$message');
    }
  }

  /// Warning log - shown in all modes
  /// Use for recoverable errors or unexpected situations
  static void warning(String message, [String? tag]) {
    final prefix = tag != null ? '[$tag] ' : '';
    print('⚠️ WARNING: $prefix$message');
  }

  /// Error log - shown in all modes
  /// Use for errors that need attention
  static void error(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  ]) {
    final prefix = tag != null ? '[$tag] ' : '';
    print('❌ ERROR: $prefix$message');
    if (error != null) print('Error details: $error');
    if (stackTrace != null && kDebugMode) {
      print('Stack trace: $stackTrace');
    }
  }

  /// API-specific debug log
  static void api(String message) {
    debug(message, 'API');
  }

  /// Workflow-specific debug log
  static void workflow(String message) {
    debug(message, 'WORKFLOW');
  }

  /// Photo service-specific debug log
  static void photo(String message) {
    debug(message, 'PHOTO');
  }

  /// Sync-specific debug log
  static void sync(String message) {
    debug(message, 'SYNC');
  }
}
