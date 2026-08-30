# PROJECT_MEMORY.md — Edito Architecture & System Blueprint

> **Status:** Phase 0 Active (Project Foundation & CI/CD Pipeline)  
> **Target:** High-performance, industry-grade Android Video Editor APK (CapCut / VN tier architecture)

---

## 1. Core Architecture Principles

1. **Modular Phase-by-Phase Construction:**  
   Every feature lives in an isolated module with frozen public interfaces (`/lib/features/<feature_name>`).
2. **Dual-Engine Model:**
   - **Preview Engine:** Lightweight native Android `MediaCodec` + `SurfaceTexture` / OpenGL ES compositor for zero-latency timeline scrubbing and real-time playback.
   - **Export Engine:** FFmpeg pipeline (`ffmpeg_kit_flutter` / native `libavcodec`) executing the frozen timeline graph for deterministic, high-quality multi-pass export (1080p/4K, H.264/H.265).
3. **Non-Destructive Project State:**  
   Edits (cuts, trims, transitions, color grading LUTs/curves, audio filters) are stored as JSON-serializable parameter graphs. Source media assets are never modified.
4. **Offline-First AI Processing:**  
   AI speech enhancement and background noise suppression run on-device via ONNX Runtime Mobile / TFLite (DeepFilterNet / RNNoise), eliminating cloud latency and privacy concerns.
5. **Automated CI/CD Delivery:**  
   Every GitHub release tag triggers GitHub Actions to produce release-signed APKs with download artifacts published automatically.

---

## 2. Tech Stack Definition

| Component | Technology | Rationale |
|---|---|---|
| **UI Framework** | Flutter (Dart 3.x) | Fast UI development, fluid 60/120fps timeline rendering, cross-platform portability. |
| **State Management** | `flutter_riverpod` (v2.x) | Type-safe, reactive, highly testable state graph with zero boilerplate leak. |
| **Preview Renderer** | Native Android `MediaCodec` + GLSL / `flutter_gl` | Hardware-accelerated real-time frame playback without CPU decoding bottleneck. |
| **Export Engine** | `ffmpeg_kit_flutter` (Full GPL) | Comprehensive filter graph support for transitions, LUTs, audio mixing, text burn-in. |
| **Audio Processing** | ONNX Runtime Mobile (`onnxruntime`) | On-device AI voice enhancement, noise reduction, and ducking. |
| **Color Grading** | GLSL Shaders (Exposure, Curves, HSL, 3D LUTs) | Real-time GPU color transformation mapped directly into FFmpeg filter chain on export. |
| **CI / Build Pipeline** | GitHub Actions | Automated lint, test, debug APK generation on push, and signed APK release on tags. |

---

## 3. Directory Layout

```
Edito/
├── .github/
│   └── workflows/
│       └── build-apk.yml          # Automated CI/CD for debug & release APKs
├── docs/
│   ├── phase-0-spec.md            # Scaffold & CI spec
│   ├── phase-1-spec.md            # Media import & data model spec
│   └── ...
├── android/                       # Native Android harness & NDK/MediaCodec plugins
│   ├── app/
│   └── gradle/
├── lib/
│   ├── core/
│   │   ├── constants/             # App dimensions, strings, asset paths
│   │   ├── theme/                 # Dark cinematic UI theme & design system
│   │   ├── routing/               # Navigation router
│   │   └── utils/                 # Timecode formatting, file helpers
│   ├── features/
│   │   ├── home/                  # Project browser & new project launcher
│   │   ├── editor/                # Editor shell, playback controls & toolbar
│   │   ├── timeline/              # Multi-track timeline & clip manipulation
│   │   ├── preview/               # Video compositor & GL surface view
│   │   ├── color_grading/         # LUTs, HSL, curves & color adjustments
│   │   ├── audio/                 # Waveforms, volume envelope & AI voice enhancer
│   │   └── export/                # Export settings, render progress & MP4 output
│   ├── models/
│   │   ├── project.dart           # Root project schema
│   │   ├── track.dart             # Video / Audio / Overlay track definitions
│   │   ├── clip.dart              # Slice, in/out points, speed, transforms
│   │   └── media_asset.dart       # Raw file references & metadata cache
│   └── main.dart                  # Application entry point
├── pubspec.yaml                   # Dependencies & asset manifests
└── PROJECT_MEMORY.md              # Living architecture document
```

---

## 4. Phase Delivery Roadmap

- **Phase 0:** Project Skeleton, CI/CD Pipeline & Home Shell *(Current)*
- **Phase 1:** Media Import, Thumbnail Caching & Project Data Model
- **Phase 2:** Multi-Track Timeline UI, Scrubbing, Trim & Split
- **Phase 3:** Real-Time Preview Compositor (Sync Audio/Video)
- **Phase 4:** Transitions & Speed Ramping (Time Remapping)
- **Phase 5:** GLSL Color Grading & 3D LUT Pipeline
- **Phase 6:** Audio Mixing & On-Device AI Voice Enhancement
- **Phase 7:** Text, Titles & Animated Keyframe Overlays
- **Phase 8:** FFmpeg Export Pipeline (Multi-format, 4K/1080p)
- **Phase 9:** Performance Optimization, Proxy Rendering & Undo/Redo
- **Phase 10:** Production Release & Distribution
