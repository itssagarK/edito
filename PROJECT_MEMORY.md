# PROJECT_MEMORY.md — Edito Architecture & System Blueprint

> **Status:** All Phases (0–10) Delivered & Released (`v1.0.0`)  
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

## 2. Directory Layout

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
│   ├── phase-7-spec.md            # Text & motion overlays spec (Complete)
│   ├── phase-8-spec.md            # FFmpeg export pipeline spec (Complete)
│   ├── phase-9-spec.md            # Undo/Redo & performance spec (Complete)
│   └── phase-10-spec.md           # Production release & distribution spec (Complete)
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
│   │   ├── history/               # Global undo/redo history engine & autosave
│   │   ├── export/                # FFmpeg graph builder, render progress & MP4 output
│   │   └── ...
│   ├── models/
│   │   ├── project.dart           # Root project schema
│   │   ├── track.dart             # Video / Audio / Overlay track definitions
│   │   ├── clip.dart              # Slice, in/out points, textOverlay, transitions, colorGrading, audioEffects
│   │   └── media_asset.dart       # Raw file references & metadata cache
│   └── main.dart                  # Application entry point
├── test/                          # Comprehensive unit & integration test suite
├── pubspec.yaml                   # Dependencies & asset manifests
└── PROJECT_MEMORY.md              # Living architecture document
```

---

## 3. Phase Delivery Roadmap

- **Phase 0:** Project Skeleton, CI/CD Pipeline & Home Shell 🟢 *(Done)*
- **Phase 1:** Media Import, Thumbnail Caching & Project Data Model 🟢 *(Done)*
- **Phase 2:** Multi-Track Timeline UI, Scrubbing, Trim & Split 🟢 *(Done)*
- **Phase 3:** Real-Time Preview Compositor (Sync Audio/Video) 🟢 *(Done)*
- **Phase 4:** Transitions & Speed Ramping (Time Remapping) 🟢 *(Done)*
- **Phase 5:** GLSL Color Grading & 3D LUT Pipeline 🟢 *(Done)*
- **Phase 6:** Audio Mixing & On-Device AI Voice Enhancement 🟢 *(Done)*
- **Phase 7:** Text, Titles & Animated Keyframe Overlays 🟢 *(Done)*
- **Phase 8:** FFmpeg Export Pipeline (Multi-format, 4K/1080p) 🟢 *(Done)*
- **Phase 9:** Performance Optimization, Proxy Rendering & Undo/Redo 🟢 *(Done)*
- **Phase 10:** Production Release & Distribution (`v1.0.0`) 🟢 *(Done)*

---

## 4. Pipeline Audit & Stabilization (Post v1.0.19)

In depth end-to-end trace and stabilization conducted across UI, Preview Compositor, and Native FFmpeg Export:

1. **State Unification & Gatekeeper Fixes**:
   - `ColorGradingConfig.isGraded`: Corrected to evaluate custom HSL shifts and tone curves so single-tab adjustments activate render pipelines.
   - Exposure math unified between preview matrix and FFmpeg `eq` filter using identical `0.15` EV scale factors.
2. **Preview Compositor Enhancements**:
   - Real-time vignette rendering added to `RealtimePreviewViewport` via radial alpha gradient to visually match FFmpeg export output.
   - Zero-overhead hardware texture fast path preserved when clips are un-graded identity.
3. **FFmpeg Export Pipeline Fixes**:
   - **Filter Order Clash Resolved**: `chromakey` is now applied *before* color grading/LUTs/vignette filters, ensuring color adjustments do not corrupt the raw keying threshold.
   - **Keyframe Motion Interpolation**: Added piecewise linear time-based interpolation to `OverlayCompilerService.generateFFmpegDrawText`, animating coordinates over export timeline.
   - **Custom Font & Box Styling**: Retains selected text ARGB hex color (`fontcolor=0x...`) and background box padding/alpha.
   - **PTS Scope Fix**: Added `isClipRelative` mode to `generateFFmpegDrawText` to resolve timestamp mismatch when burning text directly onto pre-concatenated video clips.
4. **Separability**:
   - Preview shader/viewport and FFmpeg command builder modifications are preserved in separate, isolated git commits.

---

## 5. Multi-Track Compositing, Chromakey Reordering & Audio Synchronization (Audit & Fixes)

1. **Multi-Track Layered Overlay Compositing**:
   - Replaced flawed sequential `concat` filter logic across multi-track exports with a proper layered overlay chain (`overlay=enable='between(t,START,END)':eof_action=pass`).
   - Base video track (Track 0) renders as the background canvas. Upper tracks composite on top with alpha transparency preserved (`format=yuva420p`), preventing multi-track exports from doubling duration or rendering green screen actors as black boxes.
2. **Proportional Font & Expression Quoting**:
   - Scaled text overlay font size proportionally based on target resolution height (`fontsize = (baseFontSize * outputHeight / 720).round()`), ensuring consistent typography across 720p, 1080p, and 4K renders.
   - Single-quoted `x='$xExpr'` and `y='$yExpr'` in `OverlayCompilerService` to prevent FFmpeg's filterchain parser from interpreting internal commas in piecewise linear keyframe expressions (`if(lt(...))`) as filter delimiters.
3. **Chromakey Pre-Scale Reordering (Order B)**:
   - Moved `chromakey` and `format=yuva420p` BEFORE `scale=...:flags=lanczos` and `pad` in `FFmpegCommandBuilder`.
   - Testing proved that Lanczos scaling before keying blends `#00FF00` background pixels with subject edges, creating an intermediate contaminated border ($\Delta G = +50$ green channel fringe at boundary pixels).
   - Keying at native source resolution first generates a pristine alpha matte; Lanczos scaling subsequently resamples color and alpha in unison without edge bleeding.
4. **Audio Pipeline Stabilization & Timeline Synchronization**:
   - **Cached Audio Presence (`hasAudio`)**: Added `hasAudio: bool` to the `MediaAsset` model, probed once during import via `MetadataProbeService` (using `ffprobe` when available) and cached directly on the model. This eliminates re-probing on export and prevents `Stream specifier ':a' matches no streams` crashes when exporting projects with audio-less video.
   - **Timeline Synchronization**: Audio filter chain reads the exact same `clip.startTimeMs` field as video PTS (`asetpts=PTS-STARTPTS+($timelineOffsetSec/TB)`), ensuring zero risk of audio and video drifting to different timeline offsets.
   - **Format Harmonization & Limiter**: Added `aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo` before `amix` to standardize sample rates across heterogeneous inputs, maintaining the brickwall limiter ceiling (`alimiter=limit=0.95:attack=5:release=50:asc=1`).
