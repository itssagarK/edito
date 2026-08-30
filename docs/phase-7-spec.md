# Phase 7 Specification — Text, Motion Titles & Animated Overlays

## 1. Objectives
1. Implement the **Text & Motion Title Engine** (`TextOverlayConfig`):
   - Rich typography controls: Font family (*Inter*, *Bebas Neue*, *JetBrains Mono*, *Montserrat*), size, text color, stroke border, and background plate.
   - Motion Animations: *Fade In*, *Slide Up*, *Typewriter*, *Pop Scale*, and *Bounce*.
   - Viewport placement: Position $(X, Y)$, Scale $(0.2\times–5.0\times)$, Rotation, and Opacity $(0–100\%)$.
2. Implement **Keyframe Animation Engine** (`Keyframe`):
   - Multi-point keyframing for smooth position, scale, and opacity motion paths across the clip duration.
3. Build the **Export Compiler** for Overlays:
   - Translates text overlays into FFmpeg `drawtext` filter graphs (`drawtext=text='...':fontcolor=...:fontsize=...:x=...:y=...:enable='between(t,...)`).
4. Build the **Interactive Text Editor Modal** and preview surface.

---

## 2. Public Interface Contracts (Frozen)

### 2.1 `TextOverlayConfig`
```dart
class TextOverlayConfig {
  final String text;
  final String fontFamily;
  final double fontSize;
  final int textColorHex;
  final int? backgroundColorHex;
  final int? strokeColorHex;
  final double strokeWidth;
  final double positionX; // 0.0 to 1.0 (0.5 = center)
  final double positionY; // 0.0 to 1.0 (0.5 = center)
  final double scale;
  final double rotation;  // degrees
  final double opacity;
  final TextAnimationType animationType;
}
```

### 2.2 `OverlayCompilerService`
- `TextOverlayConfig interpolateAt(Clip clip, int offsetMs)`
- `String generateFFmpegDrawText(Clip clip, TextOverlayConfig config)`

---

## 3. Acceptance Criteria
- [x] Text overlay configuration serializes/deserializes cleanly in `Clip.toJson()`.
- [x] Viewport displays interactive text overlays with live font, color, and positioning.
- [x] Keyframe interpolation smoothly computes intermediate $(X, Y)$ and scale values.
- [x] FFmpeg `drawtext` filter graph compiles correctly for Phase 8 export.
- [x] Unit tests verify text overlay data models and FFmpeg filter compilation.
