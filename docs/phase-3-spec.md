# Phase 3 Specification — Real-Time Preview Engine

## 1. Objectives
1. Implement the **Timeline Compositor Engine** (`TimelineCompositorService`):
   - Query visible video and image clips at any given timestamp `T` based on track z-order (upper tracks overlay lower tracks).
   - Calculate source media frame seek positions: `sourcePositionMs = sourceInMs + ((T - startTimeMs) * speed)`.
   - Aggregate all concurrently active audio tracks, applying clip volume, track mute state, and speed pitch factors.
2. Build the **Synchronous Playback Clock** (`PlaybackClockService`):
   - 60fps high-precision ticker generating continuous timecode progression during playback.
   - Real-time synchronization between the preview viewport, timeline playhead, and audio engine.
3. Build the **Multi-Aspect Ratio Canvas Viewport**:
   - Support standard industry aspect ratios: `16:9` (YouTube / TV), `9:16` (TikTok / Reels / Shorts), `1:1` (Instagram Feed), `4:5` (Social Portrait), and `21:9` (Cinemascope).
   - Dynamic letterboxing and pillarboxing with smooth layout animation.
   - Action-safe & Title-safe grid overlays (90% and 80% guide lines) for professional framing.

---

## 2. Public Interface Contracts (Frozen)

### 2.1 `CompositorFrame`
```dart
class CompositorFrame {
  final int timestampMs;
  final Clip? primaryVideoClip;
  final MediaAsset? primaryAsset;
  final int sourceFrameTimeMs;
  final List<ActiveAudioSource> activeAudioSources;
  final List<Clip> activeOverlays;
  final AspectRatioPreset aspectRatio;
}
```

### 2.2 `TimelineCompositorService`
- `CompositorFrame evaluateFrame(Project project, int timestampMs, {AspectRatioPreset aspectRatio})`

### 2.3 `PlaybackClockService`
- `void start({required int startPositionMs, required int maxDurationMs, double playbackRate = 1.0})`
- `void pause()`
- `void seek(int targetPositionMs)`
- `Stream<int> get tickStream`

---

## 3. Edge Cases & Resilience
- **Playhead past project end:** Automatically pauses playback and wraps to 0 or stops at duration boundary.
- **Empty timeline gaps:** Evaluates to a clean black frame without throwing null exceptions.
- **Multiple overlapping video tracks:** Evaluates highest-priority non-hidden track for video rendering.
- **Rapid scrubbing:** Throttles continuous seeks to maintain steady 60fps UI responsiveness without thread stalling.

---

## 4. Acceptance Criteria
- [x] Compositor accurately calculates `sourceFrameTimeMs` factoring in clip `startTimeMs`, `sourceInMs`, and `speed`.
- [x] Multi-track audio aggregation respects track mute and clip volume properties.
- [x] Real-time clock synchronizes playhead and viewport smoothly at 60fps.
- [x] Aspect ratio switching (16:9, 9:16, 1:1, 21:9) dynamically updates viewport geometry with safe guides.
- [x] Unit tests verify compositor frame evaluation across single and multi-track scenarios.
