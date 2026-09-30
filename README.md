# 🎬 Edito — Pro Video Editor for Android

<p align="center">
  <img src="https://raw.githubusercontent.com/itssagarK/edito/main/assets/branding/banner.png" alt="Edito Video Editor Banner" width="100%" onerror="this.style.display='none'" />
</p>

<p align="center">
  <b>A high-performance, industry-grade mobile video editor built for Android.</b><br>
  Engineered with a 60 FPS preview compositor, AI vocal isolation & speech restoration, 3-way color wheels & 4x5 GPU matrices, curved typography, multi-grid split-screen video collages, creator teleprompter, and a deterministic 4K FFmpeg export pipeline.
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
      <a href="https://github.com/itssagarK/edito/releases/download/v1.0.60/app-release.apk">
        <img src="https://img.shields.io/badge/⚡%20DIRECT%20DOWNLOAD-Edito%20v1.0.60%20APK%20(Universal)-6C5CE7?style=for-the-badge&logo=android&logoColor=white" height="42" alt="Download APK" />
      </a>
      <br>
      <sub><b>Target:</b> <code>ARM64-v8a</code>, <code>ARMeabi-v7a</code>, <code>x86_64</code> &nbsp;•&nbsp; <b>Min SDK:</b> Android 7.0+ (API 24+) &nbsp;•&nbsp; <b>Target SDK:</b> Android 16 (API 36)</sub>
    </td>
  </tr>
  <tr>
    <td align="center">
      📦 <b>Latest Release Notes:</b> <a href="https://github.com/itssagarK/edito/releases/tag/v1.0.60"><b>v1.0.60 Production Release on GitHub</b></a>
    </td>
  </tr>
</table>

---

## 🌟 Latest Flagship Studios & Features

### 📱 Multi-Grid Split-Screen Video Studio (v1.0.60)
- **10 Dynamic Multi-Grid Layouts:** 2-Split Vertical/Horizontal, 3-Strip Vertical/Horizontal, 3-T Collage (Top/Bottom), 4-Grid Quad Matrix, 5-Collage, 6-Matrix, and 9-Wall video mosaics.
- **Interactive Viewport Slot HUD:** Visual `#1`, `#2`, `#3` slot badges overlaid directly on preview cells with active slot selection, asset mapping, and touch focus.
- **Customizable Dividers & Borders:** Dynamic divider width slider ($0\text{ to }24\text{ px}$), corner roundness slider ($0\text{ to }32\text{ px}$), and 8 curated border colors (Studio White, Cyber Cyan, Neon Pink, Sunset Amber, Carbon, etc.).
- **Per-Cell Media Pan & Zoom:** Independent scaling ($1.0\times\text{ to }2.5\times$) and $(X, Y)$ focal centering per video cell.
- **FFmpeg `xstack` Multi-Stream Composition:** Compiles hardware-accelerated grid layouts into 4K video exports with custom frame padding and color fills.

### 🔤 Studio Typography, Presets & Curved Text Suite (v1.0.59)
- **20 Signature Typography Preset Styles:** 5 curated design families—Classic Clean, Bold Strokes, Badges & Pills, Drop Shadows, and Neon Glow—with vibrant multi-layer color palettes and high-contrast backdrops.
- **Parametric Curved Text Engine:** Mathematical circular arc glyph deformation ($R = \frac{W}{|\alpha|}$) from $-180^\circ$ (full convex arch) to $+180^\circ$ (full concave bowl) with continuous tangent orientation for each individual glyph.
- **Comprehensive 6-Tab Typography Dock:** Presets, Style & Font, Curve & Glow, Animation, Position & Transform, and Keyframes.
- **Full Font Customization:** Font family selection (*Inter*, *Bebas Neue*, *Montserrat*, *JetBrains Mono*, *Cinzel*), font weight, character tracking, line height, text align, outline stroke, shadow offset/blur, and background padding.

### 📜 Creator Teleprompter & Live Script Studio (v1.0.58)
- **Floating Semi-Transparent Prompter HUD:** Renders high-legibility floating script text directly over the live camera or video preview viewport.
- **Variable Autoscroll Speed:** Smooth auto-scroll calibrated from $20\text{ to }300\text{ words per minute}$ matching natural conversational or rapid-fire delivery.
- **Mirror Flip Mode:** Horizontal text mirroring for physical beam-splitter teleprompter glass hardware rigs.
- **Countdown Lead-In & Focus Guide:** Configurable $3\text{s} / 5\text{s}$ lead-in countdown timer and center focal reading guide line.
- **Integrated Script Management:** Load, edit, save, paste from clipboard, or pick curated script templates (*Product Review*, *TikTok Hook*, *YouTube Intro*, *News Flash*).

