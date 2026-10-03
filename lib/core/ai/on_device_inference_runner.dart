import 'dart:async';
import 'package:flutter/foundation.dart';

/// Base class for all on-device AI inference exceptions
sealed class AiException implements Exception {
  final String message;
  final String? technicalDetails;

  const AiException(this.message, [this.technicalDetails]);

  @override
  String toString() => (technicalDetails != null) ? '$message ($technicalDetails)' : message;
}

class AiUnsupportedDeviceException extends AiException {
  const AiUnsupportedDeviceException(super.message, [super.technicalDetails]);
}

class AiModelMissingException extends AiException {
  final String modelId;
  const AiModelMissingException(this.modelId, [String? details])
      : super('Required AI model "$modelId" is not installed.', details);
}

class AiOutOfMemoryException extends AiException {
  const AiOutOfMemoryException([super.details])
      : super('Inference halted due to memory constraints on this device.', details);
}

class AiCancelledException extends AiException {
  const AiCancelledException([super.message = 'AI inference was cancelled by user.']);
}

class AiAudioFormatException extends AiException {
  const AiAudioFormatException(super.message, [super.details]);
}

class AiChecksumException extends AiException {
  final String expected;
  final String actual;
  const AiChecksumException(this.expected, this.actual)
      : super('Model file integrity check failed: SHA-256 hash mismatch.');
}

/// Cooperative cancellation token
class CancellationToken {
  bool _isCancelled = false;
  final List<VoidCallback> _listeners = [];

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final callback in List.unmodifiable(_listeners)) {
      try {
        callback();
      } catch (e) {
        debugPrint('Error executing cancel listener: $e');
      }
    }
    _listeners.clear();
  }

  void addListener(VoidCallback callback) {
    if (_isCancelled) {
      callback();
    } else {
      _listeners.add(callback);
    }
  }

  void removeListener(VoidCallback callback) {
    _listeners.remove(callback);
  }

  void throwIfCancelled() {
    if (_isCancelled) {
      throw const AiCancelledException();
    }
  }
}

/// Simple asynchronous Mutex lock for limiting concurrent inference
class _AsyncMutex {
  Completer<void>? _completer;

  Future<void> acquire() async {
    while (_completer != null) {
      await _completer!.future;
    }
    _completer = Completer<void>();
  }

  void release() {
    final c = _completer;
    _completer = null;
    c?.complete();
  }
}

/// Central orchestrator for off-UI-thread AI inference with concurrency control and idle eviction
class OnDeviceInferenceRunner {
  static final _AsyncMutex _heavyTaskLock = _AsyncMutex();
  static bool _isRunning = false;
  static DateTime? _lastInferenceTime;
  static Timer? _idleEvictionTimer;
  static final List<Future<void> Function()> _idleCleaners = [];

  static bool get isBusy => _isRunning;

  /// Registers a callback to be called when inference engine has been idle for 30 seconds
  static void registerIdleCleaner(Future<void> Function() cleaner) {
    _idleCleaners.add(cleaner);
  }

  /// Removes a previously registered idle cleaner
  static void unregisterIdleCleaner(Future<void> Function() cleaner) {
    _idleCleaners.remove(cleaner);
  }

  /// Executes an AI task ensuring strictly single-concurrency, cancellation checks, and error mapping
  static Future<T> runHeavyInference<T>({
    required String taskName,
    required Future<T> Function(CancellationToken token) action,
    CancellationToken? cancelToken,
  }) async {
    final effectiveToken = cancelToken ?? CancellationToken();
    effectiveToken.throwIfCancelled();

    _idleEvictionTimer?.cancel();
    _idleEvictionTimer = null;

    debugPrint('AI Inference: Waiting for lock for "$taskName"...');
    await _heavyTaskLock.acquire();
    _isRunning = true;
    debugPrint('AI Inference: Acquired lock for "$taskName"');

    try {
      effectiveToken.throwIfCancelled();
      final result = await action(effectiveToken);
      effectiveToken.throwIfCancelled();
      return result;
    } on AiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw AiException('AI task "$taskName" timed out.', e.message);
    } catch (e, stack) {
      debugPrint('AI Inference error during "$taskName": $e\n$stack');
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('outofmemory') || errorStr.contains('out of memory') || errorStr.contains('oom')) {
        throw AiOutOfMemoryException(e.toString());
      }
      throw AiException('Inference error in "$taskName": $e');
    } finally {
      _isRunning = false;
      _lastInferenceTime = DateTime.now();
      _heavyTaskLock.release();
      debugPrint('AI Inference: Released lock for "$taskName"');

      _scheduleIdleEviction();
    }
  }

  static void _scheduleIdleEviction() {
    _idleEvictionTimer?.cancel();
    _idleEvictionTimer = Timer(const Duration(seconds: 30), () async {
      debugPrint('AI Inference: Idle timeout (30s) reached. Evicting native model caches...');
      for (final cleaner in List.unmodifiable(_idleCleaners)) {
        try {
          await cleaner();
        } catch (e) {
          debugPrint('Error running idle cleaner: $e');
        }
      }
    });
  }

  /// Manually trigger cache cleanup and release of native model weights
  static Future<void> releaseMemoryNow() async {
    _idleEvictionTimer?.cancel();
    _idleEvictionTimer = null;
    for (final cleaner in List.unmodifiable(_idleCleaners)) {
      try {
        await cleaner();
      } catch (e) {
        debugPrint('Error running manual cleaner: $e');
      }
    }
  }
}