5. **Stress Test Hardening Across Non-Trivial Timeline Shapes**:
   - **Audio Delay Synchronization (`adelay`)**: Identified that FFmpeg's `amix` filter ignores packet PTS timestamps and starts consuming input streams immediately from sample 0. For clips starting mid-timeline (`startTimeMs > 0`), added `adelay=${clip.startTimeMs}|${clip.startTimeMs}:all=1` to prepend accurate silence samples, ensuring frame-accurate synchronization with video PTS.
   - **Transparent Padding for Aspect Ratio Mismatches (`black@0`)**: Upper video tracks with different aspect ratios (e.g. 9:16 portrait on a 16:9 canvas) previously used opaque black padding, occluding the underlying background canvas. Upper tracks (`tIdx > 0`) now convert to `yuva420p` prior to padding and apply `color=black@0` (transparent padding).
   - **Per-Input Framerate Normalization (`fps=fps=...:round=near`)**: Added input-level frame rate harmonization matching target export FPS to prevent jitter and frame drops during layered `overlay` evaluation when mixing heterogeneous sources (e.g. 24fps cinema + 30fps screen).
   - **Stress Test Suite**: Added 5 dedicated regression test cases in `test/multi_track_stress_test.dart` verifying multi-layer z-order, offset audio sync, silent asset omission, fps harmonization, and transparent pillarboxing.

---

## 6. Video Import Loading & Green Frame / Unintended LUT Display Resolution

Comprehensive investigation and resolution of the gallery import issue where imported videos appeared with a greenish tint or green LUT appearance:

1. **Root Cause Identification**:
   - **Uninitialized Android SurfaceTexture / GraphicBuffer**: On Android, when `VideoPlayerController.initialize()` completes, ExoPlayer is prepared but has not decoded/rendered frame 0 into the native `SurfaceTexture`. Unrendered GraphicBuffers in YUV colorspace default to $(Y=0, U=0, V=0)$, which converts mathematically to RGB $(0, 135, 0)$ — an opaque green rectangle.
   - **Skipped Initial Seek**: Because initial position and target duration both started at 0ms (`driftMs == 0 <= 80ms`) and playback was paused, the initial `seekTo` was bypassed. ExoPlayer never painted frame 0, leaving the green buffer visible on screen like a solid green LUT.
   - **Scoped Storage & Content URI Expiry**: Gallery picks returning transient `content://` URIs suffered permission revocation and MediaCodec file descriptor lockouts during background initialization.
   - **Starter Reel Residuals**: Creating a project with demo placeholder clips loaded a default `LutPreset.tealAndOrange` on the demo track, which lingered if placeholders were incompletely purged upon importing user clips.
2. **Key Fixes Implemented**:
   - **Explicit Initial Frame Priming**: Immediately after `newController.initialize()` in `VideoPlaybackBridgeService`, an explicit `seekTo(targetDuration)` is awaited before publishing the controller to `activeVideoController.value`. This forces ExoPlayer to decode and paint the first frame to the native `SurfaceTexture` before the widget renders.
   - **Pending Sync Queue**: Added `_hasPendingVideoSync` queue to ensure seek and scrub events requested while `_isInitializingVideo` is active are not dropped. Reduced paused scrub tolerance from 80ms to 30ms for instant frame updates.
   - **Persistent Local File Storage**: In `MediaPickerService`, introduced `_persistPickedFile` to safely copy picked gallery/camera videos and photos into the app's persistent cache (`media_<uuid>.mp4`), guaranteeing local file existence, direct OS file descriptor access, and immunity to Android scoped storage URI revocation.
   - **MediaCodec Hardware Decoder Release Grace Period**: In `MetadataProbeService`, added a 60ms delay after disposing probe controllers to ensure Android's asynchronous `MediaCodec` hardware decoder releases fully before the playback controller initializes.
   - **Starter Reel Cleanup & Playhead Reset**: In `MediaImportNotifier`, extended `isPlaceholderPath` to identify all demo clips (`starter_scene.mp4`, `Scene_Clip.mp4`, `Audio_Soundtrack.mp3`, `sample_*`), wiping demo tracks and resetting playhead to 0ms across both editor and preview providers when the first user video is imported.
   - **Viewport Stride Artifacts & Error Handling**: In `RealtimePreviewViewport`, wrapped `VideoPlayer` with `ClipRect` and an underlying black background container to eliminate GPU stride artifacts, and added `!controller.value.hasError` check.
   - **Color Matrix Bypass Verification**: Updated `ColorFilterCompilerService.isIdentity` to ensure vignette-only configurations (rendered via radial gradient) do not activate a GPU color filter matrix pass.

---

## 7. Caption Studio & Typography Engine (Phase 7 & 8 Overhaul)

Comprehensive enhancement of the captioning suite with professional short-form styling, typography, animations, and export compilation:

1. **Rich Typography & Styling Attributes (`TextOverlayConfig`)**:
   - Added `isBold`, `isItalic`, `isUnderline`, `isUppercase`, and `letterSpacing` for complete text formatting.
   - Added outline stroke parameters (`strokeWidth`, `strokeColor`) and background box styling (`boxCornerRadius`, `boxPadding`).
   - Added drop shadow customization (`shadowColor`, `shadowBlur`).
2. **Animation Pipeline**:
   - Expanded `TextAnimationType` to include: `none`, `popScale` (TikTok/Reels pop), `bounce` (punchy spring bounce), `fadeIn` (smooth cinematic fade), `slideUp`, `typewriter` (character-by-character reveal), `shimmer` (glow pulse), `zoomIn` (dramatic scale), and `karaoke` (word pulse).
   - Real-time preview animation in `RealtimePreviewViewport` based on elapsed clip offset.
   - FFmpeg `drawtext` expression compilation in `OverlayCompilerService` generating mathematical `fontsize`, `alpha`, and coordinate transforms.
3. **Caption Studio UI (`CaptionManagerSheet`)**:
   - **Live Animated Preview Canvas**: Displays the active caption in a simulated player box with a repeating 2.5-second animation loop.
   - **Font Picker**: Scrollable selector for 11 popular fonts (`Anton`, `Inter`, `Bebas Neue`, `Montserrat`, `Poppins`, `Roboto`, `Oswald`, `JetBrains Mono`, `Permanent Marker`, `Caveat`, `Pacifico`).
   - **Font Size & Quick Chips**: Slider from 14pt to 64pt with quick size buttons (`S 18`, `M 24`, `L 30`, `XL 38`, `XXL 48`).
   - **Color Palettes**: 10 text color swatches, 9 background box styles, and 6 outline stroke colors.
   - **Typography Toggles**: One-tap toggles for Bold, Italic, ALL CAPS, and Underline.
   - **Preset Carousel**: 8 one-tap presets (`TikTok Viral`, `Cinema Subtitle`, `Neon Podcast`, `Fire Punch`, `Comic Hero`, `Minimal Clean`, `Retro Typewriter`, `Pastel Dream`).
   - **Global or Per-Line Application**: "Apply to All" toggle allowing uniform project styling or distinct individual line customizations.

