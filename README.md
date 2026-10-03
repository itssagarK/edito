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

## 📥 Official Editions & APK Downloads

Download the official release APKs directly from this repository:

<table>
  <thead>
    <tr>
      <th align="center">🎬 Edito (Universal Pro Edition)</th>
      <th align="center">👑 Edito Premium (Flagship Studio Edition)</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td align="center">
        <b>Package:</b> <code>com.edito.app</code> &nbsp;|&nbsp; <b>Version:</b> <code>v1.0.71</code><br>
        <b>Size:</b> <code>88.9 MB</code> &nbsp;|&nbsp; <b>Architecture:</b> Universal<br><br>
        <a href="https://github.com/itssagarK/edito/releases/download/v1.0.71/app-release.apk">
          <img src="https://img.shields.io/badge/⚡%20DOWNLOAD-Edito%20v1.0.71%20APK-6C5CE7?style=for-the-badge&logo=android&logoColor=white" height="38" alt="Download Edito APK" />
        </a>
        <br><br>
        <sub>⚡ 60 FPS Skia GPU Compositor &bull; Transform Studio (Rotate/Mirror)<br>Sound Effects Studio (SFX) &bull; AlbertSans Typography &bull; 4K FFmpeg</sub>
      </td>
      <td align="center">
        <b>Package:</b> <code>com.edito.premiumpak</code> &nbsp;|&nbsp; <b>Version:</b> <code>v2.1.0</code><br>
        <b>Size:</b> <code>343.1 MB</code> &nbsp;|&nbsp; <b>Architecture:</b> Universal<br><br>
        <a href="https://github.com/itssagarK/edito/releases/download/v1.0.71/edito-premium.apk">
          <img src="https://img.shields.io/badge/👑%20DOWNLOAD-Edito%20Premium%20APK-FF7675?style=for-the-badge&logo=android&logoColor=white" height="38" alt="Download Edito Premium APK" />
        </a>
        <br><br>
        <sub>🎨 Full Flagship Studio &bull; Decoupled Architecture<br>Deep Generative AI &bull; Smart Cutout &bull; Standalone Pipeline</sub>
      </td>
    </tr>
    <tr>
      <td colspan="2" align="center">
        📦 <b>Latest GitHub Release:</b> <a href="https://github.com/itssagarK/edito/releases/tag/v1.0.71"><b>v1.0.71 Official Release (Both APKs Included)</b></a>
      </td>
    </tr>
  </tbody>
</table>

---

## 🌟 Latest Flagship Studios & Features

### 🧠 100% On-Device & Offline AI Feature Suite (F1–F10)
- **Zero Cloud & Total Privacy:** Fully local on-device machine learning without cloud API keys, external servers, or data collection. Operates seamlessly in Airplane Mode.
- **Permissive Open-Source Engines:** Audited MIT, Apache-2.0, and BSD licenses across all models and runtimes (Whisper, MediaPipe, RNNoise, Silero, Real-ESRGAN).
- **F1: Auto Captions (Whisper STT):** Automatic speech-to-text with word-level timestamps and subtitle track creation via quantized int8 Whisper.
- **F2: Real Subject Segmentation:** On-device MediaPipe Selfie Segmenter powering instant Smart Cutouts and Character Highlight neon auras without manual masking.
- **F3: Auto Subject Tracking:** Dynamic face and body centroid tracking with Exponential Moving Average (EMA) focal smoothing for Character Zoom.
- **F4: Neural Noise Removal:** RNNoise recurrent neural speech enhancement paired with true-peak brickwall limiting and interactive A/B comparison.
- **F5: Smart Auto-Ducking & Beat Sync:** VAD-driven background music ducking during dialogue and spectral flux onset detection for magnetic cut snapping.
- **F6: Real-ESRGAN Neural Upscaler:** Memory-safe tiled super-resolution (128x128 / 256x256 tiles) reconstructs crisp micro-textures for thumbnails and freeze-frames without OOM crashes.
- **F7: AI Silence Remover & Smart Jump-Cut:** On-device VAD scans audio for dead-air pauses (>350ms) and automatically ripples speech contiguously for high-retention social media jump cuts.
- **F8: AI Scene Cut Detector & Auto-Split:** Hardware-accelerated frame differential luminance analysis detects camera shot transitions and slices raw footage into independent scene clips with 1 tap.
- **F9: AI Optical & Centroid Motion Tracking:** Real-time on-device selfie segmentation tracks moving subjects and centroids, locking text titles, stickers, and PiP overlays to the actor with EMA smoothing.
- **F10: AI Dynamic Auto-Reframe:** Dynamic centroid analysis automatically centers the active speaker when reframing widescreen 16:9 footage into 9:16 vertical shorts, Reels, and TikToks.

