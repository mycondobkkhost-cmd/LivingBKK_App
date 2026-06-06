import 'package:flutter/foundation.dart';
import '../data/error_catalog.dart';
import 'analytics_service.dart';

/// รวบรวม error ฝั่ง client → analytics + แสดงในศูนย์รายงานแอดมิน
class ErrorReportingService {
  ErrorReportingService._();
  static final instance = ErrorReportingService._();

  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;

    FlutterError.onError = (details) {
      report(
        message: details.exceptionAsString(),
        route: details.context?.toString(),
        stack: details.stack?.toString(),
      );
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      report(message: error.toString(), stack: stack.toString());
      return true;
    };
  }

  void report({
    required String message,
    String? errorKey,
    String? route,
    String? stack,
    Map<String, dynamic>? metadata,
  }) {
    final key = errorKey ?? ErrorCatalog.classifyFromMessage(message);
    debugPrint('PROPPITER error [$key]: $message');

    AnalyticsService.instance.trackClientError(
      errorKey: key,
      message: message.length > 500 ? message.substring(0, 500) : message,
      route: route,
      metadata: {
        if (stack != null) 'stack': stack.length > 800 ? stack.substring(0, 800) : stack,
        ...?metadata,
      },
    );
  }

}
