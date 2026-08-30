# Phase 10 Specification — Production Release & Distribution (v1.0.0)

## 1. Objectives
1. Tag and release production version **`v1.0.0`** of the **Edito** Android Video Editor.
2. Trigger the automated **GitHub Actions CI/CD Pipeline** ([.github/workflows/build-apk.yml](file:///C:/Users/Mini-PC/Desktop/projects/Edito/.github/workflows/build-apk.yml)) to:
   - Set up Java 17 & Flutter SDK on clean Ubuntu runners.
   - Run automated unit test verification across all modules.
   - Build optimized production Android APK (`build/app/outputs/flutter-apk/app-release.apk`).
   - Create a GitHub Release with auto-generated release notes and attach the downloadable APK binary.

---

## 2. Release Summary (v1.0.0)

- **Architecture:** Dual-Engine (Real-time preview compositor + Deterministic FFmpeg export graph).
- **State Engine:** Flutter Riverpod non-destructive project state with 50-level Undo/Redo history stack.
- **Media Engine:** Unified Video / Audio / Image picker, background metadata probing, and thumbnail caching.
- **Timeline Engine:** Multi-track timeline, pinch-to-zoom (0.2x–5.0x), split, trim handles, magnetic snapping (150ms), and ripple delete.
- **Preview Engine:** 60 FPS playback clock, multi-aspect ratio canvas (16:9, 9:16, 1:1, 4:5, 21:9), action & title safe area guides.
- **Transitions:** Cross-dissolve, fade to black/white, wipe, slide, and zoom with custom durations.
- **Color Grading:** Exposure, contrast, temperature/tint, 8-channel HSL color wheels, tone curves, and 3D LUT presets (*Teal & Orange*, *Vintage Kodak*, *Moody Cyber*, *Golden Hour*, *Film Noir*).
- **On-Device AI Audio:** AI speech de-noiser & voice clarity boost, dynamic auto-ducking, waveform generator, volume booster (up to 200%), and A/B comparison.
- **Motion Typography:** Font picker, text animations (*Typewriter*, *Fade In*, *Slide Up*, *Pop Scale*, *Shimmer*), keyframe animation paths, and export drawtext burn-in.
- **FFmpeg Render Engine:** 4K UHD, 1080p FHD, 720p HD @ 24/30/60 FPS, H.264/H.265 (HEVC), background progress dialog with ETA, and instant share sheet.