### 🔄 Spatial Transform & Quick Clip Workflow Studio (v1.0.71)
- **CapCut-Style Spatial Transform Studio:** 1-tap 90-degree step rotations (0°, 90°, 180°, 270°), horizontal mirroring (`hflip`), vertical flipping (`vflip`), and scale zoom sliders (0.5x to 3.0x with presets for Fit, Fill, Zoom, and Dramatic).
- **GPU Skia & 4K FFmpeg Pipeline:** Instant real-time 60 FPS viewport rendering with affine Matrix4 transforms and hardware-accelerated FFmpeg export filter compilation (`transpose=1`, `transpose=2`, `hflip`, `vflip`).
- **High-Velocity Contextual Dock:** Directly surfaces primary clip actions on the bottom dock for instant 1-tap execution: Split, Speed, Volume, Transform, Delete (with ripple delete), Duplicate, Extract Audio (to dedicated audio track), Freeze Frame (3s hold), Reverse Playback, and Sound FX.

### 💡 Cinematic Spotlight & Atmospheric Vignette Studio (v1.0.67)
- **ByteDance/CapCut Pro Optical Shader Architecture:** Direct mathematical port of CapCut Pro's native shader falloff formulas (`dark_angle.frag`, `gles2_filter.frag`) featuring cubic Hermite smoothstep edge illumination attenuation ($3t^2 - 2t^3$).
- **Dual Light/Dark Optical Modes:** Seamlessly toggles between classic Hollywood Dark Film Vignette ($0\%\text{ to }100\%$) and radiant high-key Frost Spotlight Halo ($-100\%\text{ to }0\%$) for angelic glow or ethereal dream sequences.
- **Anamorphic Aspect Deformation & Roundness:** Precision control over oval falloff shaping from $-100\%$ (2.39:1 Cinemascope widescreen horizontal oval) to $+100\%$ (vertical portrait oval), with $0\%$ being natural spherical lens falloff.
- **Interactive Viewport Aiming Reticle:** Draggable optical center crosshair reticle $(X, Y)$ allows creators to lock the spotlight or corner shadow falloff directly onto moving subjects, off-center actors, or focal objects.
- **6 Curated Rim Color Tints & 7 Studio Presets:** Noir Black (`#000000`), Vintage Sepia (`#382012`), Midnight Blue (`#0A192F`), Warm Amber (`#3B1E08`), Emerald Forest (`#0C2417`), and Frost White (`#FFFFFF`). Presets: 35mm Film, Vintage Drama, Anamorphic, Dreamy Light, Action Lock, Golden Hour, and Off.
- **Real-Time Skia 60 FPS Viewport & 4K FFmpeg Engine:** Renders live Skia RadialGradient shaders in the preview viewport and compiles native hardware-accelerated `vignette=a=...:x0=...:y0=...:aspect=...:mode=...` and color grading filter chains for 4K video exports.

### 🎞️ Cinematic Film Grain & Texture Particles Studio (v1.0.66)
- **6 Photographic Film Stocks & Texture Profiles:** 35mm Motion Picture Negative (Kodak Vision3 500T organic grain), 16mm Indie Cinema Emulsion (Arri grainy texture), Super 8mm Vintage Home Movie (chunky celluloid grain), Silver Halide (pure monochrome B&W archival grain), Analog Tape (90s VHS magnetic tape hiss and scanline drift), and Digital ISO sensor noise.
- **Dynamic Luminance Masking Math:** Direct port of CapCut Pro's native polynomial luminance masking curve ($y = \text{strength} - \text{mask}$), protecting deep crushed blacks and peak highlights while injecting rich organic micro-contrast into midtones.
- **Micro-Refinement Grain Controls:** Precision sliders for Grain Intensity ($0\%\text{ to }100\%$), Grain Size ($0.5\times\text{ to }3.0\times$), Roughness / Chromatic Noise ($0\%\text{ to }100\%$), Black Protection ($0\%\text{ to }100\%$), and Temporal Motion frame variation toggle.
- **7 Curated Cinematic Grain Presets:** Kodak 500T, Fuji 16mm, Super 8, Noir B&W, VHS Tape, Subtle 35mm, and Neutral Off.
- **Real-Time Skia Viewport Engine & 4K FFmpeg Export:** Real-time procedural particle simulation overlay in the preview viewport and hardware-accelerated FFmpeg `noise=c0s=...:c0f=t+u:c1s=...:c2s=...` export filter graphs for 4K video exports.

