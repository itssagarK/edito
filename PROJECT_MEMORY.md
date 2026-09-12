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



