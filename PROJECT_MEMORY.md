# PROJECT_MEMORY.md — Edito Architecture & System Blueprint

> **Status:** Phase 7 In Progress (Text, Motion Titles & Animated Keyframe Overlays)  
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

## 2. Frozen Interface Contracts

### 2.1 Overlays Pipeline (`lib/features/overlays/`)
- `TextOverlayConfig`: Schema for motion text, fonts, colors, background plates, $(X, Y)$ position, scale, rotation, and animation presets.
- `Keyframe`: Animation keyframe point for multi-parameter interpolation over time.
- `OverlayCompilerService`: Live preview animator and FFmpeg `drawtext` command builder.

---

## 3. Directory Layout

```
Edito/
├── .github/
│   └── workflows/
│       └── build-apk.yml          # Automated CI/CD for debug & release APKs
├── docs/
│   ├── phase-0-spec.md            # Scaffold & CI spec (Complete)
│   ├── phase-1-spec.md            # Media import & data model spec (Complete)
│   ├── phase-2-spec.md            # Timeline UI & multi-track editing spec (Complete)
│   ├── phase-3-spec.md            # Real-time preview engine spec (Complete)
│   ├── phase-4-spec.md            # Transitions & speed ramping spec (Complete)
│   ├── phase-5-spec.md            # Color grading & 3D LUT spec (Complete)
│   ├── phase-6-spec.md            # Audio tools & AI voice enhancement spec (Complete)
│   ├── phase-7-spec.md            # Text & motion overlays spec (Active)
│   ├── phase-8-spec.md            # FFmpeg export pipeline spec (Complete)
│   └── ...
├── lib/
│   ├── core/
│   │   ├── constants/             # App dimensions, strings, asset paths
│   │   ├── theme/                 # Dark cinematic UI theme & design system
│   │   └── utils/                 # Timecode formatting, file helpers
│   ├── features/
│   │   ├── home/                  # Project browser & new project launcher
│   │   ├── editor/                # Editor shell, playback controls & toolbar
│   │   ├── media/                 # Media picker, thumbnail cache & metadata probing
│   │   ├── project/               # Project storage & state repository
│   │   ├── timeline/              # Multi-track timeline, interactive gestures, trimming & split
│   │   ├── preview/               # Real-time compositor, playback clock & multi-aspect ratio canvas
│   │   ├── transitions/           # Cross-dissolve, wipe, fade, slide & xfade compiler
│   │   ├── speed/                 # Speed ramping, bezier curve presets & pitch correction
│   │   ├── color_grading/         # LUTs, HSL 8-channel, tone curves & color compiler
│   │   ├── audio/                 # AI voice enhancer, noise reduction, ducking & waveform rendering
│   │   ├── overlays/              # Text titles, keyframe animator & drawtext compiler
│   │   ├── export/                # FFmpeg graph builder, render progress & MP4 output
│   │   └── ...
│   ├── models/
│   │   ├── project.dart           # Root project schema
│   │   ├── track.dart             # Video / Audio / Overlay track definitions
│   │   ├── clip.dart              # Slice, in/out points, textOverlay, keyframes, colorGrading, audioEffects
│   │   └── media_asset.dart       # Raw file references & metadata cache
│   └── main.dart                  # Application entry point
├── pubspec.yaml                   # Dependencies & asset manifests
└── PROJECT_MEMORY.md              # Living architecture document
```

---

## 4. Phase Delivery Roadmap

- **Phase 0:** Project Skeleton, CI/CD Pipeline & Home Shell 🟢 *(Done)*
- **Phase 1:** Media Import, Thumbnail Caching & Project Data Model 🟢 *(Done)*
- **Phase 2:** Multi-Track Timeline UI, Scrubbing, Trim & Split 🟢 *(Done)*
- **Phase 3:** Real-Time Preview Compositor (Sync Audio/Video) 🟢 *(Done)*
- **Phase 4:** Transitions & Speed Ramping (Time Remapping) 🟢 *(Done)*
- **Phase 5:** GLSL Color Grading & 3D LUT Pipeline 🟢 *(Done)*
- **Phase 6:** Audio Mixing & On-Device AI Voice Enhancement 🟢 *(Done)*
- **Phase 8:** FFmpeg Export Pipeline (Multi-format, 4K/1080p) 🟢 *(Done)*
- **Phase 7:** Text, Titles & Animated Keyframe Overlays 🟡 *(Active)*
- **Phase 9:** Performance Optimization, Proxy Rendering & Undo/Redo ⚪
- **Phase 10:** Production Release & Distribution ⚪
