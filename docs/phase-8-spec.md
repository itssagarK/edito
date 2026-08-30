# Phase 8 Specification — FFmpeg Export Pipeline

## 1. Objectives
1. Implement the **Deterministic FFmpeg Graph Builder** (`FFmpegCommandBuilder`):
   - Translate the non-destructive project data model (multi-track cuts, trims, clip speeds, aspect ratio letterboxing, AI audio filters, and volume envelopes) into an executable FFmpeg filter graph.
   - Support multi-clip concatenation (`concat`), time-remapping (`setpts`, `atempo`), video scaling (`scale`, `pad`), and multi-track audio mixing (`amix`).
2. Build the **Export Configuration Engine**:
   - Resolutions: `4K UHD (3840x2160)`, `1080p FHD (1920x1080)`, `720p HD (1280x720)`.
   - Frame Rates: `24 FPS (Cinematic)`, `30 FPS (Standard)`, `60 FPS (Smooth)`.
   - Video Codecs: `H.264 (libx264 - Universal)` and `H.265 (libx265 - HEVC)`.
   - Quality / CRF Presets: Standard (CRF 23), High (CRF 18), Ultra (CRF 14).
   - Real-time estimated output file size calculation.
3. Build the **Background Export Runner & Progress UI**:
   - Asynchronous render pipeline emitting live progress percentage (0–100%), elapsed time, and ETA.
   - Graceful cancellation support.
   - Post-export completion modal with file stats and sharing actions.

---

## 2. Public Interface Contracts (Frozen)

### 2.1 `ExportConfiguration`
```dart
class ExportConfiguration {
  final ExportResolution resolution;
  final ExportFramerate framerate;
  final ExportCodec codec;
  final ExportQuality quality;
  final AspectRatioPreset aspectRatio;
  final String outputPath;
}
```

### 2.2 `FFmpegCommandBuilder`
- `List<String> buildArguments(Project project, ExportConfiguration config)`
- `String buildCommandString(Project project, ExportConfiguration config)`
- `double estimateFileSizeMb(Project project, ExportConfiguration config)`

### 2.3 `ExportRenderService`
- `Future<String> startExport(Project project, ExportConfiguration config)`
- `Stream<ExportProgress> get progressStream`
- `void cancelExport()`

---

## 3. Acceptance Criteria
- [x] FFmpeg argument list accurately represents all clip in/out points, speeds, and volumes.
- [x] On-device AI voice filters (`afftdn`, `highpass`, `equalizer`) and auto-ducking are baked into audio stream.
- [x] Estimated file size calculation matches target bitrates accurately.
- [x] Export modal allows selecting resolution, framerate, quality, and codec.
- [x] Progress dialog tracks real-time render percentage and ETA.
- [x] Unit tests verify command argument generation across single and multi-track projects.
