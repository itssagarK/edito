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
      <a href="https://github.com/itssagarK/edito/releases/download/v1.0.15/app-release.apk">
        <img src="https://img.shields.io/badge/⚡%20DIRECT%20DOWNLOAD-Edito%20v1.0.15%20APK%20(Universal)-6C5CE7?style=for-the-badge&logo=android&logoColor=white" height="42" alt="Download APK" />
      </a>
      <br>
      <sub><b>Target:</b> <code>ARM64-v8a</code>, <code>ARMeabi-v7a</code>, <code>x86_64</code> &nbsp;•&nbsp; <b>Min SDK:</b> Android 7.0+ (API 24+) &nbsp;•&nbsp; <b>Target SDK:</b> Android 16 (API 36)</sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      📦 <b>Latest Release Notes:</b> <a href="https://github.com/itssagarK/edito/releases/tag/v1.0.15"><b>v1.0.15 Production Release on GitHub</b></a>
    </td>
  </tr>
</table>

---

## 🌟 Key Features

### 🌟 Character Highlight & Background Color Customizer (v1.0.15)
- **Subject / Character Spotlight:** Spotlight focus on subjects in the frame with customizable $(X, Y)$ focal center, spotlight radius, and soft feathering.
- **Neon Aura Glow Mode:** Radiate high-intensity neon aura outlines around characters (Neon Cyan, Cyber Magenta, Golden Sun, Lime, Electric Purple, Flame Orange, Studio White) with dynamic contrast & saturation boost.
- **B&W Background Pop Mode:** Instantly transform the surroundings into moody monochrome while keeping the subject highlighted in vivid full color.
- **Custom Background Color Swap:** Recolor and tint the background behind the subject (Dark Studio, Cyber Purple, Deep Navy, Emerald Forest, Crimson Noir, Sunset Amber, Matte Charcoal) with variable dimming and saturation control.
- **Real-Time Viewport Shading & Live HUD:** Live radial gradient canvas rendering with real-time feedback badges (`🌟 CHARACTER SPOTLIGHT`, `⚡ NEON AURA GLOW`, `🎨 BG COLOR`) directly in the preview player.
- **Deterministic FFmpeg Video Filter Chains:** Compiles synchronized `vignette`, `colorbalance`, and `eq` filter chains into 4K video exports.

### 🚀 Synchronized Multi-Track Timeline & Unified Overlay Export Engine (v1.0.14)
- **Unified Timeline Coordinate System:** Solved timeline desynchronization by unifying the Top Ruler, all multi-track clip lanes, and the playhead into a single synchronized coordinate canvas. Horizontal scrolling moves all tracks, tick marks, and the playhead in 100% unison.
- **Dynamic Auto-Follow Playhead:** Automatically and smoothly scrolls the timeline horizontally during continuous video playback and seeking so the playhead needle never leaves the viewport.
- **Canvas Click-to-Seek:** Tapping anywhere on the top ruler or empty track areas instantly seeks to that precise millisecond timestamp with frame-accurate video update.
- **Dedicated Overlay Tracks in Export:** Badges, PiP images, and stickers on dedicated overlay tracks are compiled with timed `drawtext` box filters and burned seamlessly into the exported MP4 video stream.
- **Multi-Overlay Compositing:** Real-time preview viewport simultaneously renders multiple concurrent overlays (text titles, auto-captions, and sticker badges) across distinct tracks.

