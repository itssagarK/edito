# 🎬 Edito — Pro Video Editor for Android

<p align="center">
  <img src="https://raw.githubusercontent.com/itssagarK/edito/main/assets/branding/banner.png" alt="Edito Video Editor Banner" width="100%" onerror="this.style.display='none'" />
</p>

<p align="center">
  <b>A high-performance, industry-grade mobile video editor built for Android.</b><br>
  Engineered with a dual-engine preview compositor, on-device AI voice enhancement, 3D LUT color grading, motion typography, and a deterministic 4K FFmpeg export pipeline.
</p>

<p align="center">
  <a href="https://github.com/itssagarK/edito/actions/workflows/build-apk.yml">
    <img src="https://github.com/itssagarK/edito/actions/workflows/build-apk.yml/badge.svg" alt="Build Status" />
  </a>
  <a href="https://github.com/itssagarK/edito/releases/latest">
    <img src="https://img.shields.io/github/v/release/itssagarK/edito?color=6C5CE7&label=Release%20APK&logo=android" alt="Latest APK" />
  </a>
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Flutter-3.x%20%7C%20Dart%203.x-02569B?logo=flutter" alt="Flutter" />
  </a>
  <a href="https://developer.android.com">
    <img src="https://img.shields.io/badge/Android-SDK%2024%2B%20%28Android%207.0%2B%29-00CEC9?logo=android" alt="Android Support" />
  </a>
  <a href="https://ffmpeg.org">
    <img src="https://img.shields.io/badge/Render%20Engine-FFmpeg%20%7C%204K%20UHD-009688?logo=ffmpeg" alt="FFmpeg Engine" />
  </a>
  <a href="https://github.com/itssagarK/edito/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License" />
  </a>
</p>

---

## 📥 Instant APK Download

Get the official compiled release APK and install it directly on any Android device:

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/itssagarK/edito/releases/download/v1.0.0/app-release.apk">
        <img src="https://img.shields.io/badge/⚡%20DIRECT%20DOWNLOAD-Edito%20v1.0.0%20APK%20(Universal)-6C5CE7?style=for-the-badge&logo=android&logoColor=white" height="42" alt="Download APK" />
      </a>
      <br>
      <sub><b>Target:</b> <code>ARM64-v8a</code>, <code>ARMeabi-v7a</code>, <code>x86_64</code> &nbsp;•&nbsp; <b>Min SDK:</b> Android 7.0+ (API 24+)</sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      📦 <b>Latest Release Notes:</b> <a href="https://github.com/itssagarK/edito/releases/tag/v1.0.0"><b>v1.0.0 Production Release on GitHub</b></a>
    </td>
  </tr>
</table>

---

## 🌟 Key Features

### 🎞️ Multi-Track Non-Linear Timeline
- **Smooth Pinch-to-Zoom:** Zoom seamlessly from high-level bird's-eye view ($0.2\times$) to frame-accurate sample level ($5.0\times$).
- **Frame-Accurate Splitting & Trimming:** Split clips at playhead with zero audio pop; adjust head/tail handles with real-time feedback.
- **Magnetic Snapping Engine:** $150\text{ ms}$ magnetic threshold to automatically align clips to cuts, playhead, and marker boundaries.
- **Track Controls:** Independent Mute, Lock, Hide, Duplicate, and Ripple Delete for Video, Audio, and Overlay tracks.

### ⚡ Real-Time Preview & Compositor
- **Synchronized 60 FPS Engine:** Ultra-low latency playback clock driving continuous playhead synchronization.
- **Multi-Aspect Ratio Presets:** Switch instantly between **16:9** (YouTube/Cinema), **9:16** (Reels/TikTok/Shorts), **1:1** (Square), **4:5** (Instagram Portrait), and **21:9** (Ultra-Wide).
- **Broadcast Safe Guides:** $90\%$ Action Safe and $80\%$ Title Safe broadcast overlay grids with center crosshair.

