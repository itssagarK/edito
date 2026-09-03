import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CrashLog {
  final String message;
  final String stackTrace;
  final DateTime timestamp;
  final String? reason;

  CrashLog({
    required this.message,
    required this.stackTrace,
    required this.timestamp,
    this.reason,
  });

  Map<String, dynamic> toJson() => {
        'message': message,
        'stackTrace': stackTrace,
        'timestamp': timestamp.toIso8601String(),
        'reason': reason,
      };

  factory CrashLog.fromJson(Map<String, dynamic> json) => CrashLog(
        message: json['message'] as String? ?? '',
        stackTrace: json['stackTrace'] as String? ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
        reason: json['reason'] as String?,
      );
}

class CrashReportingService {
  static final List<CrashLog> _inMemoryLogs = [];

  /// Initializes global exception handlers for Flutter framework and Dart isolate
  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      recordError(
        details.exception,
        details.stack,
        reason: details.context?.toString() ?? 'Flutter Error',
      );
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      recordError(error, stack, reason: 'Platform Dispatcher Uncaught Exception');
      return true;
    };
  }

  /// Records an application error with persistent storage
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
  }) async {
    final log = CrashLog(
      message: exception.toString(),
      stackTrace: stack?.toString() ?? '',
      timestamp: DateTime.now(),
      reason: reason,
    );

    _inMemoryLogs.add(log);
    debugPrint('🚨 [Edito CrashReporter] Error: ${log.message}');

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final logDir = Directory(p.join(docDir.path, 'logs'));
      if (!logDir.existsSync()) {
        logDir.createSync(recursive: true);
      }
      final logFile = File(p.join(logDir.path, 'crash_reports.json'));
      final allLogs = await getSavedCrashLogs();
      allLogs.add(log);
      // Keep most recent 50 crash logs
      if (allLogs.length > 50) {
        allLogs.removeRange(0, allLogs.length - 50);
      }
      await logFile.writeAsString(jsonEncode(allLogs.map((l) => l.toJson()).toList()));
    } catch (_) {}
  }

  /// Retrieves saved crash logs from disk
  static Future<List<CrashLog>> getSavedCrashLogs() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final logFile = File(p.join(docDir.path, 'logs', 'crash_reports.json'));
      if (!logFile.existsSync()) return List.from(_inMemoryLogs);
      final jsonStr = await logFile.readAsString();
      final List list = jsonDecode(jsonStr);
      return list.map((item) => CrashLog.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return List.from(_inMemoryLogs);
    }
  }

  /// Clears persisted crash logs
  static Future<void> clearLogs() async {
    _inMemoryLogs.clear();
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final logFile = File(p.join(docDir.path, 'logs', 'crash_reports.json'));
      if (logFile.existsSync()) {
        await logFile.delete();
      }
    } catch (_) {}
  }
}