### 💎 Full Feature Verification & Real Rendering Pipeline (v1.0.13)
- **Live Chroma Key GPU Matrix & Suppression:** Chroma Key green/blue screen controls directly calculate color suppression coefficients on the 4x5 GPU color matrix in real-time preview, with live HUD feedback and native FFmpeg `chromakey` export filter compilation.
- **Picture-in-Picture & Creative Asset Sticker Badges:** All Creative Asset stickers (Subscribe & Bell, #1 Trending, 4K UHD, Verified Creator, etc.) and custom image overlays render in real time with dynamic $(X, Y)$ positioning, scaling, rotation, opacity, and PiP borders, and burn directly into exported videos via FFmpeg drawtext/overlay.
- **Live Canvas Framing & Backdrop Rendering:** Dynamic multi-aspect framing ($16:9, 9:16, 1:1, 4:5, 21:9$) renders live in the viewport with adjustable frame padding and rounded corners against custom backgrounds (Gaussian blur gradient, solid hex color, or aesthetic presets) and pads precisely in the final export.
- **Live Transition Animations & XFade Compilation:** Fade black, fade white, wipe left/right, and slide transitions animate live in the preview viewport and compile into seamless FFmpeg `xfade` transition filter chains in export.
- **Dynamic Speed Ramping Timeline Resizing:** Changing playback rate ($0.2\times$ slow-mo to $4.0\times$ fast-mo) recalculates clip timeline duration dynamically, preventing video freeze or audio desync.
- **Video Clip In-Place Text Overlay Rendering:** Text titles added to video clips are rendered live in both the preview compositor and the export burn-in pipeline.

### 🎬 Android MediaStore Gallery Export & Reliable Rendering (v1.0.12)
- **Instant Android Gallery Indexing:** Exported videos are immediately written to Android `MediaStore.Video` under the `Movies/Edito/` directory, appearing right away in Google Photos, Samsung Gallery, Xiaomi Gallery, and WhatsApp/Instagram pickers.
- **Thumbnail & Cover Gallery Saving:** Image Editor graphics, YouTube thumbnails, and video covers export straight to `MediaStore.Images` under `Pictures/Edito/`.
- **Scoped Storage API 29–36 Compliant:** Native Kotlin platform channel handles atomic MediaStore insertions with `IS_PENDING` flags and system `MediaScannerConnection` broadcasts across modern Android 10–16.
- **Robust Video Assembly & Playback:** Renders playable, high-bitrate MP4 files with accurate audio streams and companion `.srt` subtitle files, completely eliminating 0-byte or corrupted export containers.
- **Interactive Export Dialog:** Export success screen displays the exact gallery destination path with an instant one-tap "Save to Gallery" verification button.

### ⚡ Real-Time Video Rendering & Playback Engine (v1.0.11)
- **Instant Hardware Texture Playback:** Imported videos immediately render directly in the real-time preview viewport via native Android ExoPlayer/MediaCodec hardware textures.
- **Dynamic Compositor Evaluation:** Zero-latency evaluation ensures the viewport stays synchronized upon project loading, asset picking, and multi-track trimming.
- **Anti-Stall Playback Sync:** Eliminates decoding decoder-flush loops during continuous playback, preserving fluid 60 FPS preview with accurate playhead tracking.
- **Universal Android Media Support:** Seamless support for Android `content://` URIs (Storage Access Framework / Google Photos), local filesystem paths, and network streams.
- **Secondary Audio Isolation:** Dedicated audio tracks (soundtracks, music, sound effects) play synchronously without interfering with the primary video's native audio stream.

### 📐 Video Canvas Layouts & Aspect Ratio Framing
- **Multi-Aspect Ratio Canvas:** Switch instantly between **16:9** (YouTube/Cinema), **9:16** (Reels/TikTok/Shorts), **1:1** (Square Feed), **4:5** (Instagram Portrait), and **21:9** (Ultra-Wide).
- **Gaussian Video Blur Backdrop:** Automatically generates a smooth, blurred fill of the video footage itself behind vertical or square aspect frames.
- **Floating Border Padding & Corner Curvature:** Customize frame inset ($0–36\text{ px}$) and corner radius ($0–32\text{ px}$) for sleek modern mobile aesthetics.

### 🖼️ Picture-in-Picture (PiP) & Image Overlays
- **Interactive Overlay Layer:** Pin photos, graphics, stickers, or second video clips anywhere over the primary video.
- **Precise Transform Sliders:** Scale ($0.2\times–2.5\times$), $X/Y$ coordinates, rotation ($0°–360°$), and layer opacity ($0–100\%$).
- **PiP Window Framing:** Toggle rounded frame borders, contrast outline, and drop shadows with one tap.

### 🎨 Built-in Creative Assets Catalog
- **Badges & Call-to-Actions:** Subscribe & Bell notification, Thumbs Up & Share, #1 On Trending, 4K UHD 60FPS, Verified Creator tick, and Live indicator.
- **Layout Frames & Borders:** Cinematic 2.35:1 Anamorphic letterbox, Modern Rounded Border, and Vintage Polaroid Photo Frame.
- **Lower Thirds & Text Banners:** Breaking News alert banner, Social Media Handle card, and Chapter Segment card.
- **Canvas Backgrounds:** Dark Cosmic Nebula, Cyberpunk Neon Grid, and Minimal Studio Charcoal.

### 📸 Thumbnail & Cover Designer Studio
- **On-Canvas Design Studio:** Capture any frame from the video or import graphics to design high-impact YouTube/TikTok thumbnails.
- **Viral Headline Typography:** Bold headline text with custom drop shadows, color swatches, and background pill containers.
- **Cinematic Color Looks:** Instant one-tap looks (*Vibrant Pop*, *Cinematic Teal*, *Cyber Neon*, *Golden Hour*, *Noir B&W*) and vignette darkening.
- **One-Tap Actions:** Save as official project cover, add into video timeline as a clip, or export high-res PNG to device gallery.

### 🟩 Chroma Key Green / Blue Screen Removal
- **One-Tap Color Presets:** Dedicated green screen (`#00FF00`), blue screen (`#0000FF`), cyan, and magenta keyers.
- **Fine-Tuning Controls:** Similarity threshold, edge feather blend smoothness, and color spill suppression.
- **FFmpeg Transcode Integration:** Directly compiles `chromakey=color=$hex:similarity=$sim:blend=$smooth` into export filter graph.

### 🎞️ Multi-Track Non-Linear Timeline
- **Smooth Pinch-to-Zoom:** Zoom seamlessly from high-level bird's-eye view ($0.2\times$) to frame-accurate sample level ($5.0\times$).
- **Frame-Accurate Splitting & Trimming:** Split clips at playhead with zero audio pop; adjust head/tail handles with real-time feedback.
- **Magnetic Snapping Engine:** $150\text{ ms}$ magnetic threshold to automatically align clips to cuts, playhead, and marker boundaries.
- **Track Controls:** Independent Mute, Lock, Hide, Duplicate, and Ripple Delete for Video, Audio, and Overlay tracks.

### ⚡ Real-Time Preview & Compositor
- **Synchronized 60 FPS Engine:** Ultra-low latency playback clock driving continuous playhead synchronization.
- **Broadcast Safe Guides:** $90\%$ Action Safe and $80\%$ Title Safe broadcast overlay grids with center crosshair.
- **Real-Time PCM Audio Waveforms:** Timeline waveform visualizer supporting deterministic audio peaks.

### 🎨 Color Grading & Looks
- **Primary Adjustments:** Exposure ($-2.0$ to $+2.0\text{ EV}$), Contrast, Saturation, Brightness, Highlights, Shadows, Vignette.
- **Color Temperature & Tint:** Kelvin temperature shift (Cool Blue $\leftrightarrow$ Warm Amber) and Tint (Green $\leftrightarrow$ Magenta).
- **8-Channel Selective HSL:** Dedicated Hue, Saturation, and Luminance sliders for 8 individual color channels.
- **Master RGB Tone Curves:** Interactive 4-channel spline curve editor with draggable touch control points.

### 🎙️ Audio Enhancement & Safeguards
- **Brickwall Audio Limiter Safeguard:** Peak envelope ceiling constrained to $-0.5\text{ dB}$ (`alimiter=limit=0.95:attack=5:release=50:asc=1`) to eliminate digital clipping distortion.
- **Speech Denoising & Presence Boost:** Removes background hums and room rumble while boosting vocal articulation.
- **Smart Auto-Ducking:** Automatically attenuates background soundtrack volume when dialogue is detected.

### ✍️ Motion Typography & Keyframe Overlays
- **Rich Text Styling:** Font family picker (*Inter*, *Bebas Neue*, *JetBrains Mono*, *Montserrat*), custom sizing, colors, outlines, and background plates.
- **Keyframe Motion Paths:** Multi-point keyframing for position $(X, Y)$, scale, and opacity animation interpolated dynamically across clip duration.

### 🚀 Deterministic FFmpeg Export Pipeline
- **Burn-in Subtitles & Text:** Seamlessly burns text titles and captions into exported video stream via timed `drawtext` filters.
- **Companion `.srt` Subtitle Generation:** Synchronized `.srt` subtitle file exported automatically into `/storage/emulated/0/Movies/Edito/`.
- **Export Render Manifests:** Writes metadata manifests (`.manifest.json`) logging duration, codec, bitrate, quality, and complete FFmpeg command string.
- **Multi-Resolution:** **4K UHD** ($3840\times2160$), **1080p FHD** ($1920\times1080$), and **720p HD** ($1280\times720$).

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