---

## 8. Dedicated Borders & Frames Studio and Header & Footer Studio (v1.0.22 Release)

Two dedicated, professional editing modules introduced separately into the primary editor toolbar to empower short-form creators with viral social styling, card frames, cinematic borders, and news/podcast banners:

1. **Borders & Frames Studio (`VideoBorderConfig`, `VideoBorderSheet`, `VideoBorderCompilerService`)**:
   - **Styles Supported**: Solid frame border, glowing neon aura with customizable intensity & spread, dual-color gradient border, floating rounded card, 35mm motion picture film strip with sprocket perforations, vintage Polaroid photo frame with thick bottom margin, cinematic widescreen letterbox bars, and retro CRT television curved bezel.
   - **Full Parameter Control**: Border thickness/width slider (2px to 48px) with quick-selection chips (`4px`, `10px`, `18px`, `28px`, `40px`), corner rounding/radius (0px to 48px), opacity slider, primary & secondary 10-swatch color pickers, and glow intensity slider (0.0 to 2.0).
   - **One-Tap Presets**: Neon Cyan Glow, Gold Luxury Frame, 35mm Film Strip, Vintage Polaroid, Cinematic Letterbox, Rounded Card, Clean Minimalist, Retro TV Bezel.
   - **Realtime Preview & HUD**: Dynamic custom painters (`_GradientBorderPainter`, `_FilmStripBorderPainter`) in `RealtimePreviewViewport` with instant playback response and floating HUD status badge.
   - **FFmpeg Filter Compilation**: Proportional resolution scaling against 720p baseline generating layered `drawbox` chains with alpha blending (`yuva420p` compatible).

2. **Header & Footer Studio (`HeaderFooterConfig`, `HeaderFooterSheet`, `HeaderFooterCompilerService`)**:
   - **Dedicated Dual Banners**: Top hook headline/header banner and bottom social CTA/handle footer banner designed for TikTok, Reels, YouTube Shorts, and podcasts.
   - **Styles & Effects**: Solid banner, gradient strip, glassmorphic frosted translucent, floating pill badge, neon border accent, and minimal transparent.
   - **Typography & Formatting**: Full Google Fonts support (`Inter`, `Montserrat`, `Anton`, `Poppins`, `Oswald`, `Bebas Neue`, `Roboto`, `Playfair Display`), font size sliders with proportional resolution scaling, font and background color pickers, bold & uppercase switches.
   - **Badges & Animations**: Leading emoji badge picker for headers (🔥, 🔴, 🎙️, 💡, ⚡, 🎬, etc.) and footer icon badges (📲, 📢, 💬, 🔔, 👤, etc.), with entrance animation options (`fadeIn`, `slideIn`, `pulse`, `none`).
   - **One-Tap Presets**: Viral Social Reels, Breaking News Alert, Podcast Studio, Cinema Letterbox, YouTube Tutorial, Aesthetic Pastel Quote.
   - **Export Engine**: Compiles into parameterized FFmpeg `drawbox` and `drawtext` filters with animated entrance expressions (`y=if(lt(t,0.3),...)`) for frame-accurate renders across 720p, 1080p, and 4K exports.

3. **Domain Model & Toolbar Integration**:
   - Integrated `VideoBorderConfig` and `HeaderFooterConfig` directly onto `Clip` domain model with zero-overhead `const` defaults.
   - Added `EditorTool.borders` and `EditorTool.headerFooter` as separate tools in `EditingToolbar` and `editor_screen.dart`, providing dedicated modals with interactive live previews and "Apply to All Clips" global toggles.
   - Verified via comprehensive test suite in `test/borders_and_header_footer_test.dart`.

---

## 9. Professional Color Grading Suite & HD Video Converter Studio (v1.0.23 Release)

Two major flagship video engineering suites added to empower mobile filmmakers, content creators, and post-production workflows:

1. **Professional Color Grading Suite (`lib/features/color_grading/`)**:
   - **3-Way Color Wheels (`ColorWheelWidget`, `ColorWheelValue`)**:
     - Lift (Shadows / Pedestal), Gamma (Midtones), Gain (Highlights), and Offset (Global Master) wheels.
     - Interactive 2D chromatic puck dragging with angle ($0^\circ-360^\circ$), saturation ($0.0-1.0$), and vertical luminance slider ($-1.0$ to $+1.0$).
     - Dead-zone center snap for easy neutralization and one-tap reset per wheel.
   - **Live RGB Waveform Scopes Monitor (`ColorScopesWidget`)**:
     - Real-time custom-painted 0–100 IRE grid displaying R, G, and B channel waveform curves that react dynamically to exposure, contrast, temperature, tint, lift, gamma, and gain adjustments.
   - **13 Film Stock & Cinematic Look Presets**:
     - Arri Alexa Log-C, Kodak Portra 500T, Fuji Velvia 50, Bleach Bypass, Matrix Emerald, Fuji Eterna, Commercial Pop, Vintage 70s, Blockbuster Teal & Orange, Warm Golden Hour, Moody Cyberpunk, Noir B&W, and Natural Standard.
     - Global LUT intensity slider ($0.0-1.0$) for precise blend control.
   - **Pro Tonality & Dynamic Adjustments**:
     - Added dedicated `whites`, `blacks`, `fade` (filmic black point lift), `clarity` (midtone contrast enhancement), and `sharpness` sliders alongside exposure, contrast, saturation, temperature, tint, highlights, shadows, and vignette.
   - **Dual Engine Pipeline**:
     - Real-time 4x5 Rec.709 GPU color matrix compiled via `ColorFilterCompilerService.buildColorMatrix` for 60fps viewport preview.
     - Export filter compilation generating native FFmpeg `colorbalance` (shadows, midtones, highlights) and `curves` filters for deterministic render fidelity.

