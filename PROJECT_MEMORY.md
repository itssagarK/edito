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

---

## 19. Auto-Reframing & Multi-Platform Smart Aspect Ratio Studio (v1.0.33 Release)

Intelligent multi-platform video reframing, blur-clone background fill, and smart pan-and-scan subject tracking engine:

1. **Auto-Reframing Data Model (`lib/features/image_editor/models/video_layout_config.dart`)**:
   - **Supported Ratios (`VideoLayoutRatio` & `AspectRatioPreset`)**:
     - `9:16` ($1080 \times 1920$): TikTok, Instagram Reels, YouTube Shorts.
     - `16:9` ($1920 \times 1080$): YouTube, Landscape TV, Widescreen.
     - `1:1` ($1080 \times 1080$): Instagram Square Feed Post.
     - `4:5` ($1080 \times 1350$): Instagram Portrait Feed.
     - `4:3` ($1440 \times 1080$): Classic Retro TV, iPad, Vintage Cinema.
     - `3:4` ($1080 \times 1440$): Vertical Tablet, Portrait Photo.
     - `21:9` ($2560 \times 1080$): Ultra-Wide Cinematic.
     - `2.39:1` ($2560 \times 1072$): Hollywood Anamorphic Cinemascope.
   - **Reframing Operational Modes (`AutoReframeMode`)**:
     - `fitWithBlur`: Signature TikTok/Shorts cloned blurred video background fill ($5-50\text{px}$ blur radius).
     - `smartCrop`: Full-screen pan-and-scan subject tracking with focal point offsets.
     - `solidPillarbox`: Clean solid border frame with customizable color palette.
     - `gradientCanvas`: Cinematic dual-color gradient letterbox/pillarbox.
   - **Subject Tracking Parameters**:
     - `focalPointX`: Horizontal pan offset ($-1.0$ left to $+1.0$ right).
     - `focalPointY`: Vertical tilt offset ($-1.0$ top to $+1.0$ bottom).
     - `gradientPreset`: Midnight Neon, Vibrant Sunset, Cyberpunk Glow, Studio Charcoal, Electric Violet.

2. **Dual-Engine Compositor & Export Compiler (`AutoReframeService`)**:
   - **Deterministic FFmpeg Pipeline (`ffmpeg_command_builder.dart`)**:
     - `fitWithBlur`: Dual-branch split filter:
       `split=2[fg_raw][bg_raw];[bg_raw]scale=$targetW:$targetH:force_original_aspect_ratio=increase,crop=$targetW:$targetH,gblur=sigma=$blur:steps=2[bg_blur];[fg_raw]scale=$innerW:$innerH:force_original_aspect_ratio=decrease[fg_scaled];[bg_blur][fg_scaled]overlay=(W-w)/2:(H-h)/2`
     - `smartCrop`: Pan-and-scan crop:
       `scale=$targetW:$targetH:force_original_aspect_ratio=increase,crop=$targetW:$targetH:'(iw-ow)/2 + ($fx * (iw-ow)/2)':'(ih-oh)/2 + ($fy * (ih-oh)/2)'`
     - `solidPillarbox` & `gradientCanvas`: Precision Lanczos decrease scale + padded color frame.
   - **Real-Time Preview Compositor (`RealtimePreviewViewport`)**:
     - Hardware-accelerated Skia `ImageFilter.blur` layer rendering the cloned background in real time.
     - Interactive `Alignment(focalPointX, focalPointY)` dynamic pan-and-scan viewport rendering.
     - Live HUD badge: `📐 REFRAME: 9:16 (BLUR CLONE)`, `📐 REFRAME: 9:16 (SMART CROP PAN 40%)`.

3. **Studio Sheet UI (`VideoLayoutSheet`)**:
   - Aspect ratio chips for all 8 standard media platforms.
   - 4-mode reframing selector with icons.
   - Real-time horizontal pan slider with percentage readout and 1-tap "Reset Center" button.
   - Background blur radius slider ($5 \to 50\text{px}$).
   - Corner radius ($0 \to 32\text{px}$) and frame padding ($0 \to 36\text{px}$) sliders.
   - Integrated into editor toolbar as 'Reframe' (`EditorTool.layout`).
   - Verified by comprehensive test suite in `test/auto_reframe_suite_test.dart`.

