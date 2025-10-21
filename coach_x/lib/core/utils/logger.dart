import 'package:logger/logger.dart' as log;
import 'package:flutter/foundation.dart';

/// 日志工具类
/// 封装logger包，提供统一的日志输出接口
class AppLogger {
  AppLogger._(); // 私有构造函数，防止实例化

  static final _logger = log.Logger(
    printer: log.PrettyPrinter(
      methodCount: 2, // 显示的方法调用栈层数
      errorMethodCount: 8, // 错误时显示的方法调用栈层数
      lineLength: 120, // 每行长度
      colors: true, // 彩色输出
      printEmojis: true, // 显示表情符号
      dateTimeFormat: log.DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static final _simpleLogger = log.Logger(
    printer: log.SimplePrinter(colors: true),
  );

  /// 调试日志
  /// 仅在Debug模式下输出
  static void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// 信息日志
  /// 仅在Debug模式下输出
  static void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.i(message, error: error, stackTrace: stackTrace);
    }
  }

  /// 警告日志
  /// 所有模式下都输出
  static void warning(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// 错误日志
  /// 所有模式下都输出
  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// 致命错误日志
  /// 所有模式下都输出，用于严重错误
  static void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// 简单日志
  /// 使用简单格式输出，适合快速调试
  static void simple(dynamic message) {
    if (kDebugMode) {
      _simpleLogger.d(message);
    }
  }

  /// 网络请求日志
  static void network({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic data,
    int? statusCode,
    dynamic response,
    dynamic error,
  }) {
    if (kDebugMode) {
      final buffer = StringBuffer();
      buffer.writeln('━━━━━━━━━━━━━━━━━━ 网络请求 ━━━━━━━━━━━━━━━━━━');
      buffer.writeln('[$method] $url');

      if (headers != null && headers.isNotEmpty) {
        buffer.writeln('Headers: $headers');
      }

      if (data != null) {
        buffer.writeln('Data: $data');
      }

      if (statusCode != null) {
        buffer.writeln('Status Code: $statusCode');
      }

      if (response != null) {
        buffer.writeln('Response: $response');
      }

      if (error != null) {
        buffer.writeln('Error: $error');
      }

      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (error != null) {
        _logger.e(buffer.toString());
      } else {
        _logger.i(buffer.toString());
      }
    }
  }

  /// 路由日志
  static void route(String from, String to) {
    if (kDebugMode) {
      _logger.i('路由跳转: $from → $to');
    }
  }

  /// 生命周期日志
  static void lifecycle(String widget, String state) {
    if (kDebugMode) {
      _logger.d('[$widget] $state');
    }
  }

  /// 数据库操作日志
  static void database(String operation, {dynamic data, dynamic error}) {
    if (kDebugMode) {
      if (error != null) {
        _logger.e('数据库操作失败: $operation', error: error);
      } else {
        _logger.d('数据库操作: $operation${data != null ? ' | $data' : ''}');
      }
    }
  }

  /// Firebase日志
  static void firebase(String operation, {dynamic data, dynamic error}) {
    if (kDebugMode) {
      if (error != null) {
        _logger.e('Firebase操作失败: $operation', error: error);
      } else {
        _logger.d('Firebase操作: $operation${data != null ? ' | $data' : ''}');
      }
    }
  }

  /// 性能日志
  static void performance(String operation, Duration duration) {
    if (kDebugMode) {
      _logger.i('性能统计: $operation - ${duration.inMilliseconds}ms');
    }
  }
}

/// 简化的日志调用
void logDebug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
  AppLogger.debug(message, error, stackTrace);
}

void logInfo(dynamic message, [dynamic error, StackTrace? stackTrace]) {
  AppLogger.info(message, error, stackTrace);
}

void logWarning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
  AppLogger.warning(message, error, stackTrace);
}

void logError(dynamic message, [dynamic error, StackTrace? stackTrace]) {
  AppLogger.error(message, error, stackTrace);
}