2. **HD Video Converter Studio (`lib/features/hd_converter/`)**:
   - **Dedicated Upscaling & Video Enhancement**:
     - Target resolutions: 720p HD ($1280\times720$), 1080p Full HD ($1920\times1080$), 1440p 2K QHD ($2560\times1440$), 4K Ultra HD ($3840\times2160$), and 8K Cinema UHD ($7680\times4320$).
     - Advanced scaling algorithms: Lanczos 3-Lobe Sinc (`scale=...:flags=lanczos`), Bicubic Spline (`scale=...:flags=bicubic`), Super-Res Detail Synthesizer (`flags=lanczos+accurate_rnd`), Bilinear Fast (`flags=bilinear`).
   - **Pro Processing & Restoration Pipeline**:
     - **AI Noise Reduction (`denoiseLevel`)**: Temporal 3D spatio-temporal de-noising (`hqdn3d`).
     - **Social/MPEG Deblocking (`deblock`)**: Eliminates macroblock compression artifacts from social media downloads (`deblock=filter=weak:block=4`).
     - **Super-Resolution Detail Clarity (`clarity`) & Edge Sharpening (`sharpenAmount`)**: High-pass unsharp masking (`unsharp=5:5:...`).
     - **Dynamic Range Contrast Expansion (`dynamicRangeBoost`)**: Gamma and contrast remapping (`eq=contrast=...:gamma=...`).
   - **Interactive Studio UI (`HdConverterSheet`)**:
     - Live Before/After split-screen slider card showing real-time comparison.
     - 5 one-tap optimization presets: *Social Media Viral 1080p*, *Cinematic 4K Remaster*, *Vintage Clean & Denoise*, *Anime & Animation Crisp*, *Fast 720p Mobile Share*.
     - Viewport HUD status badge (`💎 1080p FHD CONVERTED`, `💎 4K UHD CONVERTED`, etc.) reflecting converter state.
   - **Architecture & Export Integration**:
     - `HdConverterConfig` integrated onto `Clip` domain model with `const` defaults.
     - Chained in `FFmpegCommandBuilder` with optimal filter ordering: deblock & denoise first, followed by scale & pad, unsharp detail synthesis, and dynamic range boost.
   - Fully verified by test suite `test/color_grading_and_hd_converter_test.dart`.

---

## 10. Multi-Shape Masking Studio & Pro Compositor (v1.0.24 Release)

The first flagship pro-compositing module in Edito's high-end evolution, enabling creators to perform split screens, spotlights, floating video cards, anamorphic letterbox mattes, and creative cutouts:

1. **Geometry & Shape Models (`lib/features/masking/models/mask_config.dart`)**:
   - **Supported Mask Shapes**:
     - `linear`: Split screen dividing plane with continuous rotation ($0^\circ-360^\circ$) and feathering.
     - `radial`: Elliptical or circular spotlight focus with independent width/height radii.
     - `rectangle`: Card mask with adjustable corner roundness ($0.0-1.0$, sharp box to capsule).
     - `filmStrip`: 2.39:1 anamorphic letterbox bar cutout.
     - `heart`: Smooth cubic-bezier heart cutout for creative aesthetic vlogs.
     - `star`: 5-point geometric star matte for pop social videos.
   - **Parameter Controls**:
     - Normalized center positioning (`centerX`, `centerY` $\in [0.0, 1.0]$).
     - Scale/dimensions (`width`, `height` $\in [0.05, 2.0]$).
     - Rotation angle ($0^\circ-360^\circ$) with quick buttons ($0^\circ, 45^\circ, 90^\circ, 180^\circ, 270^\circ$).
     - Edge feathering / softness falloff ($0.0-1.0$).
     - Invert mask switch (cutout vs spotlight window).
     - Master opacity slider ($0.0-1.0$).
   - **7 One-Tap Presets**: *Split Horizontal*, *Split Vertical*, *Spotlight Circle*, *Rounded Card*, *Letterbox Cutout*, *Dreamy Heart*, *Pop Star*.

2. **Dual-Engine Compositor**:
   - **Real-Time Preview**:
     - Vector path generation via `MaskCompilerService.buildMaskPath` wrapped in `MaskPreviewWrapper` / `MaskClipper`.
     - Zero dropped frames at 60fps in the viewport canvas with real-time HUD status badge (`🎭 MASK: RADIAL`, `🎭 MASK: LINEAR (INV)`).
   - **Native FFmpeg Export Pipeline**:
     - Compiles into `format=yuva420p` + mathematical `geq` alpha channel expression (`geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='...'`).
     - Evaluates rotated coordinates, elliptical distance falloff, linear edge sigmoid ramps, and inversion algebraically at native render resolution.
     - Seamlessly composites with upper video tracks and project canvas background.

3. **Editor Shell & Toolbar Integration**:
   - Integrated as `EditorTool.mask` in primary `EditingToolbar` and `DockedToolPanel` with live peek mode and "Apply to all clips" support.
   - Verified by comprehensive test suite in `test/masking_test.dart`.

---

## 11. Pro Blending Modes & Layer Compositor Studio (v1.0.25 Release)

Photoshop and Premiere-style layer blending suite enabling creative multi-track compositing for light leaks, fire, dust, textures, film grunge, and sci-fi energy glows:

1. **Blending Modes Supported (`lib/features/blending/models/blend_mode_config.dart`)**:
   - **Categorized Modes**:
     - **Standard**: `normal` (standard alpha layer stacking).
     - **Lighten (Hides Black)**: `screen` (essential for light leaks, lens flares, fire, smoke, bokeh), `lighten`, `colorDodge` (super-charged neon magic & energy glows).
     - **Darken (Hides White)**: `multiply` (essential for paper textures, film grain, dirty lens overlays), `darken`, `colorBurn` (deep burnt exposure).
     - **Contrast**: `overlay` (rich cinematic contrast), `softLight` (diffused organic lighting), `hardLight` (punchy high contrast).
     - **Inversion / FX**: `difference` (psychedelic chromatic inversion), `exclusion` (subtle tonal inversion).
   - **Parameter Controls**:
     - Layer Opacity slider ($0\%$ to $100\%$).
     - Presets: *Light Leak (Screen 85%)*, *Shadows (Multiply 75%)*, *Cinematic (Overlay 80%)*, *Soft Glow (SoftLight 90%)*, *Magic Energy (ColorDodge 70%)*, *Psychedelic (Difference 100%)*.

2. **Dual-Engine Compositing Pipeline**:
   - **Real-Time GPU Preview**:
     - Flutter hardware layer compositing via `_RenderLayerBlend` / `BlendModeWrapper` using `canvas.saveLayer(..., Paint()..blendMode = ...)`.
     - Zero dropped frames at 60fps in the preview viewport with live HUD badge (`✨ BLEND: SCREEN (85%)`).
   - **Native FFmpeg Export Pipeline**:
     - Compiles two-input filtergraph via `BlendModeCompilerService.generateFFmpegLayerCompositor`.
     - Uses native FFmpeg `blend=all_mode=...:all_opacity=...` for upper video tracks blended over the underlying canvas, or standard alpha `overlay` when in normal mode.
     - In-stream opacity handling via `colorchannelmixer=aa=...`.

3. **Editor Shell & Toolbar Integration**:
   - Accessible via `EditorTool.blend` in primary `EditingToolbar` and `DockedToolPanel` with live peek mode and "Apply blend mode to all project clips" toggle.
   - Verified by comprehensive test suite in `test/blending_test.dart`.

---

## 12. Universal Transform Keyframing Suite (v1.0.26 Release)