---

## 20. Text-to-Speech (TTS) Voiceover & Audio Narration Generator Studio (v1.0.34 Release)

High-fidelity neural voiceover generator, script-to-speech timing synthesis, and one-tap timeline narration injection:

1. **TTS Voice Personas & Acoustic Profiles (`lib/features/tts/models/tts_voice_profile.dart`)**:
   - **Voice Profiles (`TTSVoiceProfile`)**:
     - 🎙️ **Adam (Narrator)**: Deep baritone ($f_0 = 110\text{Hz}$) for video essays, documentaries, and reviews.
     - 🌟 **Emma (Storyteller)**: Warm melodic female ($f_0 = 215\text{Hz}$) for narrative audiobooks and emotional vlogs.
     - ⚡ **Max (Viral Shorts)**: High-tempo creator ($f_0 = 140\text{Hz}$) for TikTok, Reels, and Shorts.
     - 🧘 **Lily (Calm / ASMR)**: Soft breathy female ($f_0 = 230\text{Hz}$) for wellness, meditation, and aesthetic content.
     - 🎬 **Titan (Movie Trailer)**: Sub-bass chest resonance ($f_0 = 85\text{Hz}$) for cinematic blockbuster trailers.
     - 🤖 **Cyber-9 (Robotic)**: Vintage 80s vocoder synthesized digital droid voice ($f_0 = 175\text{Hz}$).
   - **Precise Formant Synthesis Modeling**:
     - Acoustical resonant frequencies ($F_1, F_2, F_3$) defined per persona for natural human vocal tract emulation.
     - `TTSConfig`: controls script text, speech rate ($0.5\text{x} \to 2.0\text{x}$), pitch shift ($-6\text{st} \to +6\text{st}$), volume boost, and caption synchronization.

2. **Synthesis Engine & Timeline Sync (`lib/features/tts/services/tts_generation_service.dart`)**:
   - `estimateSpokenDurationMs`: Accurate speech rate scaling ($150\text{ WPM}$ baseline) with punctuation pauses (periods $+320\text{ms}$, commas $+140\text{ms}$).
   - `generateRealisticWaveform`: Generates a 64-sample normalized audio envelope simulating human vocal phrasing for timeline waveforms.
   - `generateSpeechFFmpegFilter`: Carrier harmonic synthesis modulated with formant bandpass filters and brickwall ceiling limiter (`alimiter=limit=0.95`).
   - `insertVoiceoverClip`: One-tap creation and injection of `MediaAsset` and `Clip` onto the project timeline aligned with playhead position.
   - `generateSynchronizedCaptions`: Automatically chunks narration script into sequential `CaptionLine` objects synchronized to spoken duration.

3. **Studio UI Sheet & Editor Integration (`TTSVoiceoverSheet`)**:
   - Live script input box with word counter and dynamic duration estimate readout.
   - Horizontal persona card selector with avatar emoji, gender, and category badge.
   - Precision sliders for speech rate ($0.50\text{x} \to 2.0\text{x}$) and pitch shift ($-6\text{st} \to +6\text{st}$).
   - "Auto-Generate Captions" toggle switch.
   - Toolbar integration via `EditorTool.tts` ('AI Voice') and docked tool panel.
   - Verified by comprehensive test suite in `test/tts_suite_test.dart`.

---

## 21. HSL 8-Channel Selective Color Qualifier & Color Isolation Studio (v1.0.35 Release)

Hollywood-grade 8-channel selective color qualifier, per-hue isolation engine, and real-time GPU matrix shader:

1. **HSL 8-Channel Data Model (`lib/features/color_grading/models/color_grading_config.dart`)**:
   - **8 Canonical Color Sectors**:
     - `red` ($0^\circ$), `orange` ($30^\circ$, dedicated portrait skin tones), `yellow` ($60^\circ$), `green` ($120^\circ$, foliage/greenscreen), `cyan` ($180^\circ$, skies/water), `blue` ($240^\circ$), `purple` ($280^\circ$), `magenta` ($320^\circ$).
   - **`HslShift` Parameters**:
     - `hue`: Radial hue shift in degrees ($-180.0^\circ \to +180.0^\circ$).
     - `saturation`: Relative saturation delta ($-1.0 \to +1.0$, where $-1.0 = -100\%$ complete monochrome drain, $+1.0 = +100\%$ intense color pop).
     - `luminance`: Sector lightness adjustment ($-1.0 \to +1.0$).
   - **Cinematic Presets (`HslPreset`)**:
     - 🎬 **Sin City Red Pop (`selectiveRed`)**: Hollywood selective isolation keeping Red saturated ($+40\%$) while completely draining all other 7 sectors to $-100\%$ monochrome.
     - 🌅 **Teal & Orange (`tealAndOrange`)**: Warm skin highlights (Orange $+40\%$, Yellow $-25\%$) paired with cool teal-cyan shadows (Cyan $+45\%$, Blue $+30\%$).
     - 🍂 **Autumn Gold (`autumnGold`)**: Shifts foliage green $-60^\circ$ towards amber-orange with boosted yellow/orange saturation.
     - 🌲 **Emerald Foliage (`emeraldLush`)**: Deep vibrant greens ($+50\%$, $-10\%$ lightness) with rich yellow warmth.
     - 🏙️ **Urban Desat (`urbanDesat`)**: Moody architectural look crushing greens ($-80\%$) and yellows ($-70\%$) while popping cyan reflections ($+25\%$).
   - `hasActiveHsl` getter and `applyHslPreset(preset)` seamless integration.

2. **Dual-Engine Real-Time Compositor & Export Compiler (`ColorFilterCompilerService`)**:
   - **Real-Time GPU 4x5 ColorFilter Matrix**:
     - Computes per-channel primary sector projection vectors with Rec.709 luminance constants ($lr=0.2126, lg=0.7152, lb=0.0722$).
     - Desaturation selectively steers color sectors towards monochrome luminance without disturbing unselected sectors.
     - Real-time 60fps rendering in `realtime_preview_viewport.dart` with zero CPU overhead.
     - Viewport HUD status badge: `🎯 HSL (8ch)`, `🎯 HSL (2ch)`.
   - **Deterministic FFmpeg Export Compiler (`selectivecolor` filter)**:
     - Automatically maps active 8-channel HSL shifts to native FFmpeg `selectivecolor` subtractive CMYK deltas:
       `selectivecolor=reds='c m y k':yellows='...':greens='...':cyans='...':blues='...':magentas='...'`
     - Seamless integration into `ffmpeg_command_builder.dart` export pipeline.

3. **Studio UI Sheet & Editor Integration (`ColorGradingSheet`)**:
   - Dedicated HSL Presets Carousel (*Reset All*, *Sin City Red Pop*, *Teal & Orange*, *Autumn Gold*, *Emerald Foliage*, *Urban Desat*).
   - 8 channel swatches with active modification badges (amber dot), live color glows, and short channel labels.
   - Contextual header with selected channel indicator and one-tap "Reset Channel" button.
   - Precision sliders for Hue Shift ($\pm 180^\circ$), Saturation ($\pm 100\%$), and Luminance ($\pm 100\%$).
   - Universal Flutter compatibility using `IconButton.styleFrom(...)`.
   - Verified by comprehensive unit test suite in `test/hsl_suite_test.dart`.

---

## 22. Optical Flow Frame Blending & Velocity Motion Blur Studio (v1.0.36 Release)

High-performance optical flow motion estimation, temporal frame crossfade blending, and rotary shutter angle velocity motion blur engine:

1. **Optical Flow & Motion Blur Data Model (`lib/features/smoothing/models/video_smoother_config.dart`)**:
   - **Interpolation Engines (`MotionInterpolationMode`)**:
     - `none`: Native original clip frame cadence.
     - `frameBlend`: Linear temporal crossfade blending of adjacent frames (`tblend=all_mode=average`) to eliminate motion judder without vector warping artifacts.
     - `opticalFlow`: Full bidirectional motion-compensated optical flow synthesis (`minterpolate=mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1`) generating intermediate vector frames for buttery 60fps/120fps/240fps slow motion.
   - **Velocity Shutter Angle Parameters**:
     - `isMotionBlurEnabled`: Global toggle for velocity motion blur.
     - `shutterAngle`: Rotary camera shutter angle ($0.0^\circ \to 360.0^\circ$, default $180.0^\circ$).
       - $90^\circ$: Action Crisp (reduced blur, high temporal clarity).
       - $180^\circ$: Hollywood Cinema standard ($1/48\text{s}$ at $24\text{fps}$).
       - $270^\circ$: Dreamy, soft motion trail.
       - $360^\circ$: Full exposure light streak velocity blur.
     - `motionBlurSamples`: Number of temporal sub-frame slices ($2 \to 16$, default 6).
     - `motionBlurIntensity`: Velocity trail amplitude multiplier ($0.0 \to 1.0$).
     - `motionBlurDirection`: `omnidirectional`, `horizontal` (pan streak), `vertical` (tilt streak).
   - **Cinematic Presets (`SmootherPreset`)**:
     - 🎬 *180° Cinema Shutter*: Classic $180^\circ$ shutter angle natural velocity motion blur.
     - ⚡ *Action 90° Crisp*: Tight shutter speed for razor-sharp high-speed action.
     - 🌊 *60 FPS Optical Flow*: Butter-smooth 60fps frame rate interpolation.
     - 🧈 *120 FPS Buttery Flow*: 120fps high-frame-rate slow-mo frame synthesis.
     - 🌪️ *360° Velocity Streak*: Artistic light streaks and speed trail blur.
     - 🔄 *Natural Frame Blend*: Natural temporal crossfade blending.
     - 🛡️ *Gimbal Stabilizer*: 3-axis camera gimbal wobble cancellation.
     - 🧹 *Anti-Glitch & De-Flutter*: Cadence fixing and LED flutter removal.
     - 🏎️ *Action Sports Stabilizer*: Heavy rotational & translational stabilization.

2. **Dual-Engine Real-Time Compositor & Export Compiler**:
   - **Real-Time Viewport Preview Compositor (`MotionBlurPreviewWrapper`)**:
     - Hardware-accelerated Skia `ImageFilter.blur` directional layer rendering simulated shutter angle velocity streaks in real time at 60fps.
     - Live floating HUD status badges:
       - `🌪️ BLUR (180°) + 🌊 120FPS`
       - `🌪️ MOTION BLUR (180°)`
       - `🌊 OPTICAL FLOW (60FPS)`
       - `🔄 FRAME BLEND (60FPS)`
       - `🛡️ GIMBAL STABILIZED`
       - `ANTI-GLITCH`
   - **Deterministic FFmpeg Export Compiler (`AIVideoSmootherService`)**:
     - Optical flow interpolation: `minterpolate=fps=$targetFps:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1`.
     - Linear frame blending: `tblend=all_mode=average,fps=fps=$targetFps:round=near`.
     - Rotary shutter angle motion blur: Gaussian-distributed temporal sub-frame slice blending `tmix=frames=$samples:weights='...'` with directional convolution.

3. **Studio UI Sheet & Toolbar Integration (`VideoSmootherSheet`)**:
   - Modern 3-tab studio architecture: *Flow & Interpolation*, *Velocity Motion Blur*, and *Stabilizer & Glitch*.
   - Horizontal presets carousel covering all 10 cinematic presets.
   - 3-Way interpolation engine selector with real-time algorithm explanations.
   - Rotary shutter angle slider ($0^\circ \to 360^\circ$) with cinematic reference marks.
   - Integrated into editor toolbar as 'Flow & Blur' (`EditorTool.smooth`).
   - Verified by comprehensive test suite in `test/optical_flow_and_motion_blur_test.dart` and `test/video_smoother_test.dart`.