### 🛡️ AI Smart Mosaic & Privacy Censor Blur Studio (v1.0.57)
- **4 Privacy Obfuscation Modes:** Retro 8-bit Pixel Mosaic blocks, silky Gaussian privacy defocus, Hexagonal crystal honeycomb, and Frosted diffused glass blur.
- **Dynamic Geometric Mask Shapes:** Rectangle box, Ellipse/Face censor, Banner strip, and Full-frame background blur.
- **Interactive Viewport HUD:** Direct touch manipulation of censor center $(X, Y)$, dimensions, rotation, corner roundness, and mask inversion.
- **Localized FFmpeg Export Compilation:** Compiles high-performance edge-preserving `delogo` and multi-pass spatial blur filters into video exports.

### ✨ AI Video Glow & Edge Aura Studio (v1.0.55)
- **Real-Time Edge Extraction:** High-contrast edge detection generating luminous subject silhouettes.
- **Curated Neon Color Halos:** Neon Cyan, Cyber Magenta, Golden Sun, Emerald Glow, Electric Violet, Flame Orange, and Studio White.
- **Pulsing Animation Engine:** Dynamic breathing/pulsing frequency slider ($0.2\text{ to }4.0\text{ Hz}$) and glow dilation width ($2\text{ to }40\text{ px}$).
- **Deterministic FFmpeg Export:** Compiles multi-layer edge detection, color matrix recoloring, and Gaussian glow blending.

### 🎙️ AI Voice Changer & Audio Timbre Morphing Studio (v1.0.54)
- **8 Signature Vocal Characters:** Chipmunk, Deep Monster, Robot/Vocoder, Telephone Landline, Vintage AM Radio, Echo Chamber, Studio Vocal Mic, and Clean Neutral.
- **Pitch & Formant Shifting:** Pitch transposition from $-12\text{ to }+12$ semitones with tempo lock and formant compensation.
- **FFmpeg Audio DSP Graph:** Compiles `asetrate`, `atempo`, `equalizer`, and `aresample` chains with brickwall audio limiter safeguards.

### 🌙 Video De-Noise & Low-Light Detail Studio (v1.0.53)
- **Multi-Pass Noise Reduction:** High-performance spatial and temporal noise filtering (`hqdn3d` and `nlmeans`) preserving fine edge texture.
- **Low-Light Detail Recovery:** Adaptive shadow lift, tone curve expansion, and ISO sensor grain reduction.
- **A/B Split-Screen Inspection:** Instant before-and-after visual comparison toggle in the live preview viewport.

### 💡 AI Video Relight & Virtual 3D Studio Lighting (v1.0.52)
- **Virtual 3D Directional Lighting:** Position virtual key, fill, and rim lights with 3D elevation and azimuth angles.
- **Lighting Atmosphere Presets:** Golden Hour, Cyberpunk Neon, Moody Noir, Studio Warm, Cold Frost, and Sunset Glow.
- **Kelvin Color Temperature:** Continuous adjustment from warm tungsten ($2500\text{ K}$) to cool daylight ($8500\text{ K}$).

### 🎨 AI Color Match & Tone Palette Transfer (v1.0.51)
- **Reference Frame Color Transfer:** Analyzes RGB luminance distributions and transfers color mood from a reference clip to target footage.
- **Harmonized Multi-Camera Grading:** Automatically aligns contrast, color balance, and saturation across mixed camera sources.

### 🎵 AI Vocal Isolation & Audio Stem Splitter (v1.0.50)
- **Voice / Music Separation:** Isolate speech vocals, remove background noise, or extract instrumental music backing.
- **Karaoke Backing Mode:** Center-channel audio cancellation eliminating lead vocals while preserving stereo instrumentation.
- **Brickwall True-Peak Limiter:** Integrated peak envelope ceiling constrained to $-0.5\text{ dB}$ (`alimiter=limit=0.95`) preventing digital clipping.

---

## 🎨 Creative Editing Suites & Core Capabilities

### 💆 AI Face & Body Retouching Studio (v1.0.47)
- **Skin Smoothing & Blemish Conceal:** Texture-preserving bilateral skin softening with blemish reduction.
- **Facial Sculpting & Feature Contouring:** Face slimming, eye brightening, and teeth whitening sliders with live viewport feedback.

### 🎯 AI Motion Tracking & Dynamic Element Pinning (v1.0.46)
- **Point & Area Tracking:** Interactive bounding-box selector to track moving vehicles, faces, or objects.
- **Dynamic Element Binding:** Lock text titles, sticker badges, or picture-in-picture clips to tracked coordinates across time.

### 🎤 Kinetic Captions & Word-by-Word Karaoke Studio (v1.0.45 / v1.0.21)
- **Karaoke Highlight Animations:** Word-by-word active text highlighting synchronized to spoken audio.
- **Bouncy Kinetic Typography:** Pop-in, scale bounce, and typewriter motion presets.
- **Automated `.srt` Subtitle Generation:** Automatic export of synchronized `.srt` subtitle files alongside MP4 videos.