### 🎨 Pro Color Grading & 3D LUT Pipeline
- **Primary Adjustments:** Exposure ($-2.0$ to $+2.0\text{ EV}$), Contrast, Saturation, Brightness, Highlights, Shadows, Vignette.
- **Color Temperature & Tint:** Kelvin temperature shift (Cool Blue $\leftrightarrow$ Warm Amber) and Tint (Green $\leftrightarrow$ Magenta).
- **8-Channel Selective HSL:** Dedicated Hue, Saturation, and Luminance sliders for Red, Orange, Yellow, Green, Cyan, Blue, Purple, and Magenta.
- **Master RGB Tone Curves:** Interactive 4-channel spline curve editor with draggable touch control points.
- **Cinematic 3D LUT Presets:** Built-in looks with adjustable $0–100\%$ blend intensity:
  - *Teal & Orange (Blockbuster Cinema)*
  - *Vintage Kodak 500T (Retro Analog)*
  - *Moody Cyberpunk (Neon Glow)*
  - *Golden Hour (Sunset Warmth)*
  - *Film Noir (High-Contrast B&W)*

### 🎙️ On-Device AI Voice Enhancement & Audio Tools
- **AI Neural Speech Cleaner:** Removes background hums, traffic noise, room reverberation, and wind noise on-device.
- **Voice Clarity Boost:** Enhances speech presence, crispness, and vocal articulation.
- **Smart Auto-Ducking:** Automatically attenuates background soundtrack volume when dialogue is detected on foreground tracks.
- **Volume Booster:** Amplify quiet audio up to $200\%$ with soft clipping protection.
- **Waveform Visualizer:** Timeline audio amplitude waveform rendering.
- **A/B Comparison:** Instant toggle to preview original vs. enhanced audio.

### ✨ Transitions & Speed Ramping
- **GPU Transitions:** *Cross Dissolve*, *Fade to Black*, *Fade to White*, *Wipe Left*, *Wipe Right*, *Slide Up*, *Slide Down*, and *Zoom In* with custom durations ($0.2\text{s}–2.0\text{s}$).
- **Bezier Speed Ramping Curves:** Dynamic curve presets (*Montage Ramp*, *Hero Slow-Mo*, *Bullet Time*, *Jump Cut Rush*) and constant multipliers ($0.1\times–10\times$).
- **Audio Pitch Correction:** Preserves natural voice pitch (`atempo` / `rubberband`) during slow-mo and fast-motion.

### ✍️ Motion Typography & Keyframe Overlays
- **Rich Text Styling:** Font family picker (*Inter*, *Bebas Neue*, *JetBrains Mono*, *Montserrat*), custom sizing, colors, outlines, and background plates.
- **Text Motion Animations:** *Typewriter Machine*, *Smooth Fade In*, *Slide Up*, *Pop & Scale*, and *Golden Shimmer*.
- **Keyframe Motion Paths:** Multi-point keyframing for position $(X, Y)$, scale, rotation, and opacity animation.

### 🚀 Deterministic FFmpeg 4K Export Pipeline
- **Multi-Resolution:** **4K UHD** ($3840\times2160$), **1080p FHD** ($1920\times1080$), and **720p HD** ($1280\times720$).
- **Custom Framerate:** $24\text{ FPS}$ (Cinematic Film), $30\text{ FPS}$ (Standard Video), $60\text{ FPS}$ (High Motion).
- **Modern Codecs:** Universal **H.264** (`libx264`) and High-Efficiency **H.265 / HEVC** (`libx265`).
- **Live Background Render Dialog:** Frame count indicator, percentage progress bar, and estimated time remaining (ETA).
- **Direct Save & Share:** One-tap export to device gallery and native Android share sheet.

### ⏪ Global Undo / Redo Engine
- **Command-Pattern History:** Stores up to 50 levels of historical project snapshots with LRU memory management.
- **Debounced Auto-Save:** Instant crash recovery with automatic background disk persistence.

---

## 🏗️ System Architecture