CapCut Pro and After Effects style universal keyframing engine allowing fine-grained spatial and opacity animations on any timeline clip:

1. **Universal Keyframe Model & Easing Math (`lib/features/overlays/models/keyframe.dart`)**:
   - **Keyframe Attributes**: `timeOffsetMs`, `positionX` ($0.0-1.0$), `positionY` ($0.0-1.0$), `scale` ($0.1-5.0$), `rotation` ($-360^\circ$ to $+360^\circ$), `opacity` ($0.0-1.0$), and `easing`.
   - **Supported Easing Curves**:
     - `linear`: Standard constant-velocity interpolation ($t$).
     - `easeIn`: Quadratic acceleration ($t^2$).
     - `easeOut`: Quadratic deceleration ($1 - (1-t)^2$).
     - `easeInOut`: S-curve smooth cinematic transition ($2t^2$ / $1 - (-2t+2)^2/2$).
     - `bounce`: Elastic spring overshoot bounce simulation.

2. **Evaluator & Presets Engine (`lib/features/keyframes/services/keyframe_evaluator_service.dart`)**:
   - Time-indexed binary search and continuous curve evaluation via `evaluateTransformAt(keyframes, offsetMs)`.
   - **6 One-Tap Cinematic Presets**:
     - *Ken Burns Zoom In*: Subtle documentary slow zoom ($1.0 \to 1.3\times$).
     - *Slow Zoom Out*: Cinematic establishing pullback ($1.35 \to 1.0\times$).
     - *Slide In Left*: Dynamic entry pan from screen edge ($X: -0.5 \to 0.5$).
     - *Spin & Pop*: High-energy social media hook zoom with rotational spin ($0^\circ \to 360^\circ$).
     - *Cinematic Fade*: Atmospheric fade in and fade out ($0.0 \to 1.0 \to 0.0$).
     - *Dutch Angle Roll*: Dramatic action tilt ($-15^\circ \to +15^\circ$).

3. **Dual-Engine Animation Execution**:
   - **Real-Time Preview Canvas**:
     - `KeyframeTransformWrapper` computes real-time affine matrix transforms, fractional translation, scaling, and Skia opacity on every frame tick (60fps).
     - Integrated inside `RealtimePreviewViewport` with live viewport HUD status badge (`💎 KEYFRAMES (N)`).
   - **Deterministic FFmpeg Export Compiler**:
     - `KeyframeEvaluatorService.generateFFmpegTransformFilters` dynamically generates nested piecewise linear FFmpeg expressions (`if(between(t,...),...)`).
     - Constructs native video filters: `scale=eval=frame:w='...':h='...'`, `rotate=a='...':ow='...':oh='...'`, and `pad` / translation coordinates.

4. **Dedicated Keyframe Studio UI Sheet (`lib/features/keyframes/presentation/widgets/keyframe_studio_sheet.dart`)**:
   - Interactive mini timeline scrubber showing diamond markers $(\diamond)$ for all placed keyframes.
   - Stepper jump buttons $(\blacktriangleleft \diamond / \diamond \blacktriangleright)$ to navigate directly between keyframe points.
   - Add/Remove diamond toggle button $(\diamond^+ / \diamond^-)$ with real-time detection at current playhead.
   - Sliders for Scale, Rotation, Position X, Position Y, and Opacity.
   - Easing curve selector chips and One-Tap Preset horizontal carousel.
   - Accessible from Editor Toolbar and docked panel via `EditorTool.keyframes`.
   - Verified by comprehensive test suite in `test/keyframe_suite_test.dart`.

---

## 13. Timeline Workflow Suite: Freeze Frame, Video Reversal & Audio Detachment (v1.0.27 Release)

Professional CapCut Pro, DaVinci Resolve, and Premiere Pro style clip manipulation engine enabling non-linear clip workflows:

1. **Data Model Attributes (`lib/models/clip.dart`)**:
   - `isFreezeFrame: bool`: Denotes a static frozen frame clip held still for a specified duration.
   - `freezeSourceMs: int?`: Exact timestamp in source video media where the frame was captured.
   - `isReversed: bool`: Flags bidirectional reverse playback for video frames and audio packets.

2. **Non-Linear Timeline Editing Engine (`lib/features/timeline/services/timeline_editing_service.dart`)**:
   - **Freeze Frame (`freezeFrame`)**:
     - Accurately computes playhead position inside target clip (`sourceInMs + offset * speed`).
     - Splits clip dynamically (mid-clip, head, or tail).
     - Inserts a freeze frame clip (`freezeDurationMs = 3000ms`, `isMuted = true`, `isFreezeFrame = true`).
     - Ripples and time-shifts all subsequent clips on the track seamlessly without overlapping or gaps.
     - Recalculates master project duration.
   - **Video & Audio Reversal (`toggleReverseClip`)**:
     - Toggles `isReversed` flag on the target clip.
     - Instant preview update and timeline indicator update.
   - **Audio Detachment / Extraction (`extractAudio`)**:
     - Mutes original video clip (`isMuted: true`, `volume: 0.0`).
     - Discovers an existing `TrackType.audio` track or creates a new dedicated audio track.
     - Spawns an independent `Clip` on the audio track synchronized with the original video's start time and duration.
     - Permits independent audio trimming, volume curves, voice modulation, and ducking.
   - **Clip Duplication (`duplicateClip`)**:
     - Clones clip with distinct UUID and appends immediately adjacent on the track.

3. **Dual-Engine Compositor & Hardware Decoders**:
   - **Real-Time Preview Canvas (`VideoPlaybackBridgeService` & `RealtimePreviewViewport`)**:
     - During freeze frames, video player stays paused and clamped to `freezeSourceMs`, holding the frame without glitching.
     - During reversed clips, scrub and playback calculate local media offset backwards from `sourceOutMs`.
     - Displays live viewport HUD status badges: `❄️ FREEZE FRAME` and `⏪ REVERSED`.
   - **Deterministic FFmpeg Export Engine (`FFmpegCommandBuilder`)**:
     - Freeze frames compile with `trim=start=...:duration=0.04,fps=...,tpad=stop_mode=clone:stop_duration=...,trim=duration=...,setpts=PTS-STARTPTS`, holding the exact frame while omitting audio streams (silence).
     - Reversed clips compile with `reverse` in the video filterchain and `areverse` in the audio filterchain.

4. **UI Studio & Timeline Integration**:
   - **Floating Timeline Context Bar (`TimelineContextBar`)**:
     - One-tap buttons for `Split`, `Duplicate`, `Freeze` (❄️), `Reverse` (⏪), `Extract Audio` (🎵), `Trim Start`, `Trim End`, and `Delete`.
   - **Timeline Clip Badges (`TimelineClipWidget`)**:
     - Shows `❄️ FREEZE`, `⏪ REV`, and `🔇` badges directly on clip representations.
   - **Dedicated Studio Sheet (`ClipWorkflowSheet`)**:
     - Full clip metrics overview, duration slider for freeze frame insertion, forward/reverse playback toggle card, and audio extraction action.
     - Accessible from Toolbar via `EditorTool.clipWorkflow` ('Clip Actions') and docked editing panel.
   - Verified by comprehensive test suite in `test/clip_workflow_test.dart`.

