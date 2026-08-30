# 🎬 Edito — Pro Video Editor for Android

[![Build & Release Android APK](https://github.com/OWNER/Edito/actions/workflows/build-apk.yml/badge.svg)](https://github.com/OWNER/Edito/actions/workflows/build-apk.yml)
[![Release](https://img.shields.io/github/v/release/OWNER/Edito?color=6C5CE7&label=Latest%20APK)](https://github.com/OWNER/Edito/releases/latest)
[![Platform](https://img.shields.io/badge/Platform-Android%20%28SDK%2024%2B%29-00CEC9.svg)](https://flutter.dev)

**Edito** is a high-performance, industry-grade mobile video editor built for Android. Designed with a modular architecture, hardware-accelerated preview rendering, on-device AI audio enhancement, and a deterministic FFmpeg export pipeline.

---

## 📱 Features & Roadmap

| Phase | Milestone | Status | Description |
|---|---|:---:|---|
| **Phase 0** | **Project Skeleton & CI/CD** | 🟢 Complete | Flutter scaffold, dark cinematic UI, Riverpod state, and automated GitHub Actions APK builds. |
| **Phase 1** | **Media Import & Data Models** | 🟡 Next | Video/Audio/Image import, thumbnail generation, metadata extraction, JSON project persistence. |
| **Phase 2** | **Timeline UI & Multi-Track Editing** | ⚪ Pending | Multi-track timeline, playhead scrubbing, split/trim at playhead, snap-to-grid, reordering. |
| **Phase 3** | **Real-Time Preview Engine** | ⚪ Pending | Android `MediaCodec` + `SurfaceTexture` compositor, synchronous audio/video playback. |
| **Phase 4** | **Transitions & Speed Ramping** | ⚪ Pending | Cross-dissolve, wipe, slide GPU shader transitions, time-remapping with pitch correction. |
| **Phase 5** | **Color Grading & 3D LUTs** | ⚪ Pending | GLSL color pipeline: exposure, contrast, saturation, curves, HSL, and `.cube` 3D LUTs. |
| **Phase 6** | **Audio Mixing & AI Voice Clean** | ⚪ Pending | Per-track volume envelope, ducking, on-device AI voice noise removal via ONNX Runtime. |
| **Phase 7** | **Text, Titles & Overlays** | ⚪ Pending | Motion titles, sticker/image overlays with position, scale, and opacity keyframe animation. |
| **Phase 8** | **FFmpeg Export Pipeline** | ⚪ Pending | Multi-format render engine (1080p / 4K, H.264/H.265), background export with progress. |
| **Phase 9** | **Stability & Undo/Redo Engine** | ⚪ Pending | Global undo/redo stack, proxy editing for 4K media, performance benchmarking. |
| **Phase 10** | **Release & Distribution** | ⚪ Pending | Production signing, tag-based automated GitHub Releases with instant APK download link. |

---

## 🏗️ Architecture

```
                               ┌─────────────────────────────┐
                               │     Flutter UI Surface      │
                               │  (Timeline, Toolbar, Theme) │
                               └──────────────┬──────────────┘
                                              │
                      ┌───────────────────────┴───────────────────────┐
                      ▼                                               ▼
         ┌───────────────────────────┐                 ┌───────────────────────────┐
         │   Real-Time Preview       │                 │   Deterministic Export    │
         │   • Android MediaCodec    │                 │   • FFmpeg Render Graph   │
         │   • SurfaceTexture / GL   │                 │   • 1080p / 4K MP4        │
         │   • Zero-latency scrub    │                 │   • Multi-pass encode     │
         └─────────────┬─────────────┘                 └─────────────┬─────────────┘
                       │                                             │
                       └──────────────────────┬──────────────────────┘
                                              ▼
                               ┌─────────────────────────────┐
                               │    On-Device AI Engine      │
                               │  (ONNX Runtime Mobile)      │
                               │  • AI Voice Enhancement     │
                               │  • Noise Suppression        │
                               └─────────────────────────────┘
```

---

## 🚀 Getting Started

### Local Development

1. **Clone the repository:**
   ```bash
   git clone https://github.com/OWNER/Edito.git
   cd Edito
   ```

2. **Install Flutter packages:**
   ```bash
   flutter pub get
   ```

3. **Run on Android Emulator / Physical Device:**
   ```bash
   flutter run
   ```

### 📦 Automated Cloud Builds (No Local Flutter Setup Needed)

Every push to `main` builds a debug APK automatically in GitHub Actions.  
To build and publish a signed release APK:
```bash
git tag v1.0.0
git push origin v1.0.0
```
GitHub Actions will automatically build the APK and attach it directly to the GitHub Release!
