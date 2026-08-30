# Phase 5 Specification — Pro Color Grading & 3D LUT Pipeline

## 1. Objectives
1. Implement a professional, non-destructive **Color Grading Parameter Engine**:
   - **Basic Adjustments:** Exposure (-2.0 to +2.0 EV), Contrast (0.5 to 1.5), Saturation (0.0 to 2.0), Brightness (-1.0 to +1.0), Highlights/Shadows, Temperature (Cool Blue ↔ Warm Orange), and Tint (Green ↔ Magenta).
   - **8-Channel HSL Selective Color Engine:** Dedicated Hue, Saturation, and Luminance controls for Red, Orange, Yellow, Green, Cyan, Blue, Purple, and Magenta.
   - **RGB Tone Curves:** Interactive 4-channel spline curves (RGB Master, Red, Green, Blue) with draggable control points.
   - **3D LUT (.cube) Pipeline:** Built-in cinematic look presets (*Teal & Orange*, *Vintage Kodak 500T*, *Moody Cyberpunk*, *Golden Hour*, *Film Noir B&W*) with adjustable 0–100% blend intensity.
2. Build the **Color Filter Compiler** (`ColorFilterCompilerService`):
   - Compiles grading parameters into Flutter `ColorFilter` matrices for real-time viewport preview.
   - Generates exact FFmpeg filter strings (`eq`, `colorbalance`, `curves`, `lut3d`) for Phase 8 export.
3. Provide an intuitive **Color & LUT Suite Modal** in the editor with an instant **Before / After** comparison view.

---

## 2. Public Interface Contracts (Frozen)

### 2.1 `ColorGradingConfig`
```dart
class ColorGradingConfig {
  final double exposure;          // -2.0 to +2.0 (default 0.0)
  final double contrast;          // 0.5 to 1.5 (default 1.0)
  final double saturation;        // 0.0 to 2.0 (default 1.0)
  final double brightness;        // -1.0 to +1.0 (default 0.0)
  final double temperature;       // -100 to +100 (default 0.0)
  final double tint;              // -100 to +100 (default 0.0)
  final double highlights;        // -1.0 to +1.0 (default 0.0)
  final double shadows;           // -1.0 to +1.0 (default 0.0)
  final double vignette;          // 0.0 to 1.0 (default 0.0)
  final LutPreset activeLut;      // Preset enum or custom .cube
  final double lutIntensity;      // 0.0 to 1.0 (default 1.0)
  final Map<String, HslShift> hsl;// 8 color channels
  final ToneCurves toneCurves;    // RGB splines
}
```

### 2.2 `ColorFilterCompilerService`
- `ColorFilter compileColorFilter(ColorGradingConfig config)`
- `String generateFFmpegFilter(ColorGradingConfig config)`

---

## 3. UI Behavior
1. User selects a clip and taps **"Color & LUT"** in the toolbar.
2. The `ColorGradingSheet` modal opens with 4 tabs:
   - **Adjustments:** Exposure, Contrast, Saturation, Temperature, Highlights/Shadows.
   - **Cinematic LUTs:** Visual cards with live thumbnail look previews and blend intensity slider.
   - **HSL Colors:** Color chips (Red, Orange, Yellow, Green, Cyan, Blue, Purple, Magenta) with Hue/Sat/Lum sliders.
   - **Curves:** Interactive grid canvas allowing touch-dragging control points.
3. Adjustments update the active clip non-destructively in real time.

---

## 4. Acceptance Criteria
- [x] All color grading parameters serialize/deserialize seamlessly in `Clip.toJson()`.
- [x] ColorFilterCompiler generates valid 4x5 color matrices for real-time viewport rendering.
- [x] FFmpeg filter compiler outputs exact `eq`, `colorbalance`, and `curves` command strings for export.
- [x] Interactive Tone Curve Editor allows adding and dragging curve control points.
- [x] Unit tests verify color matrix calculations, LUT preset blending, and FFmpeg filter generation.
