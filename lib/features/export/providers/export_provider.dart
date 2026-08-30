import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../editor/providers/editor_provider.dart';
import '../models/export_preset.dart';
import '../models/export_status.dart';
import '../services/export_render_service.dart';

class ExportState {
  final ExportConfiguration configuration;
  final ExportProgress progress;

  const ExportState({
    this.configuration = const ExportConfiguration(),
    this.progress = const ExportProgress(),
  });

  ExportState copyWith({
    ExportConfiguration? configuration,
    ExportProgress? progress,
  }) {
    return ExportState(
      configuration: configuration ?? this.configuration,
      progress: progress ?? this.progress,
    );
  }
}

final exportRenderServiceProvider = Provider<ExportRenderService>((ref) {
  final service = ExportRenderService();
  ref.onDispose(() => service.dispose());
  return service;
});

final exportProvider = StateNotifierProvider<ExportNotifier, ExportState>((ref) {
  final service = ref.watch(exportRenderServiceProvider);
  return ExportNotifier(service, ref);
});

class ExportNotifier extends StateNotifier<ExportState> {
  final ExportRenderService _renderService;
  final Ref _ref;

  ExportNotifier(this._renderService, this._ref) : super(const ExportState()) {
    _renderService.progressStream.listen((progress) {
      state = state.copyWith(progress: progress);
    });
  }

  void setResolution(ExportResolution resolution) {
    state = state.copyWith(
      configuration: state.configuration.copyWith(resolution: resolution),
    );
  }

  void setFramerate(ExportFramerate framerate) {
    state = state.copyWith(
      configuration: state.configuration.copyWith(framerate: framerate),
    );
  }

  void setCodec(ExportCodec codec) {
    state = state.copyWith(
      configuration: state.configuration.copyWith(codec: codec),
    );
  }

  void setQuality(ExportQuality quality) {
    state = state.copyWith(
      configuration: state.configuration.copyWith(quality: quality),
    );
  }

  Future<String?> runExport() async {
    final project = _ref.read(editorProvider).project;
    if (project == null) return null;

    final result = await _renderService.startExport(project, state.configuration);
    return result;
  }

  void cancelExport() {
    _renderService.cancelExport();
  }
}
