import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'models/ai_model_descriptor.dart';
import 'on_device_inference_runner.dart';

class AiModelDownloadProgress {
  final int bytesDownloaded;
  final int totalBytes;
  final double fraction;
  final double speedBytesPerSec;
  final String statusMessage;

  const AiModelDownloadProgress({
    required this.bytesDownloaded,
    required this.totalBytes,
    required this.fraction,
    required this.speedBytesPerSec,
    required this.statusMessage,
  });

  int get percent => (fraction * 100).clamp(0, 100).toInt();

  String get formattedSpeed {
    if (speedBytesPerSec < 1024 * 1024) {
      return '${(speedBytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(speedBytesPerSec / (1024 * 1024)).toStringAsFixed(2)} MB/s';
  }
}

class AiModelManager {
  static const MethodChannel _channel = MethodChannel('com.edito.app/gallery');
  static Directory? _cachedModelsDir;

  /// Returns the persistent local models directory (e.g. appSupport/models)
  static Future<Directory> getModelsDirectory() async {
    if (_cachedModelsDir != null && await _cachedModelsDir!.exists()) {
      return _cachedModelsDir!;
    }

    final baseDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(baseDir.path, 'models'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cachedModelsDir = dir;
    return dir;
  }

  /// Target file path where this model resides on device storage
  static Future<String> getModelPath(AiModelDescriptor model) async {
    final dir = await getModelsDirectory();
    final ext = model.format.isNotEmpty ? model.format : 'bin';
    return p.join(dir.path, '${model.id}.$ext');
  }

  /// Checks if the model weights are present and ready for offline inference
  static Future<bool> isModelInstalled(AiModelDescriptor model) async {
    final targetPath = await getModelPath(model);
    final file = File(targetPath);
    if (await file.exists() && await file.length() > 0) {
      return true;
    }

    // For bundled models, check if asset exists in app package
    if (model.isBundled) {
      try {
        final byteData = await rootBundle.load(model.assetPath!);
        if (byteData.lengthInBytes > 0) {
          // Extract to local support file for direct native C++/TFLite handle
          await file.parent.create(recursive: true);
          final buffer = byteData.buffer;
          await file.writeAsBytes(
            buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
            flush: true,
          );
          return true;
        }
      } catch (_) {
        return false;
      }
    }

    return false;
  }

  /// Returns the absolute path to the local model weights file, or null if not yet installed
  static Future<String?> getModelLocalPath(AiModelDescriptor model) async {
    final installed = await isModelInstalled(model);
    if (!installed) return null;
    return getModelPath(model);
  }

  /// Queries remaining device storage space in bytes
  static Future<int> getAvailableStorageBytes() async {
    if (Platform.isAndroid) {
      try {
        final result = await _channel.invokeMethod<int>('getDiskFreeSpaceMb');
        if (result != null && result > 0) {
          return result * 1024 * 1024;
        }
      } catch (e) {
        debugPrint('Platform getDiskFreeSpaceMb fallback: $e');
      }
    }

    // Fallback: assume ample space (4 GB) if unable to probe native statfs
    return 4 * 1024 * 1024 * 1024;
  }

  /// Downloads and verifies an on-demand model with resumable chunks and SHA-256 verification
  static Stream<AiModelDownloadProgress> downloadModel(
    AiModelDescriptor model, {
    CancellationToken? cancelToken,
  }) async* {
    if (model.downloadUrl == null || model.downloadUrl!.isEmpty) {
      throw AiException('Model "${model.name}" does not specify a download URL.');
    }

    final cancel = cancelToken ?? CancellationToken();
    cancel.throwIfCancelled();

    final targetPath = await getModelPath(model);
    final partPath = '$targetPath.part';
    final partFile = File(partPath);
    final targetFile = File(targetPath);

    // 1. Verify available storage
    final freeBytes = await getAvailableStorageBytes();
    final requiredBytes = (model.sizeBytes * 2.2).toInt(); // 2.2x buffer for temp + final
    if (freeBytes < requiredBytes) {
      throw AiException(
        'Insufficient storage space to download ${model.name}.',
        'Required: ${(requiredBytes / (1024 * 1024)).toStringAsFixed(0)} MB, Available: ${(freeBytes / (1024 * 1024)).toStringAsFixed(0)} MB',
      );
    }

    yield AiModelDownloadProgress(
      bytesDownloaded: 0,
      totalBytes: model.sizeBytes,
      fraction: 0.0,
      speedBytesPerSec: 0,
      statusMessage: 'Connecting to download mirror...',
    );

    // 2. Check for partial resume
    int existingBytes = 0;
    if (await partFile.exists()) {
      existingBytes = await partFile.length();
      if (existingBytes >= model.sizeBytes) {
        // File may already be complete, verify below
        existingBytes = 0;
        await partFile.delete();
      }
    }

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final request = await client.getUrl(Uri.parse(model.downloadUrl!));
      if (existingBytes > 0) {
        request.headers.add('Range', 'bytes=$existingBytes-');
      }

      final response = await request.close();
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw AiException(
          'Download server returned HTTP ${response.statusCode}',
          response.reasonPhrase,
        );
      }

      final totalBytes = (response.contentLength > 0)
          ? (response.contentLength + existingBytes)
          : model.sizeBytes;

      final sink = partFile.openWrite(mode: existingBytes > 0 ? FileMode.append : FileMode.write);
      int receivedBytes = existingBytes;

      final stopwatch = Stopwatch()..start();
      int lastReportedBytes = existingBytes;
      int lastReportedTimeMs = 0;

      await for (final chunk in response) {
        cancel.throwIfCancelled();
        sink.add(chunk);
        receivedBytes += chunk.length;

        final elapsedMs = stopwatch.elapsedMilliseconds;
        if (elapsedMs - lastReportedTimeMs > 250) {
          final timeDiffSec = (elapsedMs - lastReportedTimeMs) / 1000.0;
          final bytesDiff = receivedBytes - lastReportedBytes;
          final speed = (timeDiffSec > 0) ? (bytesDiff / timeDiffSec) : 0.0;

          lastReportedTimeMs = elapsedMs;
          lastReportedBytes = receivedBytes;

          final fraction = (totalBytes > 0) ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

          yield AiModelDownloadProgress(
            bytesDownloaded: receivedBytes,
            totalBytes: totalBytes,
            fraction: fraction,
            speedBytesPerSec: speed,
            statusMessage: 'Downloading offline model weights...',
          );
        }
      }

      await sink.flush();
      await sink.close();

      // 3. Verify SHA-256 Checksum
      yield AiModelDownloadProgress(
        bytesDownloaded: receivedBytes,
        totalBytes: totalBytes,
        fraction: 0.99,
        speedBytesPerSec: 0,
        statusMessage: 'Verifying SHA-256 integrity checksum...',
      );

      final digest = await _computeFileSha256(partFile);
      if (model.expectedSha256.isNotEmpty && digest.toLowerCase() != model.expectedSha256.toLowerCase()) {
        await partFile.delete();
        throw AiChecksumException(model.expectedSha256, digest);
      }

      // 4. Atomically commit final model
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await partFile.rename(targetPath);

      yield AiModelDownloadProgress(
        bytesDownloaded: totalBytes,
        totalBytes: totalBytes,
        fraction: 1.0,
        speedBytesPerSec: 0,
        statusMessage: 'Model verified and ready for offline use!',
      );
    } catch (e) {
      if (cancel.isCancelled) {
        throw const AiCancelledException();
      }
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  /// Calculates SHA-256 digest of a file stream without loading the whole file into RAM
  static Future<String> _computeFileSha256(File file) async {
    final output = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(output);

    await for (final chunk in file.openRead()) {
      input.add(chunk);
    }
    input.close();

    return output.events.single.toString();
  }

  /// Deletes a locally downloaded model file to reclaim storage
  static Future<void> deleteModel(AiModelDescriptor model) async {
    final path = await getModelPath(model);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    final partFile = File('$path.part');
    if (await partFile.exists()) {
      await partFile.delete();
    }
  }
}
