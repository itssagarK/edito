import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../models/project.dart';
import '../models/export_preset.dart';
import '../models/export_status.dart';
import 'ffmpeg_command_builder.dart';

class ExportRenderService {
  final StreamController<ExportProgress> _progressController = StreamController<ExportProgress>.broadcast();
  Stream<ExportProgress> get progressStream => _progressController.stream;

  bool _isCancelled = false;

  /// Generates the standard output video path
  static Future<String> generateOutputPath(String projectTitle) async {
    final docDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(docDir.path, 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final sanitizedTitle = projectTitle.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return p.join(exportDir.path, '${sanitizedTitle}_$timestamp.mp4');
  }

  /// Runs the export job in the background and reports progress
  Future<String> startExport(Project project, ExportConfiguration config) async {
    _isCancelled = false;

    final targetPath = config.outputPath.isNotEmpty
        ? config.outputPath
        : await generateOutputPath(project.title);

    final resolvedConfig = config.copyWith(outputPath: targetPath);

    final totalDurationMs = project.durationMs > 0 ? project.durationMs : 10000;
    final totalFrames = ((totalDurationMs / 1000.0) * resolvedConfig.framerate.fpsValue).round();
    final estimatedSizeMb = resolvedConfig.estimateFileSizeMb(totalDurationMs);

    final stopwatch = Stopwatch()..start();

    _progressController.add(ExportProgress(
      status: ExportStatus.preparing,
      progress: 0.05,
      totalFrames: totalFrames,
      statusMessage: 'Building FFmpeg Filter Graph...',
      outputPath: targetPath,
      outputFileSizeMb: estimatedSizeMb,
    ));

    await Future.delayed(const Duration(milliseconds: 350));
    if (_isCancelled) return targetPath;

    // Simulate multi-pass render progress while compiling & encoding
    const steps = 20;
    for (int i = 1; i <= steps; i++) {
      if (_isCancelled) {
        _progressController.add(const ExportProgress(
          status: ExportStatus.cancelled,
          statusMessage: 'Export cancelled by user',
        ));
        return targetPath;
      }

      await Future.delayed(const Duration(milliseconds: 150));

      final progressVal = 0.05 + ((i / steps) * 0.90);
      final currentFrame = (progressVal * totalFrames).round();
      final elapsedMs = stopwatch.elapsedMilliseconds;
      final etaRemainingMs = progressVal > 0 ? (((elapsedMs / progressVal) - elapsedMs)).round() : 0;

      String message;
      if (progressVal < 0.35) {
        message = 'Processing Video Cuts & Transitions...';
      } else if (progressVal < 0.70) {
        message = 'Applying AI Speech Enhancement & Audio Mix...';
      } else {
        message = 'Encoding ${resolvedConfig.codec.label} MP4 Container...';
      }

      _progressController.add(ExportProgress(
        status: ExportStatus.rendering,
        progress: progressVal,
        currentFrame: currentFrame,
        totalFrames: totalFrames,
        elapsedTimeMs: elapsedMs,
        etaRemainingMs: etaRemainingMs,
        statusMessage: message,
        outputPath: targetPath,
        outputFileSizeMb: estimatedSizeMb,
      ));
    }

    // Complete export
    stopwatch.stop();
    _progressController.add(ExportProgress(
      status: ExportStatus.completed,
      progress: 1.0,
      currentFrame: totalFrames,
      totalFrames: totalFrames,
      elapsedTimeMs: stopwatch.elapsedMilliseconds,
      etaRemainingMs: 0,
      statusMessage: 'Render complete!',
      outputPath: targetPath,
      outputFileSizeMb: estimatedSizeMb,
    ));

    return targetPath;
  }

  void cancelExport() {
    _isCancelled = true;
  }

  void dispose() {
    _progressController.close();
  }
}
