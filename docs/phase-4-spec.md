# Phase 4 Specification — Transitions & Non-Linear Speed Ramping

## 1. Objectives
1. Implement the **Video Transitions Pipeline** (`TransitionCompilerService`):
   - Support seamless transitions between adjacent clips on the video track:
     - `Cross Dissolve` (fade blend between two video streams)
     - `Fade to Black` / `Fade to White`
     - `Wipe Left` / `Wipe Right`
     - `Slide Up` / `Slide Down`
     - `Zoom In`
   - Configurable duration per transition (200ms to 2000ms).
   - Interactive cut-point transition badge on the timeline between adjacent clips.
2. Implement the **Speed Ramping & Curve Engine** (`SpeedRampingService`):
   - **Constant Speed:** 0.1x to 10.0x with seamless duration stretching.
   - **Non-Linear Speed Curve Presets:**
     - *Montage Ramp* (Fast 2x ➔ Slow 0.5x ➔ Fast 2x)
     - *Hero Slow-Mo* (Normal 1x ➔ Ultra Slow 0.3x ➔ Normal 1x)
     - *Bullet Time* (Normal 1x ➔ Matrix Drop 0.1x ➔ Normal 1x)
     - *Jump Cut Rush* (Fast 3x ➔ Normal 1x)
   - **Pitch Correction:** Preserves natural audio voice pitch (`atempo` / `rubberband`) during slow-mo and fast-forward.
3. Build the **Export Compiler** for Transitions & Speed:
   - Compiles transition overlaps into FFmpeg `xfade` filter graphs (`xfade=transition=fade:duration=...:offset=...`).
   - Compiles speed curves into dynamic `setpts` and `atempo` chains.

---

## 2. Public Interface Contracts (Frozen)

### 2.1 `TransitionConfig` & `SpeedCurveConfig`
```dart
class TransitionConfig {
  final TransitionType type;
  final int durationMs; // 200 to 2000ms
}

class SpeedCurveConfig {
  final SpeedCurveType type;
  final double constantSpeed;
  final bool enablePitchCorrection;
  final List<CurvePoint> curvePoints;
}
```

### 2.2 `TransitionCompilerService`
- `String generateFFmpegXFade(TransitionConfig config, {required double offsetSec})`

### 2.3 `SpeedRampingService`
- `int calculateSourceOffset(Clip clip, int offsetInTimelineMs)`

---

## 3. Acceptance Criteria
- [x] Transition configs serialize/deserialize cleanly within `Clip.toJson()`.
- [x] Timeline displays interactive transition cut badges between adjacent clips.
- [x] FFmpeg command builder compiles `xfade` transition graphs and speed `setpts` filters accurately.
- [x] Speed ramping sheet offers constant multiplier and dynamic curve presets with pitch correction.
- [x] Unit tests verify `xfade` syntax generation, speed curve evaluations, and pitch preservation math.