### 📈 Pro RGB Curves & Luma Spline Studio (v1.0.65)
- **4-Channel Independent Spline Grading:** Precision tonal and chromatic curve sculpting across Master/Luma (`ALL / Y`), Red (`R`), Green (`G`), and Blue (`B`) channels ported from native CapCut Pro and DaVinci Resolve grading engines.
- **Fritsch-Carlson Monotonic Cubic Hermite Interpolation:** Enforces strictly monotonic slope weighting, eliminating overshoot, color fringing, and artificial banding across complex custom curve shapes.
- **Interactive 2D Cartesian Coordinate Canvas:** Touch-interactive $240\times240$ coordinate grid with 4x4 division guides, diagonal identity reference line, tap-to-add control points (up to 8 points), touch-drag point repositioning, and double-tap point deletion.
- **7 Signature Cinematic Curve Presets:** Linear Neutral, S-Curve Punchy Contrast, Faded Matte Film Print, Cross Process, Teal & Orange Blockbuster, Punchy Pop Dynamic Range, and Bleach Bypass Silver Halide.
- **Real-Time Skia 60 FPS Engine & 4K FFmpeg Export:** Real-time 4x5 Skia matrix hardware compilation in preview viewport and native hardware-accelerated FFmpeg `curves=m='...':r='...':g='...':b='...'` export filter graphs.

### ✏️ Creative Brush & Doodle Drawing Studio (v1.0.64)
- **Multi-Brush Creative Engine:** Seamlessly paint and sketch directly on video viewports with 6 dedicated brush types: **Precision Pen** (smooth vector ink), **Neon Glow** (triple-pass radiant halo with brilliant white core), **Highlighter** (broad translucent miter strokes), **Directional Arrow** (auto-oriented arrowhead tips), **Dashed Line** (rhythmic dashed patterns), and **Eraser** (proximity-based stroke removal).
- **Sub-Pixel Quadratic Bezier Curve Smoothing:** Smooths raw touch coordinates into silky, natural curves via mid-point Bezier interpolation, eliminating jitter and polygon stepping.
- **Dynamic Studio Controls & Palette:** 8 curated studio colors (Cyber Cyan, Neon Green, Hot Pink, Sunburst Yellow, Electric Violet, Studio White, Flame Orange, Deep Onyx), real-time stroke size scaling ($2\text{ to }80\text{ px}$), and variable opacity ($10\%\text{ to }100\%$).
- **Interactive Viewport Overlay & Reticle Cursor:** Real-time gesture canvas with a circular reticle cursor tracking touch positions, step-by-step stroke Undo, Clear All, and batch Apply to All Clips.
- **Deterministic 4K FFmpeg Export Pipeline:** Compiles stroke bounding vectors and color-mapped draw primitives into high-performance FFmpeg export filter chains.

### 🎨 Pro 3-Way & Log Color Wheels Studio (v1.0.63)
- **Dual-Engine Professional Grading:** Seamlessly switch between Primary Color Wheels (Lift, Gamma, Gain, Offset) and Log Color Wheels (Shadow, Midtone, Highlight, Offset) ported from studio architectures.
- **LumaMix Luminance Decoupling:** Dedicated $0\%\text{ to }100\%$ control preserving exposure relationships while shifting chromatic hue bias, eliminating highlight blowout and shadow clipping.
- **Cubic Hermite Range Crossover Splitting:** Dynamic Low Range ($10\%\text{ to }50\%$) and High Range ($50\%\text{ to }90\%$) threshold crossovers with cubic Hermite weighting for silky, zero-artifact transitions.
- **Interactive Disc Dials & Vertical Pedestal Sliders:** Precision touch-disc wheels with draggable pucks, 360° hue rings, saturation radii, and independent luminance pedestal sliders.
- **6 Curated Cinematic Presets:** Blockbuster Teal & Orange, Vintage Kodak 500T, Moody Cyberpunk, Golden Hour Sunset, Bleach Bypass Silver, and Commercial Clean Pop.
- **Deterministic FFmpeg Filter Compilation:** Maps wheel vectors and luminance pedestal parameters into hardware-accelerated `colorbalance` and `eq` filter graphs for 4K video exports.

