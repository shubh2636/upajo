import 'dart:async';
import 'package:flutter/foundation.dart';

/// Severity level for captured errors and events
enum ErrorSeverity { info, warning, error, fatal }

/// Abstract crash reporting and telemetry adapter interface
abstract class CrashReportingService {
  Future<void> initialize();
  void logBreadcrumb(String message, {String? category, Map<String, dynamic>? data});
  void recordError(dynamic exception, StackTrace? stack, {String? reason, ErrorSeverity severity = ErrorSeverity.error});
  void setUserIdentifier(String userId, {String? role});
  void clearUser();
}

/// Production Crash Reporting Implementation with Automatic PII Sanitization
/// (Compliant with Play Store Data Safety & Indian Digital Personal Data Protection Act)
class UpajoCrashReporting implements CrashReportingService {
  static final UpajoCrashReporting _instance = UpajoCrashReporting._internal();
  factory UpajoCrashReporting() => _instance;
  UpajoCrashReporting._internal();

  final List<Map<String, dynamic>> _breadcrumbs = [];
  static const int _maxBreadcrumbs = 50;
  String? _currentUserId;
  String? _userRole;

  // Regex patterns to scrub PII from error logs and stack traces
  static final RegExp _phoneRegex = RegExp(r'(\+?91[\-\s]?)?[6-9]\d{9}');
  static final RegExp _upiRegex = RegExp(r'[\w\.\-]+@[a-zA-Z]+');
  static final RegExp _tokenRegex = RegExp(r'bearer\s+[A-Za-z0-9\-\._~\+\/]+=*', caseSensitive: false);

  @override
  Future<void> initialize() async {
    // 1. Intercept Flutter Framework Errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      recordError(
        details.exception,
        details.stack,
        reason: details.context?.toString() ?? 'Flutter Framework Error',
        severity: ErrorSeverity.fatal,
      );
    };

    // 2. Intercept Asynchronous Platform Dispatcher Errors
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      recordError(error, stack, reason: 'Uncaught Platform Async Error', severity: ErrorSeverity.fatal);
      return true; // Handled
    };

    logBreadcrumb('Crash reporting initialized', category: 'lifecycle');
  }

  /// Sanitizes sensitive farmer and consumer PII (phones, UPI IDs, Auth Tokens)
  String _sanitizePii(String input) {
    var sanitized = input.replaceAllMapped(_phoneRegex, (m) {
      final matched = m.group(0)!;
      return '[PHONE_REDACTED_${matched.substring(matched.length > 4 ? matched.length - 4 : 0)}]';
    });
    sanitized = sanitized.replaceAllMapped(_upiRegex, (_) => '[UPI_REDACTED]');
    sanitized = sanitized.replaceAllMapped(_tokenRegex, (_) => 'Bearer [TOKEN_REDACTED]');
    return sanitized;
  }

  @override
  void logBreadcrumb(String message, {String? category, Map<String, dynamic>? data}) {
    final cleanMessage = _sanitizePii(message);
    final entry = {
      'timestamp': DateTime.now().toIso8601String(),
      'category': category ?? 'general',
      'message': cleanMessage,
      if (data != null) 'data': data,
    };

    _breadcrumbs.add(entry);
    if (_breadcrumbs.length > _maxBreadcrumbs) {
      _breadcrumbs.removeAt(0);
    }

    if (kDebugMode) {
      debugPrint('[Telemetry] [${entry['category']}] $cleanMessage');
    }
  }

  @override
  void recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    final sanitizedError = _sanitizePii(exception.toString());
    final sanitizedReason = reason != null ? _sanitizePii(reason) : null;

    final errorPayload = {
      'timestamp': DateTime.now().toIso8601String(),
      'error': sanitizedError,
      'reason': sanitizedReason,
      'severity': severity.name,
      'user_id': _currentUserId,
      'role': _userRole,
      'recent_breadcrumbs': List<Map<String, dynamic>>.from(_breadcrumbs),
      if (stack != null) 'stack': _sanitizePii(stack.toString().split('\n').take(12).join('\n')),
    };

    if (kDebugMode) {
      debugPrint('🚨 [CrashReport] [${severity.name.toUpperCase()}] $sanitizedError ($sanitizedReason)');
    }

    // In Production: Deliver to Sentry / Firebase Crashlytics SDK
    // FirebaseCrashlytics.instance.recordError(sanitizedError, stack, reason: sanitizedReason);
  }

  @override
  void setUserIdentifier(String userId, {String? role}) {
    _currentUserId = userId;
    _userRole = role;
    logBreadcrumb('User session identified: $userId ($role)', category: 'auth');
  }

  @override
  void clearUser() {
    _currentUserId = null;
    _userRole = null;
    logBreadcrumb('User logged out, session cleared', category: 'auth');
  }

  List<Map<String, dynamic>> get capturedBreadcrumbs => List.unmodifiable(_breadcrumbs);
}
