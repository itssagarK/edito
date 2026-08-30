import 'package:equatable/equatable.dart';

enum ExportStatus {
  idle,
  preparing,
  rendering,
  completed,
  failed,
  cancelled,
}

class ExportProgress extends Equatable {
  final ExportStatus status;
  final double progress; // 0.0 to 1.0
  final int currentFrame;
  final int totalFrames;
  final int elapsedTimeMs;
  final int etaRemainingMs;
  final String statusMessage;
  final String? outputPath;
  final String? errorMessage;
  final double? outputFileSizeMb;

  const ExportProgress({
    this.status = ExportStatus.idle,
    this.progress = 0.0,
    this.currentFrame = 0,
    this.totalFrames = 0,
    this.elapsedTimeMs = 0,
    this.etaRemainingMs = 0,
    this.statusMessage = 'Ready',
    this.outputPath,
    this.errorMessage,
    this.outputFileSizeMb,
  });

  int get percentage => (progress * 100).clamp(0, 100).toInt();

  ExportProgress copyWith({
    ExportStatus? status,
    double? progress,
    int? currentFrame,
    int? totalFrames,
    int? elapsedTimeMs,
    int? etaRemainingMs,
    String? statusMessage,
    String? outputPath,
    String? errorMessage,
    double? outputFileSizeMb,
  }) {
    return ExportProgress(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentFrame: currentFrame ?? this.currentFrame,
      totalFrames: totalFrames ?? this.totalFrames,
      elapsedTimeMs: elapsedTimeMs ?? this.elapsedTimeMs,
      etaRemainingMs: etaRemainingMs ?? this.etaRemainingMs,
      statusMessage: statusMessage ?? this.statusMessage,
      outputPath: outputPath ?? this.outputPath,
      errorMessage: errorMessage ?? this.errorMessage,
      outputFileSizeMb: outputFileSizeMb ?? this.outputFileSizeMb,
    );
  }

  @override
  List<Object?> get props => [
        status,
        progress,
        currentFrame,
        totalFrames,
        elapsedTimeMs,
        etaRemainingMs,
        statusMessage,
        outputPath,
        errorMessage,
        outputFileSizeMb,
      ];
}