### 👤 AI Face Reshape & 3D Feature Sculpting Studio (v1.0.62)
- **Comprehensive 21-Parameter Sculpting Engine:** Complete micro-refinement covering face slimming, V-line jaw, jawbone width, pointy chin, chin length, cheekbones, forehead, temples, eye size/span/tilt/corner/elevation, nose slimming/bridge, mouth size, plump lip volume, and smile corner lift.
- **5 Curated Signature Aesthetic Presets:** Natural Polish (gentle subtle enhancements), V-Line Aesthetic (slim contour, pointy chin, wide eyes), Chiseled Jaw (masculine defined angles, refined bridge), Doll Face (large luminous eyes, compact chin, plump lips), and High Fashion Editorial (high cheekbones, razor bridge).
- **Interactive Viewport HUD & 3D Landmark Wireframe:** Dynamic cyan wireframe (`#00E5FF`) tracking facial contour, with touch-draggable landmark anchor dots for direct on-screen sculpt manipulation.
- **Deterministic Export Pipeline:** Compiles radial/pincushion optical distortion algorithms and texture boundary unsharp filters into hardware-accelerated 4K video exports.

### 🪄 AI Magic Eraser & Object Removal Pen Studio (v1.0.61)
- **Deep Inpainting & Boundary Texture Synthesis:** Seamlessly obliterates watermarks, logos, wires, photobombers, and facial blemishes with edge-preserving boundary reconstruction.
- **Interactive Multi-Tool Selection Suite:** Freehand Brush Pen with live circular reticle, precision Eraser to rub out mask boundaries, and Box Select for instant geometric watermark targeting.
- **Dynamic Pen Size & Feathering Controls:** Adjustable brush stroke width ($6\text{ to }100\text{ px}$) and soft edge feathering ($0\%\text{ to }100\%$) for seamless blending.
- **4 Specialized Removal Modes:** AI Magic Eraser (Deep Inpainting), Smart Delogo (fast bilateral interpolation), Privacy Blur (smooth Gaussian defocus), and Clone Stamp (exemplar texture synthesis).
- **Interactive Canvas HUD & Live Mask Overlay:** Real-time coral-red translucent highlight mask overlay (`#FF2D55`) with instant Undo/Redo history, mask inversion, and deterministic FFmpeg filter compilation into 4K video exports.

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
| **v1.0.67** | **Cinematic Vignette & Spotlight** | Optical smoothstep falloff, anamorphic oval, interactive aiming reticle, 6 color tints, 4K export |
| **v1.0.66** | **Cinematic Film Grain Studio** | 6 film stocks (35mm/16mm/Super8), polynomial luma masking, 7 presets, 4K export |
| **v1.0.65** | **Pro RGB Curves Studio** | 4-channel spline curves (Y/R/G/B), Fritsch-Carlson interpolation, 7 presets, 4K export |
| **v1.0.64** | **Creative Doodle Studio** | 6 brush modes (Pen, Neon, Highlighter, Arrow, Dashed, Eraser), Bezier smoothing, 4K export |
| **v1.0.63** | **Pro Color Wheels Studio** | Primary & Log wheels, LumaMix decoupling, Low/High Range crossover, 6 presets, 4K export |
| **v1.0.62** | **AI Face Reshape & 3D Sculpt** | 21-parameter facial sculpting, 5 aesthetic presets, interactive landmark wireframe, 4K export |
| **v1.0.61** | **AI Magic Eraser Pen** | Deep inpainting & smart delogo, interactive brush/eraser/box selection, live mask overlay |
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