---

## 14. Cinematic Speed Curve Ramping Suite & Pitch Preservation (v1.0.28 Release)

CapCut Pro and Premiere Pro style dynamic speed curve ramping engine with optical-flow motion interpolation and pitch preservation:

1. **Enhanced Speed Presets & Data Model (`lib/features/speed/models/speed_curve_preset.dart`)**:
   - **Supported Curve Presets (`SpeedCurveType`)**:
     - `constant`: Uniform rate across whole clip ($0.1\times-10.0\times$).
     - `montage`: Dynamic pulse ($2.0\times \to 0.4\times \to 2.0\times$) for action vlogs.
     - `hero`: Classic hero shot ($1.0\times \to 0.25\times \to 1.0\times$) emphasizing dramatic moments.
     - `bulletTime`: Extreme matrix-style time drop ($1.0\times \to 0.1\times \to 1.0\times$).
     - `jumpCut`: Beat-matched rush ($3.0\times \to 1.0\times$).
     - `flashIn`: High-speed entry transition ($5.0\times \to 1.0\times$).
     - `flashOut`: Exponential acceleration rush ($1.0\times \to 5.0\times$).
     - `custom`: Fully customizable multi-point Bezier curve.
   - **Configuration Options (`SpeedCurveConfig`)**:
     - `isSmoothSlowMo: bool`: Toggles optical-flow motion interpolation (`minterpolate`) for artifact-free ultra slow motion.
     - `enablePitchCorrection: bool`: Toggles natural vocal pitch preservation vs vinyl record/tape pitch modulation.
     - `curvePoints: List<CurvePoint>`: Normalized 2D coordinates ($X \in [0.0, 1.0]$, $Y \in [0.1, 8.0]$).

2. **Mathematical Integration & Evaluation Engine (`lib/features/speed/services/speed_ramping_service.dart`)**:
   - **Trapezoidal Integration**: `calculateSourceOffset` computes exact continuous media frames by integrating speed curves along the timeline: $\int_0^t v(\tau) d\tau$.
   - **Effective Average Speed**: `calculateEffectiveAverageSpeed` determines exact timeline dilation factor for duration re-timing.
   - **Audio Tempo Chaining (`generateAudioSpeedFilter`)**:
     - Resolves FFmpeg's intrinsic `atempo` range limitation ($[0.5, 2.0]$) by safely chaining multiple stages (e.g. $4.0\times \to \text{atempo}=2.0,\text{atempo}=2.0$, $0.25\times \to \text{atempo}=0.5,\text{atempo}=0.5$).
     - Pitch modulation mode (`enablePitchCorrection: false`) uses `asetrate=48000*SPEED,aresample=48000` for tape speed effects.
   - **Video Filter Compilation (`generateFFmpegVideoSpeedFilters`)**:
     - Produces deterministic `setpts=PTS/SPEED` expressions.
     - Automatically chains `minterpolate=fps=FPS:mi_mode=mci:mc_mode=aobmc:vsbmc=1` when `isSmoothSlowMo` is active and speed $< 0.95\times$.

3. **Interactive Visual Curve Editor (`lib/features/speed/presentation/widgets/speed_curve_graph_widget.dart`)**:
   - Touch-draggable 2D graph with Catmull-Rom cubic spline interpolation and under-curve glowing gradient.
   - Interactive handle nodes with touch detection radius and real-time numeric speed bubbles.
   - 1.0x baseline reference line and speed markers ($0.5\times, 1.0\times, 2.0\times, 4.0\times$).
   - Dynamic point addition $(+)$ and removal $(-)$.

4. **Studio UI Sheet (`lib/features/speed/presentation/widgets/speed_ramping_sheet.dart`)**:
   - Dual tabs: Standard Multiplier Slider ($0.1\times-8.0\times$) + Dynamic Curves Canvas & Presets Carousel.
   - Quick toggles for Pitch Preservation and Optical-Flow Smooth Slow-Mo.
   - Verified by comprehensive test suite in `test/speed_suite_test.dart`.

---

## 15. Pro Chroma Key & Advanced Color Spill Suppressor Suite (v1.0.29 Release)

Hollywood and broadcast-level green/blue/luma keying engine with mathematical color spill neutralization:

1. **Enhanced Chroma & Luma Configuration (`lib/features/chroma/models/chroma_key_config.dart`)**:
   - **Supported Keying Modes**:
     - *Green Screen Studio*: Pure lime/chroma green keying (`0xFF00FF00`).
     - *Blue Screen Stage*: Deep cobalt/stage blue keying (`0xFF0055FF`).
     - *Cyber Cyan*: Electronic turquoise keying (`0xFF00FFFF`).
     - *Magenta / Pink Stage*: Pop neon magenta keying (`0xFFFF0055`).
     - *Luma Key Black (Fire/Smoke)*: Threshold keying of pure black backgrounds (`0xFF000000`).
     - *Luma Key White (Clouds/Snow)*: Threshold keying of pure white backgrounds (`0xFFFFFFFF`).
     - *Custom Eyedropper Hex*: Any 24-bit RGB keying target.
   - **Parameter Controls**:
     - `similarity`: Color sensitivity threshold ($0.05-0.50$).
     - `smoothness`: Edge feathering & transition softness ($0.01-0.35$).
     - `spill`: Color spill suppression intensity ($0.0-0.40$).
     - `edgeChoke`: Inward border clipping ($0.0-0.20$).
     - `isLumaKey`: Dedicated black/white luminance keying switch.

2. **Dual-Engine Compositor & Spill Neutralizer (`lib/features/chroma/services/chroma_key_compiler_service.dart`)**:
   - **Real-Time Preview Canvas (`ChromaKeyPreviewWrapper`)**:
     - Computes a dynamic 4x5 Skia GPU color filter matrix via `generateSpillMatrix`.
     - Attenuates green/blue channel reflections directly on actor skin, clothing, and hair in real-time (60fps).
     - Live viewport HUD status badge: `🟢 CHROMA: GREEN (15%)`, `🔵 CHROMA: BLUE (20%)`, or `⚫ LUMA KEY: BLACK (25%)`.
   - **Deterministic FFmpeg Export Compiler**:
     - Keying occurs strictly *before* Lanczos scaling and padding to eliminate border interpolation fringing.
     - Compiles `chromakey=color=$hex:similarity=...:blend=...` + `format=yuva420p`.
     - Automatically chains `despill=type=green:mix=...:expand=0.1` or `despill=type=blue:mix=...` to remove green/blue halos on exported video.