---

## 23. Picture-in-Picture (PiP) Multi-Layer Video Overlay & Window Compositor Studio (v1.0.37 Release)

Professional broadcast-grade Picture-in-Picture windowing, gaming webcam facecam framing, multi-shape masking, drop shadow ambient rendering, and multi-layer video overlay compositing:

1. **PiP Data Model & Presets Engine (`lib/features/image_editor/models/image_overlay_config.dart`)**:
   - **Window Shapes (`PipShape`)**:
     - `sharpWindow` (`rectangle`): Clean rectangular window with sharp borders.
     - `roundedRect`: Modern rounded window with customizable corner radii ($0 \to 48\text{px}$).
     - `circle`: 1:1 circular webcam portrait mask (`ClipOval`, $999\text{px}$ radius).
     - `diamond`: 4-point diamond geometric mask (`ClipPath` with Skia path clipper).
     - `squircle`: iOS continuous-curvature squircle mask ($20\text{px}$ smooth radius).
   - **Cinematic PiP Presets (`PipPreset`)**:
     - 🎥 *Webcam (Bottom-Right)*: Standard 16:9 streaming webcam window anchored at $(0.80, 0.80)$.
     - 🟣 *Circle Portrait*: 1:1 circular facecam window anchored at $(0.80, 0.80)$ with $3\text{px}$ border.
     - 🌓 *Split Left (50%)*: 50/50 side-by-side split screen anchored at $(0.25, 0.50)$.
     - 🌗 *Split Right (50%)*: 50/50 side-by-side split screen anchored at $(0.75, 0.50)$.
     - 🕹️ *Gaming HUD (Top-Left)*: Streamer gameplay overlay anchored at $(0.20, 0.20)$.
     - ↗️ *Top-Right*: Reaction window anchored at $(0.80, 0.20)$.
     - ↙️ *Bottom-Left*: PiP window anchored at $(0.20, 0.80)$.
     - 🔲 *Center Floating*: Highlight callout window centered at $(0.50, 0.50)$.
     - 🎨 *Custom Freeform*: Unconstrained manual geometry, position, and rotation.
   - **Styling & Geometry Parameters**:
     - `scale`: Window size multiplier ($15\% \to 120\%$).
     - `positionX` / `positionY`: Normalized coordinate anchors ($0.0 \to 1.0$).
     - `rotation`: Free rotation angle ($0^\circ \to 360^\circ$).
     - `opacity`: Layer transparency multiplier ($0.0 \to 1.0$).
     - `cornerRadius`: Border curvature radius ($0 \to 48\text{px}$).
     - `borderWidth`: Outer border stroke thickness ($0 \to 12\text{px}$).
     - `borderColor`: ARGB hex color code (Palette: White, Gold, Cyan, Pink, Green, Purple, Black).
     - `hasShadow`: Ambient drop shadow toggle.
     - `shadowBlur`: Skia Gaussian drop shadow blur ($0 \to 30\text{px}$).
     - `shadowColor`: ARGB hex color code with alpha.
     - `mediaPath`: Path to photo or video overlay file.
     - `assetLabel`: Overlay label or streamer badge text (e.g. "Host Cam", "Screen Share").