### 🧲 Magnetic Ripple Multi-Track Timeline (v1.0.42)
- **Synchronized Coordinate Canvas:** Ruler, multi-track clip lanes, and playhead scroll in 100% lockstep.
- **Real-Time PCM Audio Waveforms:** Deterministic audio peak rendering on all audio and video tracks.
- **Magnetic Snapping Engine:** $150\text{ ms}$ magnetic threshold snapping clips to cut points, playhead, and markers.
- **Ripple Delete & Auto-Follow Playhead:** Automated gap closing and continuous playback scrolling.

### 🎡 3-Way Color Wheels Studio (v1.0.41)
- **Lift, Gamma, Gain, and Offset:** Professional 3-way color balance wheels with master exposure sliders.
- **8-Channel Selective HSL:** Individual Hue, Saturation, and Luminance adjustment per color channel.
- **Master RGB Tone Curves:** Draggable 4-channel spline curves with touch control points.

### 🌌 Cinematic GLSL Shader Transitions Studio (v1.0.40)
- **Live Skia GPU Shader Transitions:** Cross-dissolve, zoom blur, page curl, glitch displacement, and directional wipes.
- **Deterministic `xfade` Export Compilation:** Seamless FFmpeg transition graphs with duration control.

### 🎚️ Cinematic Audio Restoration Studio (v1.0.38 / v1.0.30)
- **Spectral De-Hum & De-Esser:** Removes mains hum ($50/60\text{ Hz}$) and harsh sibilance frequencies.
- **Acoustic Room Reverb & Parametric EQ:** Recreate studio booth, auditorium, or cathedral acoustics with 5-band EQ.
- **Smart Auto-Ducking:** Automatically attenuates background soundtracks during dialogue scenes.

### 🌊 Optical Flow Frame Blending & Velocity Motion Blur (v1.0.36)
- **Silky Slow-Motion:** Frame interpolation blending adjacent frames for jitter-free slow-mo playback.
- **Directional Velocity Motion Blur:** High-energy shutter blur applied during rapid camera motion and speed ramps.

### 🗣️ AI Text-to-Speech (TTS) Voiceover Generator (v1.0.34)
- **Neural Voice Narration:** Converts script text into spoken audio tracks with pitch, speed, and volume customization.

### 🥁 Beat Detection & Rhythmic Snap Guidelines (v1.0.32)
- **Audio Transient Analysis:** Detects musical beats and drops, placing snap markers on the timeline for rhythm editing.

### 📈 Bezier Speed Ramping & Velocity Curves (v1.0.28)
- **Custom Bezier Curves:** Smooth acceleration and deceleration with Montage, Hero, and Bullet-Time curve presets.
- **Pitch Preservation:** Real-time and export pitch-corrected audio time-stretching.

### 🔄 Universal Transform Keyframing Engine (v1.0.26)
- **Multi-Property Keyframing:** Position $(X, Y)$, Scale, Rotation, and Opacity keyframes with cubic bezier easing.

### 🎭 Multi-Shape Masking & 16-Mode Layer Blending (v1.0.24 - v1.0.25)
- **Geometric Masks:** Rectangle, Ellipse, Inverted, and Feathered masking shapes.
- **16 Pro Blend Modes:** Multiply, Screen, Overlay, Soft Light, Hard Light, Color Dodge, Darken, Lighten, etc.

### 🖼️ Video Borders & Frames, Header/Footer Cards (v1.0.22)
- **Cinematic Letterbox:** 2.35:1 Anamorphic widescreen bars, rounded modern borders, and retro photo frames.
- **Header & Footer Banners:** Social media callout cards, breaking news banners, and headline strips.