3. **Chroma Studio UI Sheet (`lib/features/chroma/presentation/widgets/chroma_key_sheet.dart`)**:
   - 6 one-tap studio presets carousel (*Green Screen*, *Blue Screen*, *Cyber Cyan*, *Magenta*, *Luma Black*, *Luma White*).
   - Hex color indicator with quick color button palette.
   - Precision sliders for Similarity, Edge Smoothness, Spill Suppression, and Edge Choke.
   - Verified by comprehensive test suite in `test/chroma_suite_test.dart`.

---

## 16. Audio Ducking, Voice Isolation & Parametric EQ Studio (v1.0.30 Release)

Broadcast-level mastering, dynamic sidechain auto-ducking, AI voice isolation, and parametric 3-band equalizer studio:

1. **Audio Effects & Equalizer Configuration (`lib/features/audio/models/audio_effects_config.dart`)**:
   - **Vocal Isolation Modes (`VocalIsolationMode`)**:
     - `none`: Flat pass without isolation filtering.
     - `cleanSpeech`: Speech presence enhancement with adaptive de-noising.
     - `isolateVocals`: Aggressive formant bandpass ($95\text{Hz}-8.5\text{kHz}$), speech formant amplification ($1.2\text{kHz}$ & $2.8\text{kHz}$), and deep neural FFT noise gating (`afftdn=nr=...:nf=-50`).
     - `removeVocals`: Center-channel cancellation (`stereotools=mlev=0.04:slev=1.35`) for karaoke and instrumental backing track creation.
   - **Parametric Equalizer Presets (`EqualizerPreset`)**:
     - `flat`: Neutral uncolored response.
     - `podcastWarmth`: Low $+4.5\text{dB}$ ($120\text{Hz}$), Mid $+2.5\text{dB}$ ($3\text{kHz}$), High $+1.5\text{dB}$ ($10\text{kHz}$), HPF $80\text{Hz}$.
     - `bassBoost`: Low $+7.0\text{dB}$ ($90\text{Hz}$), Mid $-1.0\text{dB}$ ($1\text{kHz}$).
     - `trebleSparkle`: High $+6.5\text{dB}$ ($12\text{kHz}$), Mid $+1.5\text{dB}$ ($3.5\text{kHz}$).
     - `vocalAir`: High $+5.0\text{dB}$ ($12\text{kHz}$), Mid $+3.0\text{dB}$ ($4\text{kHz}$), Low $-2.0\text{dB}$.
     - `telephone`: Low $-12\text{dB}$, High $-12\text{dB}$, Mid $+6\text{dB}$ ($1.8\text{kHz}$), HPF $400\text{Hz}$, LPF $3.5\text{kHz}$.
     - `deMuddy`: Mid $-4.5\text{dB}$ ($450\text{Hz}$ boxiness cut), High $+2.0\text{dB}$, HPF $80\text{Hz}$.
     - `custom`: Fully free-form interactive frequency and gain curve.
   - **Smart Auto-Ducking Controls**:
     - `isDuckingEnabled`: Dynamic speech-aware sidechain volume lowering.
     - `duckingAttenuation`: Attenuation depth ($0.05-0.60$, default $0.30$ / $-10\text{dB}$).
     - `duckingAttackMs`: Fade-in attack ramp ($10-300\text{ms}$).
     - `duckingReleaseMs`: Recovery release ramp ($50-1200\text{ms}$).
   - **Sibilance De-Esser**:
     - `deEsserIntensity`: Frequency-specific compressor ($4\text{kHz}-8\text{kHz}$) reducing harsh 's' and 't' transients (`deesser=i=...:m=0.5:f=0.5:s=o`).
   - **Voice Booster & Limiter Safeguard**:
     - Master pre-amp boost up to $+15\text{dB}$ with strict true-peak brickwall ceiling (`alimiter=limit=0.95:attack=5:release=50:asc=1`) preventing digital clipping.

2. **Mathematical Audio Processing Engines**:
   - **Dynamic Ducking Engine (`AudioDuckingService`)**:
     - `getForegroundSpeechIntervals`: Aggregates active speech intervals from foreground video tracks and merges near-contiguous boundaries.
     - `calculateDuckingFactor`: Computes real-time smooth attack/release ramps for live viewport playback and timeline scrubbing.
     - `buildDuckingVolumeFilter`: Compiles exact frame-evaluated FFmpeg volume expressions (`volume=eval=frame:volume='if(between(t,...),...)'`) during multi-track export.
   - **Filterchain Compiler (`AIVoiceEnhancerService`)**:
     - Compiles chained biquad equalizers, high-pass and low-pass cuts, vocal isolation formants, de-esser, compand compressors, and volume envelopes.
     - `getAudioBadge`: Emits live viewport HUD badges (`🎙️ VOCAL ISOLATE (80%)`, `🎵 INSTRUMENTAL`, `🎚️ EQ: PODCAST WARMTH`, `🦆 AUTO-DUCKING`).

3. **Interactive Visual Curve Canvas (`ParametricEQCurveWidget`)**:
   - Logarithmic frequency axis ($20\text{Hz}-20\text{kHz}$) with grid markers at $100\text{Hz}, 1\text{kHz}, 10\text{kHz}$.
   - dB gain axis ($-15\text{dB} \to +15\text{dB}$) with $0\text{dB}$ center reference line.
   - Real-time biquad response curve with neon glow gradient stroke and filled area.
   - Touch-draggable interactive node handles for Low Shelf, Mid Bell, and High Shelf with floating tooltip metrics.

4. **Multi-Tab Studio Sheet (`AudioMixerSheet`)**:
   - 4 dedicated tabs: **🎚️ EQ Studio**, **🎙️ Vocal Studio**, **🦆 Ducking & Levels**, and **🔥 Voice FX & Booster**.
   - Verified by comprehensive test suite in `test/audio_suite_test.dart`.

---

## 17. Cinematic Motion VFX & Visual Effects Studio (v1.0.31 Release)

Hollywood-grade optical styling, vintage analog emulation, digital chromatic aberration, and dynamic motion FX engine:

1. **VFX Configuration & Preset Modes (`lib/features/vfx/models/vfx_config.dart`)**:
   - **Supported Effect Modes (`VfxType`)**:
     - `filmGrain`: Authentic 35mm/16mm emulsion grain texture with temporal uniform noise.
     - `rgbGlitch`: Digital chromatic aberration and horizontal red/blue channel split displacement.
     - `lensBlur`: Soft optical depth-of-field Gaussian lens defocus.
     - `vhsVintage`: 80s/90s analog camcorder CRT scanlines, desaturated tape warmth, and noise.
     - `vignette`: Darkened optical perimeter falloff focusing attention on the subject.
     - `lightLeak`: Warm anamorphic golden hour sun flare pulses and bloom.
     - `cameraShake`: High-energy organic handheld camera tremor.
     - `radialZoom`: High-velocity action zoom blur radiating from the center.
   - **Precision Parameters**:
     - `intensity`: Master blend factor ($0.05-1.0$).
     - `speed`: Motion pulse & frequency multiplier ($0.1-3.0$).
     - `grainSize`: Texture scale ($1.0-5.0$).
     - `rgbOffset`: Chromatic pixel shift ($1.0-30.0\text{px}$).
     - `blurRadius`: Defocus radius ($1.0-25.0\text{px}$).
     - `vignetteRadius` & `vignetteSoftness`: Geometric falloff controls.
     - `shakeAmplitude`: Handheld jitter amplitude ($2.0-30.0\text{px}$).

2. **Dual-Engine Real-Time Compositor & Export Compiler**:
   - **Real-Time Preview Canvas (`VfxPreviewWrapper`)**:
     - Skia hardware-accelerated Gaussian defocus (`ImageFilter.blur`), scale transformation, procedural 35mm grain particle simulation (`_FilmGrainPainter`), chromatic fringe bands (`_RgbGlitchPainter`), CRT scanlines (`_VhsScanlinePainter`), and radial vignette gradients.
     - Viewport HUD status badge: `🎞️ FILM GRAIN (45%)`, `⚡ RGB GLITCH (8px)`, `🌫️ LENS BLUR (8px)`, `📼 RETRO VHS`, `🎬 VIGNETTE`, `☀️ LIGHT LEAK`, `📳 CAMERA SHAKE`, `🚀 RADIAL ZOOM`.
   - **Deterministic FFmpeg Export Compiler (`VfxCompilerService`)**:
     - `filmGrain`: `noise=alls=...:allf=t+u`.
     - `rgbGlitch`: Native FFmpeg chromatic aberration `rgbashift=rh=$shift:bh=-$shift`.
     - `lensBlur`: `gblur=sigma=...:steps=2`.
     - `vhsVintage`: `curves=all='0/0 0.5/0.46 1/0.95':r='0/0 1/0.92':b='0/0.06 1/0.88',noise=alls=...:allf=t,vignette=PI/4`.
     - `vignette`: `vignette=angle=...`.
     - `lightLeak`: `colorchannelmixer=...,curves=r='0/0.06 1/1'`.
     - `cameraShake`: Sinusoidal crop jitter `crop=w=iw-amp:h=ih-amp:x='(iw-ow)/2+sin(n*1.8)*...':y='(ih-oh)/2+cos(n*1.4)*...',scale=iw+amp:ih+amp`.
     - `radialZoom`: Scale-crop with dynamic Gaussian blur.

3. **Studio UI Sheet & Toolbar Integration (`VfxStudioSheet`)**:
   - Quick one-tap studio presets carousel (*35mm Film*, *RGB Glitch*, *Lens Blur*, *Retro VHS*, *Vignette*, *Light Leak*, *Shake*, *Zoom Rush*).
   - Visual grid cards for all 8 VFX types with icon and description.
   - Contextual precision sliders for intensity, texture scale, RGB shift, blur radius, vignette radius, and tremor amplitude.
   - Toolbar integration via `EditorTool.vfx` ('Visual FX') and docked tool panel.
   - Verified by comprehensive test suite in `test/vfx_suite_test.dart`.

---

## 18. Beat Detection & Audio Rhythm Waveform Snapping Studio (v1.0.32 Release)

High-precision musical rhythm synchronization and magnetic editing grid for music-driven video cuts:

1. **Beat Detection Data Model (`lib/features/beats/models/beat_detection_config.dart`)**:
   - `isEnabled`: Global beat detection toggle on the clip.
   - `mode`: Detection operational mode (`BeatDetectionMode.auto`, `manual`, `gridBpm`).
   - `bpm`: Tempo in beats per minute ($40.0 \to 240.0$, default $120.0$).
   - `sensitivity`: Dynamic energy threshold sensitivity ($0.1 \to 1.0$, default $0.70$).
   - `snapToBeats`: Magnetic snapping flag to pull cuts, trims, and playhead to beat timestamps.
   - `beatTimestampsMs`: Monotonically increasing list of millisecond timestamps relative to clip start.
   - Integrated into `Clip` model (`clip.beatConfig`) with full JSON serialization and Equatable props.

2. **Detection & Snapping Engine (`lib/features/beats/services/beat_detector_service.dart`)**:
   - `autoDetectBeats`:
     - **Transient Energy Flux**: Evaluates PCM audio sample peak flux against moving average threshold $\mu + (1.0 - \text{sensitivity}) \times 0.45$ with dynamic minimum peak interval $\frac{30000}{\text{BPM}}$.
     - **Rhythm BPM Grid**: Generates exact quarter-note downbeats and eighth-note upbeat subdivisions ($\Delta t = \frac{60000}{\text{BPM}}$) for synthetic or unprobed audio tracks.
   - `calculateBpmFromTaps`: Dynamic BPM evaluation from rhythmic user tap intervals with outlier rejection ($200\text{ms} - 2000\text{ms}$).
   - `addManualBeat` & `removeNearBeat`: Real-time interactive point editing with 120ms proximity de-duplication.
   - `findNearestBeat`: Proximity search within snapping threshold ($120\text{ms}$).
   - `TimelineEditingService.calculateSnapTime`: Timeline ruler scrub, clip trimming, and split operations dynamically aggregate active beat markers across all clips where `beatConfig.snapToBeats == true` and magnetically snap within 120–150ms.

3. **Visual Timeline & Studio UI (`BeatMarkersOverlayPainter` & `BeatDetectionSheet`)**:
   - `BeatMarkersOverlayPainter`: Custom Skia painter rendering golden vertical tick guidelines and glowing top/bottom bead markers on timeline audio waveforms.
   - `TimelineClipWidget`: Displays gold `🥁 128 BPM` badge when beats are active.
   - `TimelineContextBar`: Dedicated gold `Beats` action button for selected clips.
   - `BeatDetectionSheet`: Real-time interactive sheet featuring:
     - **TAP BEAT**: Large tactile rhythm tap button updating tempo in real time.
     - **AUTO DETECT**: One-tap transient analysis with quick presets (*Beat 1 (Drops)* vs *Beat 2 (All)*).
     - **Magnetic Beat Snapping**: One-click toggle switch.
     - **Tempo & Sensitivity Sliders**: Precise numeric BPM and threshold adjustment.
     - **Playhead Beat Toggler**: Quick marker drop/remove at the exact playhead position.
   - Verified by comprehensive test suite in `test/beats_suite_test.dart`.