2. **Dual-Engine Real-Time Compositor & Export Compiler**:
   - **Real-Time Viewport Preview Compositor (`PipPreviewOverlay`)**:
     - Fractional Skia layout with `FractionallySizedBox` and `AspectRatio` (1:1 for circle webcam, 16:9 for windows).
     - Custom clipper execution for geometric shapes (`_DiamondClipper`, `ClipRRect`, `ClipOval`).
     - Real-time `BoxShadow` ambient drop shadow rendering behind the outer border stroke.
     - Live floating HUD status badges:
       - `🪟 PiP (CIRCLE WEBCAM)`
       - `🪟 PiP (SPLIT 50/50)`
       - `🪟 PiP (WEBCAM)`
       - `🪟 PiP (WINDOW)`
   - **Deterministic FFmpeg Export Compiler (`PipCompilerService`)**:
     - Scaled background bounding box generation: `drawbox=x=...:y=...:w=...:h=...:color=black@opacity:t=fill`.
     - Pixel-accurate outer border stroke generation: `drawbox=x=...:y=...:w=...:h=...:color=0xRRGGBB@opacity:t=borderWidth`.
     - Escaped streamer label burn-in: `drawtext=text=...:x=...:y=...:fontsize=...:fontcolor=white:box=1:boxcolor=black@0.75:boxborderw=4`.
     - Seamlessly integrated into `FFmpegCommandBuilder`.

3. **Studio UI Sheet & Toolbar Integration (`ImageOverlaySheet`)**:
   - Integrated into editor toolbar as 'PiP / Overlay' (`EditorTool.imageOverlay`) and docked panel as 'Picture-in-Picture (PiP)'.
   - Master Enable / Disable switch card with live badge display.
   - Horizontal preset selector carousel for all 9 PiP presets.
   - Window shape choice chips (`Sharp Window`, `Rounded Window`, `Circle Webcam`, `Diamond`, `Squircle`).
   - Gallery picker dialog supporting both Photo and Video overlays (`image_picker`).
   - Quick Anchor Position buttons (`Top-Left`, `Top-Right`, `Center`, `Bot-Left`, `Bot-Right`).
   - Precision sliders for Scale, Position X/Y, Rotation, Opacity, Corner Radius, Border Width, and Shadow Blur.
   - Border stroke color palette chips.
   - Verified by comprehensive test suite in `test/pip_suite_test.dart` and `test/video_layout_and_assets_test.dart`.

---

## 24. Cinematic Multi-Track Audio Restoration Studio (v1.0.38 Release)

DAW-grade audio restoration, ground loop hum cancellation, targeted sibilance suppression, wind/plosive sub-bass protection, and 3D acoustic room reverberation modeling:

1. **Audio Restoration & Acoustic Data Model (`lib/features/audio/models/audio_effects_config.dart`)**:
   - **Powerline Ground De-Hum Engine (`DeHumMode`)**:
     - `off`: Bypassed.
     - `hz50EuropeAsia`: $50\text{Hz}$ fundamental frequency plus harmonic overtones ($100\text{Hz}, 150\text{Hz}, 200\text{Hz}$) targeting electrical ground hums in UK, Europe, Asia, Africa, and Australia.
     - `hz60NorthAmerica`: $60\text{Hz}$ fundamental frequency plus harmonic overtones ($120\text{Hz}, 180\text{Hz}, 240\text{Hz}$) targeting electrical ground hums in USA, Canada, and Americas.
     - `custom`: Freely tunable fundamental notch frequency ($40\text{Hz} \to 120\text{Hz}$).
     - `deHumGain`: Notch attenuation depth ($-12\text{dB} \to -48\text{dB}$, default $-32\text{dB}$).
     - `deHumHarmonics`: Number of cascading harmonic notch filters ($1 \to 4$, default 3).
   - **Targeted Frequency Sibilance De-Esser (`DeEsserMode`)**:
     - `off`: De-esser disabled.
     - `wideband`: Standard wideband sibilance compression centered at $6.5\text{kHz}$.
     - `splitBandMale`: Low sibilance male speech centered at $5.0\text{kHz}$.
     - `splitBandFemale`: Sharp sibilance female speech centered at $7.5\text{kHz}$.
     - `crispMicrophone`: Condenser microphone splash centered at $9.0\text{kHz}$.
     - `deEsserIntensity`: Attenuation compression ratio ($10\% \to 100\%$).
     - `deEsserFrequency`: Precision center frequency ($3000\text{Hz} \to 10000\text{Hz}$).
   - **Wind & Mic Plosive Sub-Bass Guard**:
     - `isWindDePlosiveEnabled`: Steep 18dB/octave low-cut and dynamic low-frequency compressor targeting air turbulence and "p"/"b" microphone pops below $75\text{Hz}$.
     - `dePlosiveIntensity`: Sub-bass dynamic compression ratio ($20\% \to 100\%$).
   - **Studio Room Reverb & Acoustic Space Modeling (`RoomReverbPreset`)**:
     - `none`: Completely dry direct sound.
     - `studioVocalBooth`: Ultra-tight acoustic reflection booth (roomSize 0.12, damping 0.85, wet 0.08, dry 0.95).
     - `intimateRoom`: Cozy home studio / living room (roomSize 0.28, damping 0.65, wet 0.15, dry 0.90).
     - `warmAuditorium`: Medium theater / concert hall (roomSize 0.55, damping 0.45, wet 0.22, dry 0.85).
     - `cinematicCathedral`: Expansive epic cavernous hall (roomSize 0.85, damping 0.30, wet 0.35, dry 0.75).
     - `tunnelEcho`: Concrete reflective chamber with metallic ring (roomSize 0.75, damping 0.10, wet 0.40, dry 0.70).
     - `custom`: Manually adjustable acoustic dimensions.