```
                      ┌────────────────────────────────────────────────────────┐
                      │                   Edito Android App                    │
                      │           (Flutter 3.x + Riverpod State Graph)         │
                      └───────────────────────────┬────────────────────────────┘
                                                  │
 ┌──────────────────────┬─────────────────────────┼─────────────────────────┬──────────────────────┐
 ▼                      ▼                         ▼                         ▼                      ▼
┌──────────────────┐   ┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐   ┌──────────────────┐
│ Timeline Engine  │   │  Preview Engine  │      │ Pro Color & LUTs │      │ AI Voice Engine  │   │ Motion Overlays  │
│ • Pinch-to-zoom  │   │ • 60 FPS Clock   │      │ • 3D LUT Presets │      │ • Speech Cleaner │   │ • Text Titles    │
│ • Trim Handles   │   │ • Multi-Aspect   │      │ • 8-Channel HSL  │      │ • Auto-Ducking   │   │ • Keyframe Paths │
│ • Magnetic Snap  │   │ • Safe Guides    │      │ • RGB Tone Curve │      │ • Audio Waveform │   │ • Font Stylizer  │
│ • Ripple Delete  │   │ • Frame Compositor│      │ • GLSL Matrices  │      │ • A/B Comparison │   │ • 5x Animations  │
└────────┬─────────┘   └────────┬─────────┘      └────────┬─────────┘      └────────┬─────────┘   └────────┬─────────┘
         │                      │                         │                         │                      │
         └──────────────────────┴─────────────────────────┼─────────────────────────┴──────────────────────┘
                                                          ▼
                                       ┌─────────────────────────────────────┐
                                       │       FFmpeg Export Pipeline        │
                                       │ • 4K UHD / 1080p FHD / 720p HD      │
                                       │ • 24 / 30 / 60 FPS Multi-Framerate  │
                                       │ • H.264 (Universal) / H.265 (HEVC)  │
                                       │ • Background Progress & Live ETA    │
                                       │ • Direct Share & Save to Gallery    │
                                       └─────────────────────────────────────┘
```

---

## 📱 Complete Roadmap & Architecture Phases

| Phase | Git Tag | Module | Status | Specification |
|---|:---:|---|:---:|:---:|
| **Phase 0** | `master` | **Project Foundation & CI/CD** | 🟢 Complete | [docs/phase-0-spec.md](docs/phase-0-spec.md) |
| **Phase 1** | `phase-1-done` | **Media Import & Data Models** | 🟢 Complete | [docs/phase-1-spec.md](docs/phase-1-spec.md) |
| **Phase 2** | `phase-2-done` | **Timeline UI & Multi-Track Editing** | 🟢 Complete | [docs/phase-2-spec.md](docs/phase-2-spec.md) |
| **Phase 3** | `phase-3-done` | **Real-Time Preview Compositor** | 🟢 Complete | [docs/phase-3-spec.md](docs/phase-3-spec.md) |
| **Phase 4** | `phase-4-done` | **Transitions & Speed Ramping** | 🟢 Complete | [docs/phase-4-spec.md](docs/phase-4-spec.md) |
| **Phase 5** | `phase-5-done` | **Color Grading & 3D LUTs** | 🟢 Complete | [docs/phase-5-spec.md](docs/phase-5-spec.md) |
| **Phase 6** | `phase-6-done` | **On-Device AI Audio Enhancement** | 🟢 Complete | [docs/phase-6-spec.md](docs/phase-6-spec.md) |
| **Phase 7** | `phase-7-done` | **Text, Motion Titles & Overlays** | 🟢 Complete | [docs/phase-7-spec.md](docs/phase-7-spec.md) |
| **Phase 8** | `phase-8-done` | **FFmpeg Export Pipeline** | 🟢 Complete | [docs/phase-8-spec.md](docs/phase-8-spec.md) |
| **Phase 9** | `phase-9-done` | **Global Undo/Redo Engine** | 🟢 Complete | [docs/phase-9-spec.md](docs/phase-9-spec.md) |
| **Phase 10** | `v1.0.0` | **Production Release & Distribution** | 🟢 Complete | [docs/phase-10-spec.md](docs/phase-10-spec.md) |

---

## 🛠️ Local Development & Build Instructions

### Prerequisites
- **Flutter SDK:** `^3.19.0` or newer
- **Dart SDK:** `^3.3.0` or newer
- **Android Studio / SDK:** `compileSdkVersion 34`, `minSdkVersion 24`
- **JDK:** Java 17

### 1. Clone the repository
```bash
git clone https://github.com/itssagarK/edito.git
cd edito
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Run the automated test suite
```bash
flutter test
```

### 4. Run on a connected Android device or emulator
```bash
flutter run
```

### 5. Build release APK locally
```bash
flutter build apk --release
```
The compiled APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