### 🔍 8K Lanczos Upscaler & HD Video Converter (v1.0.23)
- **Algorithmic Lanczos Interpolation:** Sharp, artifact-free resolution scaling up to 4K/8K.
- **Optimized FastStart Containers:** FastStart atom placement (`-movflags +faststart`) for instant web & social playback.

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
│ Timeline Engine  │   │  Preview Engine  │      │ Pro Color Studio │      │ AI Audio Engine  │   │ Motion Overlays  │
│ • Magnetic Snap  │   │ • 60 FPS Clock   │      │ • 3-Way Wheels   │      │ • Vocal Isolation│   │ • Curved Text    │
│ • PCM Waveforms  │   │ • Multi-Grid Pip │      │ • 4x5 Matrices   │      │ • Voice Changer  │   │ • 20 Typography  │
│ • Ripple Editing │   │ • Safe Guides    │      │ • Color Match    │      │ • Speech Cleaner │   │ • Keyframe Paths │
│ • Trim & Split   │   │ • Teleprompter   │      │ • 8-Channel HSL  │      │ • Brickwall Limit│   │ • Kinetic Titles │
└────────┬─────────┘   └────────┬─────────┘      └────────┬─────────┘      └────────┬─────────┘   └────────┬─────────┘
         │                      │                         │                         │                      │
         └──────────────────────┴─────────────────────────┼─────────────────────────┴──────────────────────┘
                                                          ▼
                                       ┌─────────────────────────────────────┐
                                       │       FFmpeg Export Pipeline        │
                                       │ • 4K UHD / 1080p FHD / 720p HD      │
                                       │ • Multi-Grid xstack Composition     │
                                       │ • GLSL xfade Transition Chains      │
                                       │ • Hardware Android MediaStore Save  │
                                       │ • Companion SRT Subtitle Export     │
                                       └─────────────────────────────────────┘
```

---

## 📱 Release History & Feature Milestones

| Version | Milestone Feature | Release Highlights |
|:---:|---|---|
| **v1.0.60** | **Split-Screen Studio** | 10 multi-grid collage layouts, interactive slot HUD, divider styling, `xstack` export |
| **v1.0.59** | **Curved Text & Typography** | 20 signature preset styles, $-180^\circ$ to $+180^\circ$ circular arc deformation, 6-tab dock |
| **v1.0.58** | **Creator Teleprompter** | Floating semi-transparent prompter HUD, 20–300 wpm autoscroll, mirror flip mode |
| **v1.0.57** | **Smart Mosaic & Blur** | Pixel blocks, Gaussian privacy blur, Hexagonal crystal, Frosted glass, dynamic masks |
| **v1.0.55** | **Edge Aura & Video Glow** | Real-time edge detection, multi-color neon halos, pulsing aura animation, dilation |
| **v1.0.54** | **AI Voice Changer** | 8 vocal characters, pitch & formant shifting, equalizer, brickwall limiter |
| **v1.0.53** | **De-Noise & Low-Light** | `hqdn3d` and `nlmeans` temporal/spatial denoisers, shadow detail recovery |
| **v1.0.52** | **AI Video Relight** | Virtual 3D key, fill, and rim lights, 3D angle elevation, Kelvin color temperature |
| **v1.0.51** | **AI Color Match** | Reference frame color extraction, automated RGB distribution transfer |
| **v1.0.50** | **AI Vocal Isolation** | Vocal removal, speech isolation, karaoke backing, stem splitting |
| **v1.0.47** | **AI Face Retouching** | Bilateral skin smoothing, blemish reduction, eye brightening, teeth whitening |
| **v1.0.46** | **AI Motion Tracking** | Bounding box object tracking, dynamic text/sticker coordinate pinning |
| **v1.0.42** | **Magnetic Timeline** | Real-time PCM waveforms, magnetic snapping, ripple editing, auto-follow playhead |
| **v1.0.41** | **3-Way Color Wheels** | Lift, Gamma, Gain, Offset color wheels, two-tier contextual dock |
| **v1.0.40** | **GLSL Transitions** | Live Skia GPU shader transitions, FFmpeg `xfade` compilation |
| **v1.0.38** | **Audio Restoration** | Spectral de-hum, de-esser sibilance reducer, room reverb, parametric EQ |
| **v1.0.36** | **Optical Flow Motion** | Frame blending slow-motion, directional velocity motion blur |
| **v1.0.34** | **AI Text-to-Speech** | Neural multi-language voice narration synthesis, pitch & pace controls |
| **v1.0.32** | **Beat Detection** | Audio transient analysis, automatic beat drop markers, rhythm snapping |
| **v1.0.28** | **Speed Ramping** | Custom Bezier curves, Montage/Hero/Bullet-Time presets, pitch preservation |
| **v1.0.26** | **Keyframing Engine** | Universal transform keyframing (Position, Scale, Rotation, Opacity) |
| **v1.0.24** | **Masking & Blending** | Multi-shape masks, 16 layer blend modes, pro compositor |
| **v1.0.23** | **8K Boost & HD Convert** | Algorithmic Lanczos upscaling, HD video converter, FastStart optimization |
| **v1.0.19** | **Zero-Bleed Color** | Pristine original media import, BT.709 colorimetry, midtone contrast balancing |
| **v1.0.0**  | **Production Release** | Core MVP, timeline, preview engine, FFmpeg export pipeline |

---

## 🛠️ Local Development & Build Instructions

### Prerequisites
- **Flutter SDK:** `^3.19.0` or newer
- **Dart SDK:** `^3.3.0` or newer
- **Android Studio / SDK:** `compileSdkVersion 36`, `minSdkVersion 24`, `targetSdkVersion 36`
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