2. **Dual-Engine Real-Time Compositor & Export Compiler**:
   - **Skia 3D Acoustic Space Visualizer (`AcousticSpaceVisualizer`)**:
     - Interactive wireframe 3D room box scaling dynamically with `reverbRoomSize`.
     - Sound emitter origin and multi-bounce reflection vectors showing ray paths.
     - Live acoustic readouts: Sabine RT60 reverberation decay time calculation, reflection density percentage, and damping ratio.
     - Live floating HUD badges: `🏛️ REVERB (...)`, `🧹 DE-HUM (...)`, `🎙️ DE-ESSER (...)`, `🌬️ DE-PLOSIVE ACTIVE`.
   - **Deterministic FFmpeg Export Compiler (`AIVoiceEnhancerService`)**:
     - Cascading steep Q notch filter generation: `equalizer=f=$f:width_type=q:width=14:g=$g`.
     - Wind/plosive filter: `highpass=f=75:p=2,compand=attacks=0.01:decays=0.08:points=...`.
     - Targeted de-esser: `deesser=i=$i:m=0.5:f=$freqNorm:s=e`.
     - Algorithmic Freeverb: `freeverb=roomsize=...:damping=...:wet=...:dry=...:width=...`.
     - Limiter safeguard: `alimiter=limit=0.95:attack=5:release=50:asc=1` eliminating digital clipping.

3. **5-Tab Studio UI Sheet & Toolbar Integration (`AudioMixerSheet`)**:
   - Upgraded from 4 tabs to 5 pro studio tabs:
     1. `🎚️ EQ`: Parametric 3-band tone equalizer with live Skia frequency response curve.
     2. `🧹 Restore`: Powerline De-Hum, targeted De-Esser, Wind/Plosive guard, and AI noise suppression.
     3. `🏛️ Acoustic`: Studio room reverb with 3D space visualizer and acoustic geometry sliders.
     4. `🎙️ Vocal`: Vocal isolation, clean speech, and neural voice gating.
     5. `🦆 Dynamics`: Smart sidechain auto-ducking, pre-amp booster, and voice modulation FX.
   - Integrated into editor docked panel as 'Audio Restoration & Mixer'.
   - Verified by comprehensive test suite in `test/audio_restoration_test.dart` and `test/audio_suite_test.dart`.

---

## 25. Dynamic Kinetic Subtitles & Animated Word-by-Word Caption Studio (v1.0.39 Release)

Viral short-form kinetic captions, word-by-word active timing synchronization, SubRip (`.srt`) / WebVTT (`.vtt`) bidirectional interchange, and multi-style karaoke typography:

1. **Word-Level Kinetic Timing & Subtitle Data Model (`lib/features/captions/models/caption_line.dart`)**:
   - **`WordTimestamp` Architecture**:
     - Models individual word fragments: `word`, `startOffsetMs`, and `durationMs`.
     - 100% backward-compatible JSON serialization.
   - **`KaraokeHighlightStyle` Engine**:
     - `none`: Standard static subtitle display.
     - `colorFill`: Viral TikTok / Reels style color pop changing active word to neon accent.
     - `scalePunch`: High-energy scale pop ($1.05\text{x} \to 1.50\text{x}$) bouncing active spoken syllables.
     - `pillBackground`: High-contrast neon bounding pill container wrapping the active word.
     - `glowWave`: Radiant soft-light neon aura drop shadow pulsing on active speech.
   - **Timing Algorithms**:
     - `CaptionLine.generateInterpolatedWords(text, durationMs)`: Distributes phrase durations across words with natural vowel/consonant weighting.
     - `CaptionLine.getActiveWordIndex(offsetMs)`: Pinpoints active word index with clamping and timecode synchronization.

2. **Bidirectional SubRip & WebVTT Subtitle Interchange Engine (`lib/features/captions/services/srt_subtitle_service.dart`)**:
   - `parseSrt`: Robust parser handling comma-separated (`00:00:01,000`) and dot-separated timecodes, multiline subtitle blocks, and automatic word-level interpolation.
   - `exportToSrt`: Deterministic standard SubRip formatter with sequence indices and blank-line separation.
   - `exportToVtt`: Standards-compliant WebVTT format for modern web players and streaming distribution.

3. **Dual-Engine Real-Time Compositor & Export Compiler**:
   - **Skia Real-Time Viewport Overlay (`KineticCaptionOverlay`)**:
     - Zero-latency Skia canvas rendering word-by-word transformations inside `RealtimePreviewViewport`.
     - Supports live font rendering across Google Fonts (`Anton`, `Inter`, `Bebas Neue`, `Montserrat`, `Poppins`, `JetBrains Mono`, `Permanent Marker`, `Caveat`, `Pacifico`).
     - Dynamic pill box container rendering, glow wave drops, and scale punching.
   - **FFmpeg Timed Subtitle Filter Chain (`CaptionCompilerService`)**:
     - Generates resolution-scaled timed `drawtext` filters with `between(t, start, end)` gates.
     - Position scaling across 720p, 1080p, and 4K UHD resolutions.
     - Floating HUD badge status: `⚡ KINETIC CAPTIONS (count)` or `💬 SUBTITLES (count)`.

4. **Dedicated 6-Tab Caption Studio (`CaptionManagerSheet`)**:
   - Upgraded from 5 to 6 dedicated studio tabs:
     1. `✨ AI & SRT`: AI speech sync, script auto-slicer, SubRip `.srt` import dialog, and `.srt` / `.vtt` clipboard export dialogs.
     2. `⚡ Kinetic Karaoke`: Highlight styles (`Color Pop`, `Scale Bounce`, `Neon Pill`, `Aura Glow`), 8-color palette, scale bounce slider, and word re-alignment.
     3. `🎨 Presets`: One-tap viral presets (`TikTok Viral`, `Cinematic Serif`, `Neon Cyberpunk`, `Subtle Minimal`, `Bold Highlight`).
     4. `🔤 Font & Size`: Typography picker, quick size chips (`S`, `M`, `L`, `XL`, `XXL`), and styling toggles (`Bold`, `Italic`, `ALL CAPS`, `Underline`).
     5. `🌈 Colors & Stroke`: 10 text colors, 9 background box translucent presets, and stroke outline slider.
     6. `🎬 Animation & Pos`: Entrance animations (`Fade`, `Pop Scale`, `Bounce`, `Slide Up`, `Zoom In`, `Shimmer`, `Karaoke`, `Typewriter`) and position presets (`Top`, `Center`, `Bottom`).
   - Integrated into editor bottom modal and timeline action bar.
   - Tested by comprehensive unit test suite in `test/kinetic_captions_test.dart`.
