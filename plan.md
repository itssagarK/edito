# Edito - On-Device AI Features Master Plan & Task Tracker

> **Last Updated:** 2026-10-08  
> **Target:** High-Performance, 100% On-Device & Offline AI Video Editing Engine (Edito)  
> **Status:** Phase 0–26 **ALL COMPLETED** | Cinematic Radial Blur & Binaural Auto-Pan Dynamic Suite Live (v1.0.89+90)  

---

## 🚨 Emergency Recovery Guide (If System Reboots or Session Drops)

If this environment restarts or your session closes abruptly, follow this 4-step recovery checklist:

1. **Verify Git & Working Tree Status:**
   ```powershell
   git status
   ```
2. **Run Linter / Verification Script:**
   ```powershell
   python scripts/verify_codebase.py
   ```
   *(Must return 100% CLEAN. Never commit or proceed if this fails.)*
3. **Locate Current Feature in Section 3 Below:**
   - All features F1–F6 and Phase 13–26 are complete.
4. **Resume Direct Commands / Tests / Release**.

---

## 1. Hard Engineering Rules & Constraints

- **Rule 1: 100% On-Device & Offline.** Zero cloud APIs, zero external HTTP API keys (Remove.bg/OpenAI/etc. removed), zero telemetry, zero background servers. All models run locally on Android (bundled or one-time downloaded with local storage).
- **Rule 2: Permissive Open-Source Licenses Only.** MIT, Apache-2.0, BSD only. Every model/library must be documented in `docs/THIRD_PARTY_LICENSES.md`.
- **Rule 3: Non-Destructive & Backward Compatible.** Existing project file formats and data models must open without error. Add optional/nullable fields with sensible defaults.
- **Rule 4: Architecture & UI Consistency.** Follow Riverpod state management, command-pattern undo/redo, docked-panel + Peek Mode UI, `IconButton.styleFrom(...)`.
- **Rule 5: Verification Before Done.** Every change must pass `python scripts/verify_codebase.py` and unit tests before committing.
- **Rule 6: Twin Platform Channel Maintenance.** Every method added to `android/app/src/main/kotlin/com/edito/app/MainActivity.kt` must also be kept in sync in `scripts/configure_android.py` (which templates CI builds).

---

## 2. Feature Implementation Sequence

| # | Feature Code | Feature Description | Model / Runtime | License | Status |
|---|---|---|---|---|---|
| **0** | **INFRA** | Shared On-Device AI Infrastructure | OnDeviceInferenceRunner, Tiering, Download | Internal | ✅ **COMPLETED** (`af4d1cc`) |
| **1** | **F1** | Auto Captions (Whisper STT) | Whisper Tiny int8 / Sherpa-ONNX / Native VAD | MIT | ✅ **COMPLETED** (`af4d1cc`) |
| **2** | **F2** | Real Subject Segmentation | MediaPipe Selfie Segmentation (TFLite) | Apache-2.0 | ✅ **COMPLETED** (`128a471`) |
| **3** | **F3** | Auto Subject Tracking (Zoom) | MediaPipe Face / Centroid + Kalman/EMA | Apache-2.0 | ✅ **COMPLETED** (`fd4c757`) |
| **4** | **F4** | Neural Noise Removal | FFmpeg `arnndn` (RNNoise) | BSD-3 | ✅ **COMPLETED** (`397f2e1`) |
| **5** | **F5** | Smart Auto-Ducking & Beat Sync | Silero VAD / Energy VAD + Onset Detection | MIT | ✅ **COMPLETED** (`a62ac48`) |
| **6** | **F6** | AI Upscaler & Enhancer | Real-ESRGAN Compact (ncnn/ONNX, Tiled) | BSD-3 | ✅ **COMPLETED** |
| **7** | **RENDER** | Unified Preview & Export Parity | Transforms, Gaps, Compositor, Real-ESRGAN | Internal | ✅ **COMPLETED** (`7fb2867`) |
| **8** | **AI-SUITE** | Built-in AI Suite (Silence Cut, Scene Split, Optical Track, Auto-Reframe) | Silero/Energy VAD, Shot Boundary, MediaPipe | MIT / Apache-2.0 | ✅ **COMPLETED** (`b5830a5`) |
| **9** | **UI-PRO** | Professional UI Hierarchy & Ergonomic Overhaul | CapCut Pro 2-tier dock, AI Suite, Live Header, Export Pill | Internal | ✅ **COMPLETED** (`04689a6`) |
| **10** | **APK-UI** | Full APK Home Shell & 4-Tab Navigation Overhaul | CapCut Pro 4-tab shell, AI Studio tab, Studio tab, System tab | Internal | ✅ **COMPLETED** (`c12e7c4`) |
| **11** | **SFX** | Native Sound Effects & Silence Spacers | Motion Whoosh, Tactile Snap, SSML Precision Silence | Internal | ✅ **COMPLETED** |
| **12** | **CLARITY** | Editing Screen Clarity & Precision Navigation | Instant Tool Search, Categorized Dock, Boundary Jumps | Internal | ✅ **COMPLETED** |
| **13** | **OFFLINE-SUITE** | 100% Self-Dependent Feature Suite (Social Progress Bar, Ken Burns Motion, Timeline Gap Closer) | Deterministic Math / Skia / DSP | Internal | ✅ **COMPLETED** |
| **14** | **CREATOR-POWER** | Creator Power Suite (Auto Beat Cut & Rhythm Snapper, Audio Fade Envelopes, Cinematic Impact Flash) | Deterministic Math / Skia / DSP | Internal | ✅ **COMPLETED** (`v1.0.77`) |
| **15** | **PRO-MOTION-AUDIO** | Pro Motion & Audio Dynamics Suite (Action Freeze Climax, Bezier Curve Speed Ease, 8D Spatial Audio Pan) | Deterministic Timeline Surgery / Bezier / LFO DSP | Internal | ✅ **COMPLETED** (`v1.0.78`) |
| **16** | **TYPOGRAPHY-VFX** | Creative Stylist & Typography Dynamics Suite (Typewriter Kinetic Titles, CRT Cyber Scanlines, Spatial Reverb Chamber) | Skia Canvas / DSP Convolver | Internal | ✅ **COMPLETED** (`v1.0.79`) |
| **17** | **OPTICAL-GLOW-AUDIO** | Optical Glow & Retro Tone Suite (Anamorphic Streak Flare, Halation Film Bleed, Tape Cassette Audio Warble) | Skia Canvas / Optical Convolution / DSP Wow & Flutter | Internal | ✅ **COMPLETED** (`v1.0.80`) |
| **18** | **CINEMATIC-SFX** | Cinematic Camera & Sound FX Suite (Handheld Shake, Fisheye Lens, Vinyl Turntable) | Skia Canvas / Mesh Distort / DSP Vinyl Crackle | Internal | ✅ **COMPLETED** (`v1.0.81`) |
| **19** | **ATMOSPHERIC-CHIPTUNE** | Atmospheric Lighting & Retro Texture Suite (Light Leak Rainbow Prisms, Night Vision Infrared, 8-Bit Lo-Fi Chiptune) | Skia Canvas / Colormap False Color / DSP Bitcrusher | Internal | ✅ **COMPLETED** (`v1.0.82`) |
| **20** | **KALEIDO-GLITCH-TREMOLO**| Prismatic Geometry & Audio Modulation Suite (Kaleidoscope Radial Mirror, Datamosh Glitch, Stereo Tremolo & Auto-Wah) | Skia Reflection / Delta Artifacts / LFO DSP | Internal | ✅ **COMPLETED** (`v1.0.83`) |
| **21** | **SPATIAL-OPTICS-BINAURAL**| Spatial Optics & Binaural Dynamics Suite (Tilt-Shift Miniature, Edge Glow Neon Hologram, Vocal Pitch Harmonizer) | Skia Canvas / Edge Detect / DSP Pitch Shifter | Internal | ✅ **COMPLETED** (`v1.0.84`) |
| **22** | **DYNAMIC-OPTICS-STUTTER**| Dynamic Optics & Audio Stutter Suite (RGB Chromatic Glitch, Thermal Solarization Invert, Rhythmic Beat Stutter) | Skia Canvas / Tone Curves / Micro-Buffer DSP | Internal | ✅ **COMPLETED** (`v1.0.85`) |
| **23** | **PIXEL-SORT-POP-FLANGER**| Glitch Mosaic & Stereo Flanger Dynamic Suite (Pixel Sort Glitch, Posterize Pop Art, Jet Flanger Frequency Phaser) | Skia Canvas / Luminance Sort / Comb DSP | Internal | ✅ **COMPLETED** (`v1.0.86`) |
| **24** | **LUMA-KEY-RING-MOD** | Luma Keying & Metallic Ring Modulator Suite (Luma Silhouette Keyer, Matrix Digital Rain, Metallic Ring Modulator & Robotic Vocoder) | Skia Canvas / Matrix Rain / Carrier Oscillator DSP | Internal | ✅ **COMPLETED** (`v1.0.87`) |
| **25** | **ECHO-ASCII-SUB-BASS** | Motion Echo Trails & Sub-Bass Exciter Suite (Motion Blur & Echo Decay Trails, ASCII Terminal Matrix Texturizer, Sub-Bass 808 Saturator & Harmonic Exciter) | Skia Canvas / Temporal Blend / Harmonic Bass DSP | Internal | ✅ **COMPLETED** (`v1.0.88`) |
| **26** | **RADIAL-BLUR-AUTO-PAN** | Cinematic Radial Blur & Binaural Auto-Pan Dynamic Suite (Anamorphic Radial Zoom Blur, Cyber HUD Hologram Grid, Binaural Auto-Pan & Doppler Swell) | Skia Canvas / Polar Transform / 3D Binaural LFO DSP | Internal | ✅ **COMPLETED** (`v1.0.89`) |
| **27** | **PRISM-FLUID-MULTIBAND** | Optical Prism Flare & Multiband Master Compressor Suite (Liquid Water Caustics, Diamond Glass Prism, Multiband Mastering Compressor) | Skia Canvas / Liquid Caustics / 3-Band DSP Compressor | Internal | 🚀 **PLANNED** |

---

## 3. Detailed Phase Breakdown & Task Status

### Phase 0: Shared On-Device AI Infrastructure ✅ [COMPLETED]
- [x] Document third-party AI licenses in `docs/THIRD_PARTY_LICENSES.md`.
- [x] Create `AiModelDescriptor` and `AiModelCatalog` (`lib/core/ai/models/ai_model_descriptor.dart`) covering Whisper, MediaPipe, RNNoise, Silero, Real-ESRGAN.
- [x] Implement `DeviceTierService` (`lib/core/ai/device_tier_service.dart`) with hardware info querying (RAM, CPU cores, tier calculation: low/medium/high).
- [x] Implement `OnDeviceInferenceRunner` (`lib/core/ai/on_device_inference_runner.dart`) with mutex concurrency, `CancellationToken`, 30s idle eviction, typed exceptions (`AiException`).
- [x] Implement `AiModelManager` (`lib/core/ai/ai_model_manager.dart`) for bundled asset copy, resumable HTTP download, SHA-256 validation, storage checks.
- [x] Build `ModelDownloadDialog` (`lib/core/ai/widgets/model_download_dialog.dart`) user-facing modal.
- [x] Add platform channel handlers to `MainActivity.kt` and `scripts/configure_android.py`:
  - `getDeviceHardwareInfo`
  - `getDiskFreeSpaceMb`
- [x] Add unit test suite `test/on_device_ai_infrastructure_test.dart`.

---

### Phase 1: F1 - Auto Captions (Whisper STT) ✅ [COMPLETED]
- [x] Native audio extraction pipeline (`extractAudioToWav` via MediaCodec/FFmpeg downmixed to 16 kHz 16-bit mono WAV).
- [x] Native VAD audio transcription pipeline (`transcribeAudioOnDevice`) in `MainActivity.kt` & `scripts/configure_android.py`.
- [x] Rewrote `WhisperTranscriptionService` (`lib/features/captions/services/whisper_transcription_service.dart`) to run 100% on-device via `OnDeviceInferenceRunner` and local models.
- [x] Replaced cloud API buttons and keys in `CaptionManagerSheet` (`lib/features/captions/presentation/widgets/caption_manager_sheet.dart`) with on-device UI, language selection, model download dialog, and cancellation.
- [x] Purged legacy cloud `AiSettingsSheet` references from `editor_screen.dart` and `editing_toolbar.dart`.
- [x] Add unit test suite `test/on_device_whisper_test.dart`.
- [x] Verified 100% clean with `python scripts/verify_codebase.py`.
- [x] Git committed: `feat: add shared AI infrastructure and on-device Whisper STT (F1)` (`af4d1cc`).

---

### Phase 2: F2 - Real Subject Segmentation ✅ [COMPLETED]
**Goal:** Replace manual circular spotlight / cloud API background removal with real-time on-device selfie/person segmentation.

#### Task Checklist:
- [x] **Step 2.1:** Native Android Segmentation Runner
  - Implemented frame extraction and multi-pass portrait segmentation in `MainActivity.kt` & `scripts/configure_android.py`.
  - Platform channel methods: `extractVideoFrameAtTime`, `segmentSubjectOnDevice`, and `generateVideoSegmentationMask`.
- [x] **Step 2.2:** Dart Segmentation Service
  - Created `lib/core/ai/services/on_device_segmentation_service.dart`.
  - Concurrency management, cancellation token, and device-tier-aware video mask generation.
- [x] **Step 2.3:** Wire into `SmartCutout` Feature
  - Replaced cloud Remove.bg API in `AiBackgroundRemovalService` with `OnDeviceSegmentationService`.
  - Added on-device AI Cutout button card to `SmartCutoutSheet` UI.
- [x] **Step 2.4:** Wire into `CharacterHighlight` Feature
  - Added `useAiSegmentation`, `isAiSubjectDetected`, `maskPath`, and `subjectBbox` to `CharacterHighlightConfig`.
  - Added AI Subject Segmentation card in `CharacterHighlightSheet` with auto-track scan and manual (X, Y) fallback sliders.
  - Enhanced `_CharacterHighlightPainter` in `RealtimePreviewViewport` to support adaptive bounding box neon aura.
- [x] **Step 2.5:** Export Pipeline Integration
  - Verified FFmpeg command builder integration with `CharacterHighlightCompilerService` and `SmartCutoutCompilerService`.
- [x] **Step 2.6:** Testing & Verification
  - Created unit test suite `test/subject_segmentation_test.dart`.
  - Ran `python scripts/verify_codebase.py` (331 Dart files scanned, 100% clean).

---

### Phase 3: F3 - Auto Subject Tracking for Main Character Zoom ✅ [COMPLETED]
**Goal:** Automatically detect face/subject centroid and dynamically update zoom focal point with Kalman/EMA smoothing.
- [x] Added `isAutoTrackingEnabled`, `isSubjectTracked`, and `trackingSmoothing` to `CharacterZoomConfig`.
- [x] Implemented `applyEmaSmoothing` helper method with mathematical exponential moving average filter.
- [x] Added on-device AI Auto Subject Tracking card in `CharacterZoomSheet` with re-detect action, smoothness slider, and status indicator.
- [x] Implemented seamless manual override: panning/tapping targeting canvas or selecting quick anchors turns off auto-tracking without losing focus.
- [x] Updated `CharacterZoomCompilerService.getZoomBadge` with `🤖 AI TRACK` indicator.
- [x] Added comprehensive unit tests in `test/character_zoom_tracking_test.dart`.
- [x] Verified 100% clean with `python scripts/verify_codebase.py` (332 files).

---

### Phase 4: F4 - Neural Noise Removal ✅ [COMPLETED]
**Goal:** High-fidelity speech denoiser without cloud processing.
- **Model:** RNNoise (`librnnoise`, BSD-3-Clause) / FFmpeg native `arnndn` / enhanced recurrent filter.
- **Pipeline:** Pre-pass audio through neural denoiser, clamp with brickwall limiter (`alimiter=limit=0.95:attack=5:release=50:asc=1`).
- **UI:** Clean speech slider in `AudioMixerSheet`, A/B comparison toggle (press-and-hold to audition raw noisy audio vs denoised).
- [x] Extended `AudioEffectsConfig` with `isNeuralDenoiseEnabled`, `neuralDenoiseStrength`, and `isNoiseComparisonBypass`.
- [x] Integrated neural denoiser into `AIVoiceEnhancerService.generateFFmpegFilter` with true-peak brickwall ceiling limiter.
- [x] Added Vocal Studio RNNoise UI card, strength slider, and hold-to-compare A/B button in `AudioMixerSheet`.
- [x] Added unit tests in `test/neural_noise_removal_test.dart`.
- [x] Verified 100% clean with `python scripts/verify_codebase.py` (333 files).

---

### Phase 5: F5 - Smart Auto-Ducking and Beat Sync ✅ [COMPLETED]
**Goal:** Intelligent background music attenuation during speech, plus music beat grid snapping.
- **Ducking:** Silero VAD (MIT) / Energy VAD envelope detector to generate smooth sidechain ducking volume automation.
- **Beat Sync:** FFT spectral flux onset detector to snap timeline cuts to music tempo beats.
- **UI:** Visual ducking curve and beat marker dots on timeline.
- [x] Extended `AudioEffectsConfig` with `isVadDuckingEnabled` and `speechIntervalsMs` (backward compatible).
- [x] Upgraded `AudioDuckingService` to duck only during detected foreground speech segments.
- [x] Implemented `AudioVadService` (`lib/features/audio/services/audio_vad_service.dart`).
- [x] Enhanced `BeatDetectorService` with half-wave rectified spectral flux onset detection and statistical BPM estimation.
- [x] Added native pipelines `detectVoiceActivityPipeline` and `detectAudioBeatsPipeline` to `MainActivity.kt` and `scripts/configure_android.py`.
- [x] Added AI VAD speech activity scanner card and status badges in `AudioMixerSheet`.
- [x] Added AI Spectral Onset Scan button in `BeatDetectionSheet`.
- [x] Added comprehensive unit tests in `test/audio_vad_ducking_test.dart` and `test/beat_sync_onset_test.dart`.
- [x] Verified 100% clean with `python scripts/verify_codebase.py` (336 files).

---

### Phase 6: F6 - AI Upscaler & Image Enhancer ✅ [COMPLETED]
**Goal:** Super-resolution for thumbnails, cover images, and short clip frames.
- **Model:** Real-ESRGAN Compact (BSD-3-Clause) via ncnn/ONNX.
- **Safety:** Tiled execution (128x128 on low tier, 256x256 on medium/high tier with 16px overlap) to prevent Android out-of-memory.
- **UI:** Honest speed notice and duration disclaimer in `VideoEnhancementSheet` and `ImageEditorSheet`.
- [x] Implemented twin platform channel handlers `"upscaleImageRealEsrgan"` and memory-safe tiled implementation `upscaleImageRealEsrganPipeline` in `MainActivity.kt` and `scripts/configure_android.py`.
- [x] Created `OnDeviceUpscalerService` (`lib/core/ai/services/on_device_upscaler_service.dart`) with hardware tier detection, duration estimation, and cancellation tokens.
- [x] Extended `VideoEnhancementConfig` with `useNeuralRealEsrgan`, `tiledResolutionScale`, and `upscaledAssetPath` (backward-compatible defaults).
- [x] Updated `AIVideoEnhancerService.getResolutionLabel` with technically honest distinctions between `4x REAL-ESRGAN (NEURAL)` and `8K UHD Lanczos (7680x4320)`.
- [x] Added Neural Real-ESRGAN card with live progress bar and execution button to `VideoEnhancementSheet`.
- [x] Added 4x Real-ESRGAN Super-Resolution export button to `ImageEditorSheet` (`lib/features/image_editor/presentation/widgets/image_editor_sheet.dart`).
- [x] Created unit test suite `test/on_device_upscaler_test.dart`.
- [x] Verified 100% clean with `python scripts/verify_codebase.py` (338 files).

---

### Phase 7: Full Rendering Pipeline & Preview/Export Parity Audit ✅ [COMPLETED]
**Goal:** Guarantee complete 1:1 mathematical parity between real-time viewport preview rendering and exported video output across all parameters, edits, AI features, transforms, and multi-track timing.
- [x] **Real-ESRGAN Upscaled Asset Parity:**
  - Resolved `primaryAsset` in `TimelineCompositorService.evaluateFrame` to use `upscaledAssetPath` when neural enhancement is active.
  - Registered upscaled asset paths as dedicated input streams in `FFmpegCommandBuilder.buildArguments` for video frames while preserving original audio channels.
  - Wired `upscaledAssetPath` into Tier 2 hardware `MediaCodec` frame renderer in `ExportRenderService`.
- [x] **Spatial Transforms Compiler Service:**
  - Created `VideoTransformCompilerService` (`lib/features/transform/services/video_transform_compiler_service.dart`).
  - Compiles 90/180/270 rotations, horizontal/vertical flips, zoom-in punch crop (`crop + scale`), zoom-out shrink (`scale + pad`), and on-canvas translation (`positionX`, `positionY`).
- [x] **Track 0 Timeline Gap Preservation:**
  - Added initial head gap and inter-clip gap black canvas fillers in `FFmpegCommandBuilder` so Track 0 never squashes clips or desynchronizes audio and subtitles.
  - Single-clip projects starting at 0 preserve exact `[v0]` labels and backward compatibility.
- [x] **Upper Video Tracks Multi-Clip Layer Compositing:**
  - Enabled per-clip layer compositing via `BlendModeCompilerService.generateFFmpegLayerCompositor` with clip-specific blend modes and exact `between(t, startSec, endSec)` time windows.
- [x] **Character Zoom Preview Parity:**
  - Added radial focus vignette and saturation/contrast subject aura to `RealtimePreviewViewport` matching export filter output.
- [x] **Testing & Verification:**
  - Created unit test suite `test/rendering_fidelity_test.dart`.
  - Ran `python scripts/verify_codebase.py` (340 Dart files scanned, 100% clean).

---

### Phase 8: Built-in On-Device AI Features Suite ✅ [COMPLETED]
**Goal:** Empower creators with essential on-device AI features that CapCut Pro and Premiere Pro possess, running 100% offline with complete preview/export rendering fidelity:
- [x] **Feature 8.1: AI Silence Remover & Smart Jump-Cut (Audio AI):**
  - Created `AiSilenceRemoverService` (`lib/features/audio/services/ai_silence_remover_service.dart`).
  - Detects dead-air pauses and unvoiced intervals (>350ms) using on-device VAD.
  - Slices speech sub-clips non-destructively, calculates precise `sourceInMs`/`sourceOutMs`, and ripples following timeline clips.
  - Wired into `ClipWorkflowSheet` and `AudioMixerSheet` with sensitivity controls and dead-air statistics.
- [x] **Feature 8.2: AI Scene Cut Detector & Auto-Split (Vision AI):**
  - Added twin platform channel methods `"detectSceneCuts"` and `detectSceneCutsPipeline` to `MainActivity.kt` and `scripts/configure_android.py`.
  - Created `AiSceneDetectorService` (`lib/features/timeline/services/ai_scene_detector_service.dart`) with luminance frame delta analysis and fallback.
  - Slices long footage into independent scene clips with 1 tap in `ClipWorkflowSheet`.
- [x] **Feature 8.3: AI Real Optical Motion Tracking (Vision AI):**
  - Upgraded `MotionTrackingService.generateOpticalTrajectoryFromVideo` (`lib/features/tracking/services/motion_tracking_service.dart`).
  - Samples video frames and tracks real subject centroid and bounding box using on-device MediaPipe segmentation with EMA smoothing.
  - Wired live tracking progress into `MotionTrackingSheet`.
- [x] **Feature 8.4: AI Auto-Reframe (Dynamic Speaker Centering):**
  - Added `AutoReframeService.detectOptimalSpeakerFocalPoint` (`lib/features/image_editor/services/auto_reframe_service.dart`).
  - Auto-centers 9:16 vertical video crops on the active speaker.
  - Added 1-tap "AI Auto-Center Speaker" button in `VideoLayoutSheet`.
- [x] **Testing & Verification:**
  - Added comprehensive unit test suite `test/built_in_ai_features_test.dart`.
  - Scanned 343 Dart files with `python scripts/verify_codebase.py` (100% CLEAN).

---

### Phase 9: Professional UI Hierarchy & Ergonomic Experience Overhaul ✅ [COMPLETED]
**Goal:** Elevate Edito to an industry-grade, CapCut Pro / DaVinci Resolve tier of design polish, logical hierarchy, and ergonomic workflow.

#### Task Checklist:
- [x] **Step 9.1: Dedicated AI Suite Dock & Micro-Badges**
  - Upgraded `EditingToolbar` with dedicated "AI Suite" action card featuring gradient border and glowing AI badge.
  - Added on-device AI micro-badges to all neural-powered tools (`isAi: true`) across both contextual clip dock and global dock.
  - Elevated `AI Studio` (`EditorTool.clipWorkflow`) directly into the primary clip dock alongside Split, Speed, Volume, and Cutout.
- [x] **Step 9.2: Categorized Professional Bottom Sheets**
  - Built `_showGlobalAiSuiteSheet` with "100% OFFLINE" status indicator and cards for Whisper, VAD, Real-ESRGAN, MediaPipe, Demucs, RNNoise, and Face Sculpt.
  - Reorganized `_showClipMoreToolsSheet` into 4 logical suites:
    1. 🤖 *AI Intelligence & Smart Studio*
    2. 🎬 *Cinematic Visuals & VFX*
    3. 🎵 *Audio & Voice Studio*
    4. 🎨 *Color & Finishing*
  - Reorganized `_showGlobalMoreToolsSheet` into *AI Intelligence*, *Audio & Narration*, and *Canvas & Visual Design*.
- [x] **Step 9.3: EditorAppBar CapCut Pro Header**
  - Added interactive Resolution & Frame Rate badge (`1080P • 30FPS` or `4K • 60FPS`) with quick preset dropdown.
  - Added duration and track count subtitle under project title.
  - Upgraded Export CTA with electric purple gradient, subtle drop shadow, and 12.5px bold typography.
- [x] **Step 9.4: Docked Tool Panel & Live Peek Ergonomics**
  - Polished docked panel header with subtle icon container, pulsing live status badge, and gradient "Done" action button.
  - Enhanced "Live Peek" floating action bar with electric purple restore controls button.
- [x] **Step 9.5: Linter & Architectural Verification**
  - Scanned 343 Dart files with `python scripts/verify_codebase.py`: **100% CLEAN**.

---

### Phase 10: Full APK Home Shell & 4-Tab Navigation Overhaul ✅ [COMPLETED]
**Goal:** Transform the entry-level APK experience into a flagship commercial video editor with a 4-tab bottom navigation shell, dedicated AI Studio showcase, creative studio tools, hardware telemetry diagnostics, and polished project cards.

#### Task Checklist:
- [x] **Step 10.1: CapCut Pro 4-Tab Navigation Architecture**
  - Added bottom `NavigationBar` on `HomeScreen` with 4 dedicated tabs:
    1. 🎬 **Edit**: Hero New Project banner, instant aspect ratio chips, quick creator shortcuts, search & filtered recent projects.
    2. 🤖 **AI Studio**: Complete on-device neural engine showcase (Speech AI, Motion AI, Vision AI, Real-ESRGAN Upscaler).
    3. 🎨 **Studio**: Creative visual tools (Cover maker, Split screen multi-grid, 3D Parallax, Doodle brush, Pro Color Wheels, Sound FX).
    4. ⚙️ **System**: Real-time hardware telemetry (RAM, cores, tier, storage), offline privacy guarantee, open-source licenses dialog.
- [x] **Step 10.2: Dedicated Modular Tab Widgets**
  - Created `AiStudioTab` (`lib/features/home/presentation/widgets/ai_studio_tab.dart`).
  - Created `CreativeStudioTab` (`lib/features/home/presentation/widgets/creative_studio_tab.dart`).
  - Created `SystemSpecsTab` (`lib/features/home/presentation/widgets/system_specs_tab.dart`).
- [x] **Step 10.3: Modernized Project Card with Aspect Frames & Delete Guard**
  - Upgraded `ProjectCard` with aspect-ratio-accurate preview container (`9:16`, `16:9`, `1:1`), monospace duration badge, 1080P/4K resolution tag, and safety delete confirmation dialog.
- [x] **Step 10.4: Version Bump for Automated CI/CD Release**
  - Updated `pubspec.yaml` to `1.0.72+73`.
  - Updated `scripts/configure_android.py` to `versionCode = 73` and `versionName = "1.0.72"`.
- [x] **Step 10.5: Architectural Verification**
  - Scanned 346 Dart files with `python scripts/verify_codebase.py`: **100% CLEAN**.

---

### Phase 11: EditorCopy Native Sound Effects & Silence Spacers Integration ✅ [COMPLETED]
**Goal:** Extract, bundle, and integrate sound effects from `EditorCopy` resource into Edito's cinematic audio studio.

#### Task Checklist:
- [x] **Step 11.1: Audio Extraction & Asset Bundling**
  - Copied dynamic motion transition audio (`motion_whoosh.mp3`) from `EditorCopy/res/kx/a.mp3`.
  - Copied tactile shutter / UI snap audio (`tactile_click.wav`) from `EditorCopy/res/kx/kh.wav`.
  - Extracted 4 SSML precision silence spacers (`silence_100ms.mp3`, `silence_200ms.mp3`, `silence_400ms.mp3`, `silence_800ms.mp3`) from `EditorCopy/assets/ssml_silence_audio.zip`.
- [x] **Step 11.2: Sound Effect Item Library Enhancement**
  - Added `motion_whoosh` (Motion Swell & Swoosh) to `Transitions` in `SoundEffectItem.library`.
  - Added `tactile_snap` (Tactile Shutter & Snap) to `Tactile & UI`.
  - Added dedicated `Silence Spacers` category with 100ms, 200ms, 400ms, 800ms precision audio gap items.
- [x] **Step 11.3: Sound Effects Sheet Category Filter**
  - Added `'Silence Spacers'` category filter to `SoundEffectsSheet`.
- [x] **Step 11.4: Linter & Architectural Verification**
  - Scanned 346 Dart files with `python scripts/verify_codebase.py`: **100% CLEAN**.

---

### Phase 12: Editing Screen Clarity, Intuitive Precision Navigation & Ergonomics Overhaul ✅ [COMPLETED]
**Goal:** Optimize editing screen clarity, eliminate tedious tool hunting, deliver precision frame-by-frame and cut-to-cut timestamp navigation, and prevent accidental mis-edits.

#### Task Checklist:
- [x] **Step 12.1: Precision Timestamp Jump & Scrub Dialog (`TimestampJumpDialog`)**
  - Created interactive modal with live timeline scrub slider.
  - 1-tap boundary navigation: `|◀ Start`, `◀ Prev Cut`, `Next Cut ▶`, `End ▶|` powered by `TimelineEditingService`.
  - Frame-by-frame precision stepping: `-1 Frame` (~33ms at 30fps), `+1 Frame`, `-1s`, `+1s` with haptic feedback.
  - Percentage presets (`0%`, `25%`, `50%`, `75%`, `100%`) and SMPTE timecode readout.
- [x] **Step 12.2: Realtime Preview Viewport HUD & Transport Bar Upgrade**
  - Converted static text timecode badge to interactive chip opening `TimestampJumpDialog`.
  - Replaced coarse `±5s` jumps with precision `-1 Frame`, `+1 Frame`, `-1s`, and `+1s` nudges.
  - Interactive SMPTE overlay badge on video canvas header.
- [x] **Step 12.3: Selected Clip Context & Safety HUD (`SelectedClipContextBar`)**
  - Sticky context bar between preview viewport and timeline showing active track type, clip duration, in/out points.
  - Quick action pills: `Split at playhead`, `Duplicate`, `Delete`, and prominent `Done / Deselect` button to prevent accidental mis-edits.
  - Idle timeline status showing track count and 1-tap jump timecode chip.
- [x] **Step 12.4: Instant Tool Search & Categorized Filter Dock (`EditingToolbar` & `ToolSearchModal`)**
  - Added categorized filter pills above contextual clip dock (`All`, `Edit`, `AI Studio`, `Audio`, `Visuals`, `Color`).
  - Created `ToolSearchModal` indexing all 58 tools with keyword matching (e.g., "split", "cutout", "lut", "mask", "voice", "denoise").
  - Added quick `Search 🔍` button in both contextual and global docks.
- [x] **Step 12.5: Timeline Interaction & Deselection Safety**
  - Tapping empty track lanes or timeline ruler automatically deselects clips safely.
  - Added haptic feedback when playhead snaps to cuts or markers.
  - Unit test suite added in `test/editing_screen_clarity_and_navigation_test.dart`.
  - Scanned 350 Dart files with `python scripts/verify_codebase.py`: **100% CLEAN**.

---

### Phase 13: 100% Self-Dependent Offline Feature Suite (Zero-API / Deterministic Math) ✅ [COMPLETED]
**Goal:** Implement rock-solid, 100% self-dependent editing features that run entirely on-device with mathematical predictability and zero failure risk.

#### Tasks:
- [x] **Step 13.1: Social Video Retention Progress Bar Studio (`ProgressBarConfig`)**
  - Model `ProgressBarConfig` with gradient colors, position (bottom/top), height, glow, and border radius.
  - Wired into `Project` domain model with backward-compatible defaults.
  - Real-time Skia 60 FPS viewport rendering in `RealtimePreviewViewport`.
  - Native export rendering in `FFmpegCommandBuilder` via `ProgressBarCompilerService`.
  - Dedicated interactive UI sheet: `ProgressBarSheet` with live preview and electric presets.
- [x] **Step 13.2: Ken Burns Photo & B-Roll Motion Animator (`KenBurnsConfig`)**
  - Model `KenBurnsConfig` with modes (`zoomIn`, `zoomOut`, `panLeft`, `panRight`, `diagonalDrift`), intensity, and easing.
  - Wired into `Clip` domain model with backward-compatible defaults.
  - Real-time 2D affine matrix animation in `RealtimePreviewViewport`.
  - Native export filter in `FFmpegCommandBuilder` via `KenBurnsCompilerService`.
  - Dedicated interactive UI sheet: `KenBurnsSheet` with live animated canvas simulation.
- [x] **Step 13.3: Timeline Micro-Gap Finder & Ripple Closer (`GapCloserService`)**
  - Service `GapCloserService` in `lib/features/timeline/services/gap_closer_service.dart`.
  - Scans tracks for accidental 1ms to 1000ms black gaps and calculates metrics.
  - 1-tap ripple elimination of black frame flashes across all tracks.
  - Dedicated interactive UI sheet: `GapCloserSheet`.
- [x] **Step 13.4: Tool Registration & Navigation Wiring**
  - Added `progressBar`, `kenBurns`, `gapCloser` to `EditorTool` enum in `editor_provider.dart`.
  - Fully wired into `EditorScreen`, `DockedToolPanel`, `EditingToolbar`, and `ToolSearchModal`.
- [x] **Step 13.5: Comprehensive Unit Tests & Codebase Verification**
  - Created `test/self_dependent_offline_suite_test.dart` testing models, interpolation math, ripple editing, and export compilation.
  - Bumped version to `1.0.76+77` in `pubspec.yaml` and `scripts/configure_android.py`.
  - Verified 100% clean with `python scripts/verify_codebase.py` (365 Dart files).

---

### Phase 14: Creator Power Suite (Auto Beat Cut, Audio Fade Envelopes, Cinematic Impact Flash) ✅ [COMPLETED]
**Goal:** Deliver 3 high-impact offline features powered by deterministic DSP, Skia Canvas blending, and timeline arithmetic with 0% failure risk.

#### Tasks:
- [x] **Step 14.1: Auto Beat Cut & Rhythm Sync Studio (`BeatCutterService`)**
  - Implemented `BeatCutterService` in `lib/features/beats/services/beat_cutter_service.dart`.
  - Auto-split video clips on detected audio beat markers or mathematical tempo grid intervals (every 1st, 2nd, or 4th beat).
  - Snap existing video clip cutpoints to nearest musical beats within customizable tolerance (±50ms to ±300ms).
  - Dedicated interactive UI sheet: `BeatCutterSheet` in `lib/features/beats/presentation/widgets/beat_cutter_sheet.dart`.
- [x] **Step 14.2: Audio Fade Envelopes & Anti-Pop Crossfade Studio (`AudioFadeConfig`)**
  - Modeled `AudioFadeConfig` in `lib/features/audio/models/audio_fade_config.dart` (`fadeInDurationMs`, `fadeOutDurationMs`, curve types).
  - Wired into `Clip` domain model with backward-compatible defaults.
  - Implemented `AudioFadeCompilerService` in `lib/features/audio/services/audio_fade_compiler_service.dart` for FFmpeg `afade` compilation.
  - Dedicated interactive UI sheet: `AudioFadeSheet` in `lib/features/audio/presentation/widgets/audio_fade_sheet.dart`.
  - Export integration: automatically wired into audio filter chain in `FFmpegCommandBuilder`.
- [x] **Step 14.3: Cinematic Impact Flash & Strobe Accent Studio (`ImpactFlashConfig`)**
  - Modeled `ImpactFlashConfig` in `lib/features/vfx/models/impact_flash_config.dart` (`whiteFlash`, `blackFlash`, `warmGlow`, `rgbStrobe`, duration, intensity, decay curves).
  - Wired into `Clip` domain model with backward-compatible defaults.
  - Real-time 60 FPS Skia canvas blend mode rendering in `RealtimePreviewViewport`.
  - Implemented `ImpactFlashCompilerService` in `lib/features/vfx/services/impact_flash_compiler_service.dart` for FFmpeg export filter generation.
  - Dedicated interactive UI sheet: `ImpactFlashSheet` in `lib/features/vfx/presentation/widgets/impact_flash_sheet.dart`.
- [x] **Step 14.4: Tool Registration & Navigation Wiring**
  - Added `beatCut`, `audioFade`, `impactFlash` to `EditorTool` enum in `editor_provider.dart`.
  - Fully wired into `EditorScreen`, `DockedToolPanel`, `EditingToolbar`, and `ToolSearchModal`.
- [x] **Step 14.5: Comprehensive Unit Tests & Codebase Verification**
  - Created `test/creator_power_suite_test.dart` testing models, DSP calculations, beat cut arithmetic, and export compilation.
  - Bumped version to `1.0.77+78` in `pubspec.yaml` and `scripts/configure_android.py`.
  - Verified 100% clean with `python scripts/verify_codebase.py` (374 Dart files scanned).

---

### Phase 15: Pro Motion & Audio Dynamics Suite (Action Freeze Climax, Bezier Curve Speed Ease, 8D Spatial Audio Pan) ✅ [COMPLETED]
**Goal:** Deliver 3 high-impact, 100% self-dependent creator tools powered by deterministic timeline surgery, cubic bezier easing math, and audio stereo matrix DSP:
- [x] **Step 15.1: Action Freeze Frame Climax Studio (`FreezeClimaxService`, `FreezeClimaxSheet`)**
  - Modeled `FreezeClimaxConfig` (`freezeDurationMs`, `zoomScale`, `flashAccent`, `accentStyle`, `muteAudioDuringFreeze`).
  - Implemented `FreezeClimaxService` in `lib/features/timeline/services/freeze_climax_service.dart`.
  - Splits target clip, inserts freeze hold with camera punch zoom, monochrome/grit accents, and ripple-shifts subsequent clips across all tracks.
  - Interactive UI sheet: `FreezeClimaxSheet` in `lib/features/timeline/presentation/widgets/freeze_climax_sheet.dart` with live simulation.
- [x] **Step 15.2: Bezier Curve Speed Ramping & Optical Ease (`SpeedEaseConfig`, `SpeedEaseCompilerService`, `SpeedEaseSheet`)**
  - Modeled `SpeedEaseConfig` in `lib/features/speed/models/speed_ease_config.dart` with Newton-Raphson cubic Bezier easing solver.
  - Presets: *Hero Entrance*, *Bullet Time Ease*, *Montage Acceleration*, *Smooth Optical Ease*, *Fast Snap*.
  - Compiles FFmpeg `setpts` and `fps` filter chains via `SpeedEaseCompilerService`.
  - Interactive UI sheet: `SpeedEaseSheet` in `lib/features/speed/presentation/widgets/speed_ease_sheet.dart` with draggable Skia control handles.
- [x] **Step 15.3: 8D Spatial Audio & Stereo Matrix Pan Studio (`SpatialAudioPanConfig`, `SpatialPanCompilerService`, `SpatialPanSheet`)**
  - Modeled `SpatialAudioPanConfig` in `lib/features/audio/models/spatial_audio_pan_config.dart` with equal-power panning and sinusoidal LFO orbit calculation.
  - Native FFmpeg filter compilation via `SpatialPanCompilerService` using `stereotools=mpan` and `pan=stereo` with true-peak brickwall ceiling limiter.
  - Interactive UI sheet: `SpatialPanSheet` in `lib/features/audio/presentation/widgets/spatial_pan_sheet.dart` with animated binaural headphone radar canvas.
- [x] **Step 15.4: Tool Registration & Navigation Wiring**
  - Added `freezeClimax`, `speedEase`, `spatialPan` to `EditorTool` enum in `editor_provider.dart`.
  - Wired into `EditorScreen`, `DockedToolPanel`, `EditingToolbar`, and `ToolSearchModal`.
- [x] **Step 15.5: Comprehensive Unit Tests & Codebase Verification**
  - Created `test/pro_motion_audio_dynamics_test.dart` testing models, timeline surgery, Bezier math, equal-power panning, and FFmpeg filter compilation.
  - Bumped version to `1.0.78+79` in `pubspec.yaml` and `scripts/configure_android.py`.
  - Verified 100% clean with `python scripts/verify_codebase.py` (384 Dart files scanned).

---

### Phase 16: Creative Stylist & Typography Dynamics Suite (Typewriter Kinetic Titles, CRT Cyber Scanlines, Spatial Reverb Chamber) ✅ [COMPLETED]
**Goal:** Deliver 3 high-impact, 100% self-dependent creator tools powered by Skia Canvas typography animation, analog scanline raster filters, and acoustic DSP delays:
- [x] **Step 16.1: Animated Text Typewriter & Kinetic Word Flow (`TypewriterTitleConfig`, `TypewriterTitleService`, `TypewriterTitleSheet`)**
  - Modeled `TypewriterTitleConfig` with `charByChar`, `wordByWord`, `fadeWord`, and `terminalGlitch` modes.
  - Interactive cursor customization: `line`, `block`, `underscore`, `caret`, `none` with customizable blink period and haptic sync.
  - Progressive alpha / keyframe export filters in `TypewriterTitleService` and real-time preview viewport parity.
  - Interactive UI sheet: `TypewriterTitleSheet` with live typing simulation card, speed slider, and presets (*Tech Terminal*, *Noir Title*, *TikTok Punch*, *Hacker Matrix*, *Minimal Clean*).
- [x] **Step 16.2: Retro CRT Scanlines & Cyber Phosphor Glow Studio (`CrtScanlineConfig`, `CrtScanlineCompilerService`, `CrtScanlineSheet`)**
  - Modeled `CrtScanlineConfig` with scanline pitch, opacity, rolling hum bar speed, CRT barrel curvature, RGB shadow offset, and TV noise.
  - 6 cathode phosphor tints: `Natural`, `Amber Classic (1981)`, `P1 Green (IBM 5151)`, `Trinitron Cyber Cyan`, `CCTV B&W Monochrome`, `Vaporwave Neon Pink`.
  - Deterministic FFmpeg filter pipeline (`drawgrid`, `colorchannelmixer`, `rgbashift`, `vignette`, `noise`) via `CrtScanlineCompilerService`.
  - Skia custom painter `_ViewportCrtPainter` in viewport preview stack and interactive `CrtScanlineSheet`.
- [x] **Step 16.3: Audio Reverb Chamber & Spatial Acoustic Convolver (`ReverbChamberConfig`, `ReverbCompilerService`, `ReverbChamberSheet`)**
  - Modeled `ReverbChamberConfig` with 7 room acoustic types (`studioBooth`, `smallRoom`, `vocalHall`, `cathedral`, `cyberCavern`, `plateReverb`, `stadium`).
  - Wet/dry mix, decay tail duration (100ms–5000ms), high-frequency damping, stereo width, and pre-delay reflections.
  - Deterministic FFmpeg `aecho`, `stereotools`, `equalizer` audio pipeline with **true-peak brickwall ceiling limiter (`alimiter=limit=0.95:attack=5:release=50:asc=1`)** per AGENTS.md Rule 4.
  - Interactive UI sheet: `ReverbChamberSheet` with 3D acoustic room visualizer canvas (`_AcousticChamberPainter`).
- [x] **Step 16.4: Tool Registration & Navigation Wiring**
  - Added `typewriterTitle`, `crtScanline`, `reverbChamber` to `EditorTool` enum in `editor_provider.dart`.
  - Wired into `EditorScreen`, `DockedToolPanel`, `EditingToolbar`, and `ToolSearchModal`.
- [x] **Step 16.5: Comprehensive Unit Tests & Codebase Verification**
  - Created `test/creative_stylist_typography_dynamics_test.dart` testing models, typography math, CRT raster filters, reverb DSP, and schema backwards compatibility.
  - Bumped version to `1.0.79+80` in `pubspec.yaml` and `scripts/configure_android.py`.
  - Verified 100% clean with `python scripts/verify_codebase.py` (394 Dart files scanned).

---

### Phase 17: Optical Glow & Retro Tone Suite (Anamorphic Streak Flare, Halation Film Bleed, Tape Cassette Audio Warble) ✅ [COMPLETED] (v1.0.80)
**Goal:** Deliver 3 high-impact, 100% self-dependent creator tools powered by anamorphic optical flares, film stock emulsion halation, and analog tape wow & flutter DSP:
- [x] **17.1 Anamorphic Streak Flare & Starburst Studio (`AnamorphicFlareConfig`, `AnamorphicFlareCompilerService`, `AnamorphicFlareSheet`)**:
  - Horizontal blue/gold/neon cinema lens streak bloom, luminance threshold extraction ($0.60$–$0.98$), anamorphic aspect stretch ($1.0\text{x}$–$10.0\text{x}$), specular starburst spikes ($0, 4, 6, 8$), 5 optical tints, and live interactive Skia Canvas viewport simulation.
  - FFmpeg filter compiler (`colorchannelmixer`, `gblur` horizontal stretch, `curves`).
- [x] **17.2 35mm Film Halation & Emulsion Red Bleed Studio (`FilmHalationConfig`, `FilmHalationCompilerService`, `FilmHalationSheet`)**:
  - Red photochem layer backscatter glow halo along high-contrast specular highlights and silhouette edges, diffusion radius ($2\text{px}$–$30\text{px}$), warmth scatter, 4 emulsion hues (CineStill Red, Vision3 Orange, Eterna Magenta, Kodachrome Amber), and live Skia simulation.
  - FFmpeg filter compiler (`colorchannelmixer`, `curves`, `gblur`).
- [x] **17.3 Vintage Tape Cassette & Wow/Flutter Warble Studio (`TapeCassetteConfig`, `TapeCassetteCompilerService`, `TapeCassetteSheet`)**:
  - Low-frequency tape speed drift (wow ~0.2Hz–2Hz), rapid capstan flutter (~5Hz–20Hz), head azimuth tape warmth ($85\text{Hz}$ low bump + $6\text{kHz}$–$14.5\text{kHz}$ roll-off), analog hiss floor, and animated rotating tape reels card.
  - FFmpeg DSP compiler (`vibrato`, `equalizer`, `lowpass`) with strict true-peak brickwall ceiling limiter per `AGENTS.md` Rule 4 (`alimiter=limit=0.95:attack=5:release=50:asc=1`).
- [x] **Integration & Polish**:
  - Wired into `Clip` domain model (`copyWith`, `toJson`, `fromJson`, `props`).
  - Integrated into `FFmpegCommandBuilder` video and audio export filtergraphs.
  - Implemented live Skia Canvas compositing overlays in `RealtimePreviewViewport`.
  - Registered in `EditorTool` enum, docked in `DockedToolPanel`, surfaced in `EditingToolbar` dock and modal grid, and indexed in `ToolSearchModal`.
  - Created comprehensive test suite `test/optical_glow_retro_tone_test.dart`.
  - Bumped version to `1.0.80+81` in `pubspec.yaml` and `scripts/configure_android.py`.
  - Verified 100% clean with `python scripts/verify_codebase.py` (404 Dart files scanned).

---

### Phase 18: Cinematic Camera & Sound FX Suite (Organic Camera Shake, Lens Distortion & Fisheye, Vinyl Turntable Dust) ✅ [COMPLETED] (v1.0.81)
**Goal:** Deliver 3 high-impact, 100% self-dependent creator tools powered by deterministic mathematical motion drift, optical geometric lens deformation, and vinyl needle acoustic textures:
- [x] **18.1 Organic Handheld Camera Shake & Impact Tremor Studio (`CameraShakeConfig`, `CameraShakeCompilerService`, `CameraShakeSheet`)**:
  - Natural handheld micro-drift, violent impact earthquake shockwaves, vehicle motor rumble, frequency and amplitude LFOs, Skia viewport simulation, and FFmpeg `crop` + trigonometric harmonic coordinate jitter.
  - 5 camera shake profiles: Handheld, Earthquake, Vehicle Offroad, Heartbeat Pulse, Impact Tremor.
- [x] **18.2 Lens Distortion & Action-Cam Fisheye Studio (`LensDistortionConfig`, `LensDistortionCompilerService`, `LensDistortionSheet`)**:
  - Curved panoramic barrel fisheye curvature, telephoto pincushion zoom, chromatic aberration RGB edge fringe, corner vignette falloff, interactive Skia mesh warp canvas simulation, and FFmpeg `lenscorrection` / `vignette` pipeline.
  - 5 optical profiles: Action Cam Fisheye, Anamorphic Barrel, Telephoto Pincushion, Drone Ultra-Wide, Vintage Spyglass.
- [x] **18.3 Vintage Vinyl Turntable & Dusty Needle Studio (`VinylRecordConfig`, `VinylRecordCompilerService`, `VinylRecordSheet`)**:
  - Analog needle surface crackle, dust pops, 33⅓, 45, and 78 RPM speeds, authentic mechanical needle drop cue, phono RIAA warmth EQ curve, and animated rotating vinyl turntable card.
  - FFmpeg DSP compiler (`highpass`, `equalizer`, `lowpass`, `vibrato`) with strict true-peak brickwall ceiling limiter per `AGENTS.md` Rule 4 (`alimiter=limit=0.95:attack=5:release=50:asc=1`).
- [x] **Integration & Polish**:
  - Wired into `Clip` domain model (`copyWith`, `toJson`, `fromJson`, `props`).
  - Integrated into `FFmpegCommandBuilder` video and audio export filtergraphs.
  - Implemented live Skia Canvas compositing overlays in `RealtimePreviewViewport`.
  - Registered in `EditorTool` enum, docked in `DockedToolPanel`, surfaced in `EditingToolbar` dock and modal grid, and indexed in `ToolSearchModal` (64 tools total).
  - Created comprehensive test suite `test/cinematic_camera_sound_fx_test.dart`.
  - Bumped version to `1.0.81+82` in `pubspec.yaml` and `scripts/configure_android.py`.
  - Verified 100% clean with `python scripts/verify_codebase.py` (414 Dart files scanned).

---

### Phase 19: Atmospheric Lighting & Retro Texture Suite (Light Leak Rainbow Prisms, Night Vision Infrared Scope, 8-Bit Lo-Fi Chiptune Crusher) ✅ [COMPLETED]
**Goal:** Deliver 3 high-impact, 100% self-dependent creator tools powered by optical atmospheric light dispersion, spectral military infrared false-coloring, and DSP audio bit-crushing:
- [x] **19.1 Light Leak Rainbow Prisms Studio (`LightLeakConfig`, `LightLeakCompilerService`, `LightLeakSheet`)**:
  - Organic solar light leaks, chromatic rainbow prism flares, warm anamorphic exposure breathing, Skia Canvas blending (`_LightLeakPainter`), and FFmpeg `eq` / `colorchannelmixer` composition.
- [x] **19.2 Night Vision & Thermal Infrared Scope Studio (`NightVisionConfig`, `NightVisionCompilerService`, `NightVisionSheet`)**:
  - Phosphor green night-vision matrix, FLIR thermal false-color heatmap, CRT scan lines, phosphor bloom halo, ocular tube vignette, and authentic military rangefinder reticle overlay (`_NightVisionPainter`).
- [x] **19.3 8-Bit Lo-Fi Chiptune Bitcrusher Studio (`BitcrusherConfig`, `BitcrusherCompilerService`, `BitcrusherSheet`)**:
  - Sample rate downsampling ($3\text{kHz}$–$22\text{kHz}$), bit depth quantization ($2$ to $12$ bits), arcade crunch saturation, animated quantized waveform monitor (`_BitcrusherPainter`), and strict true-peak brickwall ceiling limiter (`alimiter=limit=0.95:attack=5:release=50:asc=1`) per `AGENTS.md` Rule 4.
- [x] **Full Integration**: Wired into `Clip`, `FFmpegCommandBuilder`, `RealtimePreviewViewport`, `EditorTool`, `DockedToolPanel`, `EditorScreen`, `EditingToolbar`, and `ToolSearchModal`.
- [x] **Verification**: Created test suite `test/atmospheric_lighting_retro_texture_test.dart` and verified 100% clean with `python scripts/verify_codebase.py` (424 files).

---

### Phase 20: Prismatic Geometry & Audio Modulation Suite (Kaleidoscope Radial Mirror, Datamosh Glitch, Stereo Tremolo & Auto-Wah) ✅ [COMPLETED] (v1.0.83)
**Goal:** Deliver 3 high-impact, 100% self-dependent creator tools powered by radial optical kaleidoscope symmetry, temporal digital compression data-moshing, and periodic audio LFO wave modulation:
- [x] **20.1 Prismatic Kaleidoscope & Radial Mirror Studio (`KaleidoscopeConfig`, `KaleidoscopeCompilerService`, `KaleidoscopeSheet`)**:
  - Multi-facet radial symmetry reflection (2 to 12 segments: bilateral, quad, hexagon, octagon, dodecagon), center pivot offset, dynamic rotation spin, focal zoom, animated Skia Canvas mandala preview simulation (`_KaleidoscopePainter`), and FFmpeg `split` / `hflip` / `hstack` / `vstack` / `rotate` filter compilation.
  - 5 curated presets: Classic Hexagon, Sacred Mandala, Quad Retro Mirror, Cosmic Crystal, Twin Symmetry.
- [x] **20.2 Glitch Data-Mosh & Compression Artifacts Studio (`DatamoshGlitchConfig`, `DatamoshGlitchCompilerService`, `DatamoshGlitchSheet`)**:
  - Simulated keyframe I-frame dropout, macroblock DCT pixelation ($8\text{px}$–$48\text{px}$), RGB chromatic displacement slices, VHS horizontal tracking loss, blocky quantization smears, animated Skia Canvas glitch preview (`_DatamoshPainter`), and FFmpeg `rgbashift` / `scale` / `noise` filter pipeline.
  - 5 curated profiles: Classic Datamosh, Cyberpunk Glitch, Extreme Compression, VHS Tape Tear, Fatal Data Decay.
- [x] **20.3 Stereo Tremolo & Auto-Wah Dynamic Filter Studio (`TremoloWahConfig`, `TremoloWahCompilerService`, `TremoloWahSheet`)**:
  - LFO periodic stereo amplitude pulsation (sine, triangle, square, sawtooth; $0.2\text{Hz}$–$20.0\text{Hz}$), dynamic resonant auto-wah bandpass envelope ($200\text{Hz}$–$4000\text{Hz}$, Q-factor resonance $0.5$–$10.0$), Doppler Leslie rotary speaker simulation, EDM stutter chopper gate, animated Skia Canvas dual-channel LFO waveform monitor (`_TremoloWahPainter`), and strict true-peak brickwall ceiling limiter (`alimiter=limit=0.95:attack=5:release=50:asc=1`) per `AGENTS.md` Rule 4.
  - 5 curated presets: Vintage Surf Tremolo, Funky Auto-Wah, Leslie Organ Speaker, Hard EDM Stutter, Trippy Phaser Sweep.
- [x] **Full Integration & Polish**:
  - Wired into `Clip` domain model (`copyWith`, `toJson`, `fromJson`, `props`).
  - Integrated into `FFmpegCommandBuilder` video export (`vFilters`) and audio export (`aFilters`) filtergraphs.
  - Implemented live Skia Canvas compositing overlays in `RealtimePreviewViewport` (`_ViewportKaleidoscopePainter`, `_ViewportDatamoshGlitchPainter`).
  - Registered in `EditorTool` enum, docked in `DockedToolPanel`, surfaced in `EditingToolbar` dock, `_showAllToolsModal`, and `_showClipMoreToolsSheet`, and indexed in `ToolSearchModal` (67 tools total).
  - Created comprehensive test suite `test/prismatic_geometry_audio_modulation_test.dart`.
  - Bumped version to `1.0.83+84` in `pubspec.yaml` and `scripts/configure_android.py`.
  - Verified 100% clean with `python scripts/verify_codebase.py` (434 Dart files scanned).

---

### Phase 21: Spatial Optics & Binaural Dynamics Suite (Tilt-Shift Miniature, Neon Hologram Wireframe, Vocal Pitch & Formant Harmonizer) ✅ [COMPLETED] (v1.0.84)
**Goal:** Deliver 3 high-impact, 100% self-dependent creator tools powered by selective miniature optical focus planes, edge-detection holographic wireframe glows, and DSP musical vocal pitch/formant shifting:
- [x] **21.1 Tilt-Shift Miniature & Depth-of-Field Diorama Studio (`TiltShiftConfig`, `TiltShiftCompilerService`, `TiltShiftSheet`)**:
  - Linear focal plane strip and radial circular focus mask, progressive Gaussian/box blur falloff outside focal region, miniature toy-model color saturation boost, interactive Skia focal band drag handles (`_TiltShiftPainter`), and FFmpeg `boxblur` / `blend` selective filter compilation.
  - 5 curated presets: Toy Town Miniature, Diorama Horizontal, Portrait Radial Focus, Macro Shallow DoF, Architectural Tilt.
- [x] **21.2 Edge Glow Cyberpunk Neon & Hologram Wireframe Studio (`NeonGlowConfig`, `NeonGlowCompilerService`, `NeonGlowSheet`)**:
  - Sobel edge-detection filter, neon/rainbow phosphor edge mapping, pulsating intensity glow, holographic scanline raster, Skia Canvas glowing silhouette overlay (`_NeonGlowPainter`), and FFmpeg `edgedetect` / `colorkey` / `tblend` / `drawgrid` compositing.
  - 5 curated presets: Tokyo Neon Cyan, Hologram Mesh Blue, Synthwave Magenta, Matrix Wireframe, Rainbow Spectrum.
- [x] **21.3 Dynamic Vocal Pitch Shifter & Formant Harmonizer Studio (`PitchHarmonizerConfig`, `PitchHarmonizerCompilerService`, `PitchHarmonizerSheet`)**:
  - Musical semitone transposition (-12 to +12 semitones, -50 to +50 cents), dual-voice interval harmonies (octave down/up, minor/major 3rd, perfect 4th/5th), robotic ring modulation timbre, animated musical keyboard visualizer (`_PitchHarmonizerPainter`), and FFmpeg `asetrate` / `atempo` / `amix` / `flanger` DSP pipeline with strict true-peak brickwall ceiling limiter (`alimiter=limit=0.95:attack=5:release=50:asc=1`) per `AGENTS.md` Rule 4.
  - 5 curated presets: Lead 5th Harmony, Sub-Octave Doubler, Airy Upper Octave, Demon Grave Pitch, Dalek Ring Mod.
- [x] **Full Integration & Polish**:
  - Wired into `Clip` domain model (`copyWith`, `toJson`, `fromJson`, `props`).
  - Integrated into `FFmpegCommandBuilder` video export (`vFilters`) and audio export (`aFilters`) filtergraphs.
  - Implemented live Skia Canvas compositing overlays in `RealtimePreviewViewport` (`_ViewportTiltShiftPainter`, `_ViewportNeonGlowPainter`).
  - Registered in `EditorTool` enum, docked in `DockedToolPanel`, surfaced in `EditingToolbar` dock, `_showAllToolsModal`, and `_showClipMoreToolsSheet`, and indexed in `ToolSearchModal` (70 tools total).
  - Created comprehensive test suite `test/spatial_optics_binaural_dynamics_test.dart`.
  - Bumped version to `1.0.84+85` in `pubspec.yaml` and `scripts/configure_android.py`.
  - Verified 100% clean with `python scripts/verify_codebase.py` (444 Dart files scanned).

---

### Phase 22: Dynamic Optics & Audio Stutter Suite (RGB Chromatic Glitch, Thermal Solarization Invert, Rhythmic Beat Stutter) ✅ [COMPLETED] (v1.0.85)
**Goal:** Deliver 3 high-impact, 100% self-dependent creator tools powered by optical chromatic dispersion, photographic solarization inversion, and rhythmic audio buffer repetition:
- [x] **22.1 RGB Color Aberration & Holographic Glitch Shift Studio (`ChromaticAberrationConfig`, `ChromaticAberrationCompilerService`, `ChromaticAberrationSheet`)**:
  - Radial and linear RGB channel separation, Red/Green/Blue color fringe offsets, lens dispersion prisms, animated Skia chromatic aberration preview (`_ChromaticAberrationPainter`), and FFmpeg `rgbashift` / `colorchannelmixer` filters.
  - 5 curated presets: Cyber Glitch, Lens Prism, 3D Anaglyph, Hologram Shift, Radial Warp.
- [x] **22.2 Thermal Solarization & Psychedelic Color Invert Studio (`SolarizeInvertConfig`, `SolarizeInvertCompilerService`, `SolarizeInvertSheet`)**:
  - Tone curve inversion inflection thresholds, Sabattier solarization effect, negative color mapping, psychedelic trippy saturation cycling, animated Skia tone transfer curve monitor (`_SolarizeCurvePainter`), and FFmpeg `lutrgb` / `curves` export filters.
  - 5 curated presets: Sabattier Solarize, Film Negative, Acid Trip, Thermal Infrared, Darkroom Cross.
- [x] **22.3 Rhythmic Audio Stutter & Glitch Buffer Beat Repeater Studio (`AudioStutterConfig`, `AudioStutterCompilerService`, `AudioStutterSheet`)**:
  - Synchronized micro-buffer beat repeat slices (1/4, 1/8, 1/16, 1/32 beats), pitch-ramping stutter roll drops, tape stop deceleration brake, animated buffer waveform repeater monitor (`_AudioStutterPainter`), and FFmpeg `aecho` / `tremolo` / `vibrato` / `aphaser` / `flanger` DSP filtergraph with strict true-peak brickwall ceiling limiter (`alimiter=limit=0.95:attack=5:release=50:asc=1`) per Rule 4.
  - 5 curated presets: 1/8 Beat Roll, 1/16 Glitch, Pitch Drop Brake, Machine Gun Drill, Granular Cloud.
- [x] **Full Integration & Polish**:
  - Wired into `Clip` domain model (`copyWith`, `toJson`, `fromJson`, `props`).
  - Integrated into `FFmpegCommandBuilder` video export (`vFilters`) and audio export (`aFilters`) filtergraphs.
  - Implemented live Skia Canvas compositing overlays in `RealtimePreviewViewport` (`_ViewportChromaticAberrationPainter`, `_ViewportSolarizeInvertPainter`).
  - Registered in `EditorTool` enum, docked in `DockedToolPanel`, surfaced in `EditingToolbar` dock, `_showAllToolsModal`, and `_showClipMoreToolsSheet`, and indexed in `ToolSearchModal` (73 tools total).
  - Created comprehensive test suite `test/dynamic_optics_audio_stutter_test.dart`.
  - Bumped version to `1.0.85+86` in `pubspec.yaml` and `scripts/configure_android.py`.
  - Verified 100% clean with `python scripts/verify_codebase.py` (454 Dart files scanned).

---

### Phase 23: Glitch Mosaic & Stereo Flanger Dynamic Suite (Pixel Sort Glitch, Posterize Pop Art, Jet Flanger Frequency Phaser) ✅ [COMPLETED] (v1.0.86)
**Goal:** Deliver 3 high-impact, 100% self-dependent creator tools powered by algorithmic luminance pixel sorting, threshold color posterization, and comb-filter jet flanger DSP:
- [x] **23.1 Pixel Sort & Glitch Streak Studio (`PixelSortConfig`, `PixelSortCompilerService`, `PixelSortSheet`)**:
  - Threshold-based luminance pixel sorting, horizontal/vertical digital data streaks, directional sorting angle, animated Skia streak flow monitor, and FFmpeg displacement glitch filtergraph.
- [x] **23.2 Threshold Posterization & Pop Art Chromatic Studio (`PosterizePopConfig`, `PosterizePopCompilerService`, `PosterizePopSheet`)**:
  - Quantized tonal banding reduction (2 to 16 color levels per channel), Andy Warhol Pop Art vibrant tint mapping, edge outline thresholding, and FFmpeg `lutrgb` / `curves` posterize filter pipeline.
- [x] **23.3 Jet Flanger & Barberpole Frequency Phaser Studio (`JetFlangerConfig`, `JetFlangerCompilerService`, `JetFlangerSheet`)**:
  - Short modulated delay comb-filtering simulating jet-engine whoosh sweeps, barberpole infinite rising/falling phasing, stereo width expansion, and strict true-peak brickwall ceiling limiter per Rule 4.
- [x] **Full System Integration & Verification**:
  - Wired into `Clip`, `FFmpegCommandBuilder`, `RealtimePreviewViewport`, `EditorTool`, `DockedToolPanel`, `EditorScreen`, `EditingToolbar`, and `ToolSearchModal` (76 tools indexed).
  - Created comprehensive test suite `test/glitch_mosaic_stereo_flanger_test.dart`.
  - Bumped version to `1.0.86+87` in `pubspec.yaml` and `scripts/configure_android.py`.
  - Verified 100% clean with `python scripts/verify_codebase.py` (464 Dart files scanned).

---

### Phase 24: Luma Keying & Metallic Ring Modulator Suite (Luma Silhouette Keyer, Matrix Digital Rain, Metallic Ring Modulator & Robotic Vocoder) ✅ [COMPLETED] (v1.0.87)
**Goal:** Deliver 3 high-impact, 100% self-dependent creator tools powered by luminance silhouette transparency extraction, cascading digital character rain, and carrier frequency ring modulation DSP:
- [x] **24.1 Luma Key & Silhouette Transparency Studio (`LumaKeyConfig`, `LumaKeyCompilerService`, `LumaKeySheet`)**:
  - Luminance threshold masking (isolating dark silhouettes or bright highlights), soft edge falloff tolerance, invert keying, Skia luminance histogram monitor, and FFmpeg `lumakey` / `colorkey` filter pipeline.
- [x] **24.2 Matrix Digital Code Rain & Cyber Stream Studio (`MatrixRainConfig`, `MatrixRainCompilerService`, `MatrixRainSheet`)**:
  - Cascading green phosphor and cyber glyph rain streaks, variable density and speed, glow persistence, animated Skia digital rain canvas preview, and FFmpeg overlay stream generator.
- [x] **24.3 Metallic Ring Modulator & Robotic Vocoder Studio (`RingModulatorConfig`, `RingModulatorCompilerService`, `RingModulatorSheet`)**:
  - Carrier oscillator multiplication (20 Hz to 4,000 Hz sine/triangle carrier waves), Dalek robotic metallic ringing, sci-fi alien vocoder textures, animated Skia dual-carrier spectrum monitor, and strict AGENTS.md Rule 4 true-peak brickwall ceiling limiter (`alimiter=limit=0.95:attack=5:release=50:asc=1`).
- [x] **Full System Integration & Verification**:
  - Wired into `Clip`, `FFmpegCommandBuilder`, `RealtimePreviewViewport`, `EditorTool`, `DockedToolPanel`, `EditorScreen`, `EditingToolbar`, and `ToolSearchModal` (79 tools indexed).
  - Created comprehensive test suite `test/luma_key_ring_modulator_test.dart`.
  - Bumped version to `1.0.87+88` in `pubspec.yaml` and `scripts/configure_android.py`.
  - Verified 100% clean with `python scripts/verify_codebase.py` (474 Dart files scanned).

---

### Phase 25: Motion Echo Trails & Sub-Bass Exciter Suite (Motion Blur & Echo Decay Trails, ASCII Terminal Matrix Texturizer, Sub-Bass 808 Saturator & Harmonic Exciter) ✅ [COMPLETED] (v1.0.88)
**Goal:** Deliver 3 high-impact, 100% self-dependent creator tools powered by temporal motion decay smearing, retro computing ASCII glyph quantization, and sub-bass psychoacoustic harmonic synthesis:
- [x] **25.1 Motion Blur & Temporal Echo Decay Studio (`EchoMotionConfig`, `EchoMotionCompilerService`, `EchoMotionSheet`)**:
  - Long-exposure motion ghosting and trailing shutter decay (`tblend` / `lagfun` / Skia trailing alpha decay buffer), variable decay persistence, trailing frame count, dreamy slow shutter speed simulation, and optical motion smear.
- [x] **25.2 ASCII Terminal & Retro Matrix Texturizer Studio (`AsciiArtConfig`, `AsciiArtCompilerService`, `AsciiArtSheet`)**:
  - Retro computing ASCII/ANSI character rasterization, monochrome green phosphor or 8-bit colored glyph mapping, font cell resolution scaling, luminance character ramp quantization, animated Skia terminal matrix canvas preview, and FFmpeg filter pipeline.
- [x] **25.3 Sub-Bass 808 Saturator & Harmonic Low-End Exciter Studio (`SubBassExciterConfig`, `SubBassExciterCompilerService`, `SubBassExciterSheet`)**:
  - Deep sub-bass harmonic overtone synthesis (40 Hz to 90 Hz sub-oscillator generation), psychoacoustic low-end warmth exciter, punchy tube saturation drive, animated Skia low-end seismic spectrum analyzer, and strict AGENTS.md Rule 4 true-peak brickwall ceiling limiter (`alimiter=limit=0.95:attack=5:release=50:asc=1`).
- [x] **Full System Integration & Verification**:
  - Wired into `Clip`, `FFmpegCommandBuilder`, `RealtimePreviewViewport`, `EditorTool`, `DockedToolPanel`, `EditorScreen`, `EditingToolbar`, and `ToolSearchModal` (82 tools indexed).
  - Created comprehensive test suite `test/echo_motion_ascii_sub_bass_test.dart`.
  - Bumped version to `1.0.88+89` in `pubspec.yaml` and `scripts/configure_android.py`.
  - Verified 100% clean with `python scripts/verify_codebase.py` (484 Dart files scanned).

---

### Phase 26: Cinematic Radial Blur & Binaural Auto-Pan Dynamic Suite (Anamorphic Radial Zoom Blur, Cyber HUD Hologram Grid, Binaural Auto-Pan & Doppler Swell) ✅ [COMPLETED] (v1.0.89)
**Goal:** Deliver 3 high-impact, 100% self-dependent creator tools powered by radial zoom motion blur, sci-fi cyber tactical HUD reticles, and 3D binaural stereo auto-pan Doppler sweeping DSP:
- [x] **26.1 Anamorphic Radial Zoom Blur Studio (`RadialZoomBlurConfig`, `RadialZoomBlurCompilerService`, `RadialZoomBlurSheet`)**:
  - High-velocity radial zoom blur bursting from customizable focal center, variable blur radius, angular rotation spin blur, animated Skia speed line vortex monitor (`_RadialZoomBlurPainter`), interactive 2D draggable focal crosshairs reticle, and FFmpeg zoom blur filter pipeline (`boxblur`, `lenscorrection`, `rgbashift`, `rotate`, `eq`).
  - 5 curated presets: Hyperspace Warp, Action Impact Zoom, Anamorphic Vortex, Subtle Focus Punch, Dizzy Spin.
- [x] **26.2 Cyber HUD Hologram Grid & Tactical Sci-Fi Reticle Studio (`CyberHudConfig`, `CyberHudCompilerService`, `CyberHudSheet`)**:
  - Sci-fi targeting reticles, concentric radar telemetry rings, angular corner brackets, animated tactical compass coordinates, animated 360° rotating radar sweep arm (`_CyberHudPainter`), 5 emission colors (cyanQuantum, neonGreen, amberWarning, crimsonCombat, violetSyndicate), and FFmpeg overlay filtergraph (`drawgrid`, `drawbox`, center target reticle, unsharp bloom).
  - 5 curated presets: Tactical Lock-On, Sonar Search, Telemetry Data, Combat Assault, Avionics HUD.
- [x] **26.3 Binaural Auto-Pan & Doppler Swell Dynamic Studio (`BinauralAutoPanConfig`, `BinauralAutoPanCompilerService`, `BinauralAutoPanSheet`)**:
  - 3D binaural stereo LFO pan rotation (circular 3D orbit, pendulum swing, Doppler flyby pitch warp, chaotic vortex, subtle stereo spread), animated Skia binaural soundstage circular radar monitor (`_BinauralAutoPanPainter`) with orbiting sound node and Doppler ripples, dynamic L/R meters, and strict AGENTS.md Rule 4 true-peak brickwall ceiling limiter (`alimiter=limit=0.95:attack=5:release=50:asc=1`).
  - 5 curated presets: 3D Spatial Orbit, Binaural Pendulum, Doppler Super-Flyby, Cosmic Chaos Vortex, Subtle Stereo Widen.
- [x] **Full System Integration & Verification**:
  - Wired into `Clip`, `FFmpegCommandBuilder`, `RealtimePreviewViewport`, `EditorTool`, `DockedToolPanel`, `EditorScreen`, `EditingToolbar`, and `ToolSearchModal` (85 searchable tools indexed).
  - Created comprehensive test suite `test/radial_blur_cyber_hud_binaural_test.dart`.
  - Bumped version to `1.0.89+90` in `pubspec.yaml` and `scripts/configure_android.py`.
  - Verified 100% clean with `python scripts/verify_codebase.py` (494 Dart files scanned).

---

### Phase 27: Optical Prism Flare & Multiband Master Compressor Suite (Liquid Water Caustics, Diamond Glass Prism, Multiband Mastering Compressor) 🚀 [PLANNED] (v1.0.90)
**Goal:** Deliver 3 high-impact, 100% self-dependent creator tools powered by liquid light caustics refraction, multifaceted diamond glass prism dispersion, and 3-band studio audio master compression:
- **27.1 Liquid Water Caustics & Underwater Light Wave Studio (`WaterCausticsConfig`, `WaterCausticsCompilerService`, `WaterCausticsSheet`)**:
  - Procedural shimmering underwater caustic light web, refractive ripple distortion, aquatic cyan/deep blue tinting, animated Skia voronoi/wave canvas monitor, and FFmpeg filter pipeline.
- **27.2 Diamond Glass Prism & Geometric Light Refraction Studio (`DiamondPrismConfig`, `DiamondPrismCompilerService`, `DiamondPrismSheet`)**:
  - Multi-faceted optical diamond dispersion, spectral rainbow edge splitting, prismatic facet reflections, animated Skia faceted refraction monitor, and FFmpeg filter pipeline.
- **27.3 Multiband Studio Audio Master Compressor (`MultibandCompressorConfig`, `MultibandCompressorCompilerService`, `MultibandCompressorSheet`)**:
  - Independent 3-band crossover compression (Low, Mid, High), threshold, ratio, attack/release, makeup gain, animated Skia 3-band gain reduction VU meters, and strict AGENTS.md Rule 4 true-peak brickwall ceiling limiter (`alimiter=limit=0.95:attack=5:release=50:asc=1`).

---

## 4. Work Log & Recent Commit History

- **2026-10-03 [Commit `af4d1cc`]:**
  - Added shared on-device AI infrastructure (models, catalog, tiering, runner, manager, dialog).
  - Implemented 100% on-device Whisper STT audio transcription.
  - Replaced legacy cloud API settings with offline on-device flow.
  - Added unit test suites for AI infrastructure and Whisper.
  - Linter verification: 100% clean (329 files).

- **2026-10-03 [Commit `128a471`]:**
  - Added F2 Real Subject Segmentation (MediaPipe Selfie Segmenter).
  - Offline cutouts in SmartCutoutSheet & adaptive neon aura in CharacterHighlightSheet.
  - Linter verification: 100% clean (331 files).

- **2026-10-03 [Commit `fd4c757`]:**
  - Added F3 Auto Subject Tracking for Main Character Zoom.
  - EMA focus smoothing, auto-tracking canvas preview, and manual override.
  - Linter verification: 100% clean (332 files).

- **2026-10-03 [Commit `397f2e1`]:**
  - Added F4 Neural Noise Removal (RNNoise BSD-3).
  - Brickwall limiter ceiling, interactive hold-to-compare A/B auditioning.
  - Added unit test suite `test/neural_noise_removal_test.dart`.
  - Linter verification: 100% clean (333 files).

- **2026-10-03 [F5 Smart Auto-Ducking & Beat Sync]:**
  - Added on-device VAD speech segmentation and sidechain auto-ducking envelopes.
  - Added spectral flux transient onset detector, statistical BPM calculation, and magnetic beat snap.
  - Added twin platform channel methods `detectVoiceActivity` & `detectAudioBeats` in `MainActivity.kt` and `scripts/configure_android.py`.
  - Added unit test suites `test/audio_vad_ducking_test.dart` and `test/beat_sync_onset_test.dart`.
- **2026-10-07 [Self-Dependent Offline Suite (Phase 13 - v1.0.76)]:**
  - Added Real-time Social Retention Progress Bar Studio with Skia Canvas overlay and FFmpeg export filter.
  - Added Ken Burns 2D Photo Motion & Pan/Zoom drift with affine transforms and FFmpeg zoompan export.
  - Added Timeline Micro-Gap Finder & Ripple Closer service and interactive sheet.
  - Added comprehensive test suite `test/self_dependent_offline_suite_test.dart`.
  - Linter verification: 100% clean (365 files).

- **2026-10-07 [Creator Power Suite (Phase 14 - v1.0.77)]:**
  - Added Auto Beat Cut & Rhythm Snapper Studio (`BeatCutterService`, `BeatCutterSheet`) with cadence selection and tempo grid snapping.
  - Added Audio Fade Envelopes & Anti-Pop Crossfade Studio (`AudioFadeConfig`, `AudioFadeSheet`, `AudioFadeCompilerService`) with logarithmic/exponential/S-curve math and FFmpeg `afade`.
  - Added Cinematic Impact Flash & Strobe Accent Studio (`ImpactFlashConfig`, `ImpactFlashSheet`, `ImpactFlashCompilerService`) with Skia preview simulation and FFmpeg `drawbox` cutpoint strobe.
  - Added unit test suite `test/creator_power_suite_test.dart`.
  - Linter verification: 100% clean (374 files).

- **2026-10-07 [Pro Motion & Audio Dynamics Suite (Phase 15 - v1.0.78)]:**
  - Added Action Freeze Frame Climax Studio (`FreezeClimaxService`, `FreezeClimaxSheet`) with camera punch zoom, impact flash, and multi-track ripple sync.
  - Added Bezier Curve Speed Ramping & Optical Ease Studio (`SpeedEaseConfig`, `SpeedEaseCompilerService`, `SpeedEaseSheet`) with Newton-Raphson easing and interactive Skia curve handles.
  - Added 8D Spatial Audio & Stereo Matrix Pan Studio (`SpatialAudioPanConfig`, `SpatialPanCompilerService`, `SpatialPanSheet`) with equal-power panning and binaural headphone radar.
  - Added unit test suite `test/pro_motion_audio_dynamics_test.dart`.
  - Linter verification: 100% clean (384 files).

- **2026-10-07 [Creative Stylist & Typography Dynamics Suite (Phase 16 - v1.0.79)]:**
  - Added Kinetic Typewriter Studio (`TypewriterTitleConfig`, `TypewriterTitleService`, `TypewriterTitleSheet`) with char-by-char, word-by-word, and terminal glitch modes, blinking cursors, and live typing simulation.
  - Added Retro CRT Scanlines & Cyber Phosphor Glow Studio (`CrtScanlineConfig`, `CrtScanlineCompilerService`, `CrtScanlineSheet`) with cathode-ray raster lines, rolling hum bars, 6 phosphor tints, and barrel curvature.
  - Added Audio Reverb Chamber Studio (`ReverbChamberConfig`, `ReverbCompilerService`, `ReverbChamberSheet`) with 7 acoustic room types, multi-tap delay reflections, and true-peak brickwall ceiling limiter.
  - Added unit test suite `test/creative_stylist_typography_dynamics_test.dart`.
  - Linter verification: 100% clean (394 files).

- **2026-10-07 [Optical Glow & Retro Tone Suite (Phase 17 - v1.0.80)]:**
  - Added Anamorphic Streak Flare & Starburst Studio (`AnamorphicFlareConfig`, `AnamorphicFlareCompilerService`, `AnamorphicFlareSheet`) with horizontal bloom stretch, threshold extraction, specular spikes, and Skia Canvas simulation.
  - Added 35mm Film Halation & Emulsion Red Bleed Studio (`FilmHalationConfig`, `FilmHalationCompilerService`, `FilmHalationSheet`) with photochemical backscatter halo, edge bleed, diffusion radius, and film stock presets.
  - Added Vintage Tape Cassette & Wow/Flutter Warble Studio (`TapeCassetteConfig`, `TapeCassetteCompilerService`, `TapeCassetteSheet`) with analog pitch drift, flutter vibration, tape warmth bump, rotating reels preview, and true-peak brickwall ceiling limiter (`alimiter=limit=0.95:attack=5:release=50:asc=1`).
  - Added unit test suite `test/optical_glow_retro_tone_test.dart`.
  - Linter verification: 100% clean (404 files).

- **2026-10-07 [Cinematic Camera & Sound FX Suite (Phase 18 - v1.0.81)]:**
  - Added Organic Handheld Camera Shake & Impact Tremor Studio (`CameraShakeConfig`, `CameraShakeCompilerService`, `CameraShakeSheet`) with harmonic motion drift, 5 shake types, and viewfinder simulation.
  - Added Lens Distortion & Action-Cam Fisheye Studio (`LensDistortionConfig`, `LensDistortionCompilerService`, `LensDistortionSheet`) with barrel/pincushion curvature, chromatic aberration RGB fringe, and optical mesh simulation.
  - Added Vintage Vinyl Turntable & Dusty Needle Studio (`VinylRecordConfig`, `VinylRecordCompilerService`, `VinylRecordSheet`) with 33/45/78 RPM speeds, dust crackle, surface hiss, phono RIAA curve, rotating turntable simulation, and true-peak brickwall ceiling limiter (`alimiter=limit=0.95:attack=5:release=50:asc=1`).
  - Added unit test suite `test/cinematic_camera_sound_fx_test.dart`.
  - Linter verification: 100% clean (414 files).

- **2026-10-07 [Atmospheric Lighting & Retro Texture Suite (Phase 19 - v1.0.82)]:**
  - Added Light Leak Rainbow Prisms Studio (`LightLeakConfig`, `LightLeakCompilerService`, `LightLeakSheet`) with solar flares, prism dispersion, anamorphic cyan beam, exposure breathing, and Skia Canvas simulation.
  - Added Night Vision & Thermal Infrared Scope Studio (`NightVisionConfig`, `NightVisionCompilerService`, `NightVisionSheet`) with Gen-3 phosphor green, FLIR thermal ironbow, rainbow heat gradient, white/black hot IR, scanlines, ocular vignette, and military rangefinder reticle overlay.
  - Added 8-Bit Lo-Fi Chiptune Bitcrusher Studio (`BitcrusherConfig`, `BitcrusherCompilerService`, `BitcrusherSheet`) with NES/GameBoy/Arcade/Walkie-Talkie downsampling, bit-depth DAC quantization, overdrive saturation, animated quantized waveform monitor, and true-peak brickwall ceiling limiter (`alimiter=limit=0.95:attack=5:release=50:asc=1`).
  - Added unit test suite `test/atmospheric_lighting_retro_texture_test.dart`.
  - Linter verification: 100% clean (424 files).

- **2026-10-07 [Prismatic Geometry & Audio Modulation Suite (Phase 20 - v1.0.83)]:**
  - Added Prismatic Kaleidoscope & Radial Mirror Studio (`KaleidoscopeConfig`, `KaleidoscopeCompilerService`, `KaleidoscopeSheet`) with 2-12 radial symmetry facets, rotation drift, focal zoom, animated Skia mandala simulation, and FFmpeg mirror stack filters.
  - Added Glitch Data-Mosh & Compression Artifacts Studio (`DatamoshGlitchConfig`, `DatamoshGlitchCompilerService`, `DatamoshGlitchSheet`) with I-frame dropout simulation, macroblock DCT pixelation, RGB chromatic displacement slices, VHS tracking loss, and Skia glitch canvas preview.
  - Added Stereo Tremolo & Auto-Wah Dynamic Filter Studio (`TremoloWahConfig`, `TremoloWahCompilerService`, `TremoloWahSheet`) with periodic stereo LFO amplitude pulses, dynamic auto-wah bandpass envelope sweeping, Leslie rotary simulation, stutter chopper gate, animated dual-channel LFO waveform monitor, and strict true-peak brickwall ceiling limiter (`alimiter=limit=0.95:attack=5:release=50:asc=1`).
- **2026-10-07 [Spatial Optics & Binaural Dynamics Suite (Phase 21 - v1.0.84)]:**
  - Added Tilt-Shift Miniature & Depth-of-Field Diorama Studio (`TiltShiftConfig`, `TiltShiftCompilerService`, `TiltShiftSheet`) with linear and radial focus bands, box blur falloff, toy-model saturation boost, Skia interactive viewfinder handles, and selective FFmpeg boxblur/blend filter compilation.
  - Added Edge Glow Cyberpunk Neon & Hologram Wireframe Studio (`NeonGlowConfig`, `NeonGlowCompilerService`, `NeonGlowSheet`) with Sobel edge detection, neon phosphor edge mapping, pulsating intensity glow, holographic scanlines, and animated Skia glowing contour monitor.
  - Added Dynamic Vocal Pitch Shifter & Formant Harmonizer Studio (`PitchHarmonizerConfig`, `PitchHarmonizerCompilerService`, `PitchHarmonizerSheet`) with semitone/cent transposition, dual-voice interval harmonies, ring modulation, animated musical keyboard visualizer, and strict true-peak brickwall ceiling limiter (`alimiter=limit=0.95:attack=5:release=50:asc=1`).
  - Added comprehensive test suite `test/spatial_optics_binaural_dynamics_test.dart`.
  - Linter verification: 100% clean (444 files).

- **2026-10-07 [Dynamic Optics & Audio Stutter Suite (Phase 22 - v1.0.85)]:**
  - Added RGB Color Aberration & Holographic Glitch Shift Studio (`ChromaticAberrationConfig`, `ChromaticAberrationCompilerService`, `ChromaticAberrationSheet`) with linear/radial RGB channel separation, 3D anaglyph stereoscopic shift, hologram jitter oscillation, and animated Skia RGB split monitor.
  - Added Thermal Solarization & Psychedelic Color Invert Studio (`SolarizeInvertConfig`, `SolarizeInvertCompilerService`, `SolarizeInvertSheet`) with Sabattier tone inflection thresholds, negative film inversion, psychedelic hue cycling, FLIR thermal false-color mapping, and animated Skia transfer curve monitor.
  - Added Rhythmic Audio Stutter & Glitch Buffer Beat Repeater Studio (`AudioStutterConfig`, `AudioStutterCompilerService`, `AudioStutterSheet`) with 1/4 to 1/32 beat divisions, accelerating drill build-ups, tape stop pitch drops, animated buffer slice sequencer, and strict true-peak brickwall ceiling limiter (`alimiter=limit=0.95:attack=5:release=50:asc=1`).
  - Added comprehensive test suite `test/dynamic_optics_audio_stutter_test.dart`.
  - Linter verification: 100% clean (454 files).

- **2026-10-08 [Glitch Mosaic & Stereo Flanger Dynamic Suite (Phase 23 - v1.0.86)]:**
  - Added Pixel Sort & Glitch Streak Studio (`PixelSortConfig`, `PixelSortCompilerService`, `PixelSortSheet`) with threshold-based luminance pixel sorting, directional digital streaks, horizontal tearing, radiant bursts, animated Skia streak flow monitor, and FFmpeg displacement glitch filtergraph.
  - Added Threshold Posterization & Pop Art Chromatic Studio (`PosterizePopConfig`, `PosterizePopCompilerService`, `PosterizePopSheet`) with discrete color quantization (2 to 16 levels), Andy Warhol silk-screen pop art color mapping, comic book inked shading, and FFmpeg `lutrgb` channel quantization stepping.
  - Added Jet Flanger & Barberpole Frequency Phaser Studio (`JetFlangerConfig`, `JetFlangerCompilerService`, `JetFlangerSheet`) with comb-filter resonant sweeping simulating jet flybys, barberpole infinite phasing, metallic ringing, animated frequency notch visualizer, and strict Rule 4 true-peak brickwall ceiling limiter (`alimiter=limit=0.95:attack=5:release=50:asc=1`).
  - Integrated into `Clip`, `FFmpegCommandBuilder`, `RealtimePreviewViewport`, `EditorTool`, `DockedToolPanel`, `EditorScreen`, `EditingToolbar`, and `ToolSearchModal` (76 tools indexed).
  - Added comprehensive unit test suite `test/glitch_mosaic_stereo_flanger_test.dart`.
  - Bumped version to `1.0.86+87` in `pubspec.yaml` and `scripts/configure_android.py`.
  - Linter verification: 100% clean (464 files).

- **2026-10-08 [Luma Keying & Metallic Ring Modulator Suite (Phase 24 - v1.0.87)]:**
  - Added Luma Key & Silhouette Transparency Studio (`LumaKeyConfig`, `LumaKeyCompilerService`, `LumaKeySheet`) with luminance threshold keying (dark silhouette, bright specular, midtones, high contrast, soft threshold gradient), soft falloff tolerance, invert keying, Skia luminance checkerboard monitor, and FFmpeg `format=yuva420p`, `lumakey` / `negate` filter pipeline.
  - Added Matrix Digital Code Rain & Cyber Stream Studio (`MatrixRainConfig`, `MatrixRainCompilerService`, `MatrixRainSheet`) with 5 color modes (classic phosphor green, cyberpunk neon pink, quantum cyan, golden ascii, ghost monochrome), variable fall speed, glyph density, glow radius, animated Skia cascading digital rain stream monitor, and FFmpeg drawgrid / scanlines / color tint overlay filter pipeline.
  - Added Metallic Ring Modulator & Robotic Vocoder Studio (`RingModulatorConfig`, `RingModulatorCompilerService`, `RingModulatorSheet`) with 5 presets (Dalek robotic, alien vocoder, sub-harmonic tremor, cyber bell bells, dual-carrier sci-fi), carrier frequencies 20 Hz to 4,000 Hz, AM modulation depth, overtone harmonic saturation, animated Skia carrier oscillator envelope monitor, and strict AGENTS.md Rule 4 true-peak brickwall ceiling limiter (`alimiter=limit=0.95:attack=5:release=50:asc=1`).
  - Integrated into `Clip`, `FFmpegCommandBuilder`, `RealtimePreviewViewport`, `EditorTool`, `DockedToolPanel`, `EditorScreen`, `EditingToolbar`, and `ToolSearchModal` (79 tools indexed).
  - Added comprehensive unit test suite `test/luma_key_ring_modulator_test.dart`.
  - Bumped version to `1.0.87+88` in `pubspec.yaml` and `scripts/configure_android.py`.
  - Linter verification: 100% clean (474 files scanned).

- **2026-10-08 [Motion Echo Trails & Sub-Bass Exciter Suite (Phase 25 - v1.0.88)]:**
  - Added Motion Echo Trails & Temporal Smear Studio (`EchoMotionConfig`, `EchoMotionCompilerService`, `EchoMotionSheet`) with 5 echo modes (smoothMotionBlur, longExposureGhost, phantomEcho, lightTrailSmear, dreamySlowShutter), 1-12 echo decay frames, trail decay weight, Skia Canvas motion lag and ghosting monitor, and FFmpeg `tmix` / `lagfun` / `tblend` temporal blend filters.
  - Added Cyberpunk ASCII Art & Matrix Pixel Quantizer Studio (`AsciiArtConfig`, `AsciiArtCompilerService`, `AsciiArtSheet`) with 5 color themes (greenPhosphor, amberCathode, cyberpunkNeon, matrixColor, monochromePaper), cell size downscale/upscale quantization, character ramp density, contrast boost, CRT phosphor bloom, animated procedural ASCII ramp Skia monitor, and FFmpeg scale quantization with `drawgrid` cell boundary rasterization.
  - Added Sub-Bass Harmonic Exciter & Low-End Synthesizer Studio (`SubBassExciterConfig`, `SubBassExciterCompilerService`, `SubBassExciterSheet`) with 5 sub modes (club808Punch, cinematicSubRumble, analogWarmthDrive, phoneSpeakerExciter, heavyBassDrop), sub-frequency tuning (30-120 Hz), sub-harmonic boost, 2nd & 3rd harmonic overtone excitation, softclip saturation, animated seismic sub-acoustic ripple Skia monitor, and strict AGENTS.md Rule 4 true-peak brickwall ceiling limiter (`alimiter=limit=0.95:attack=5:release=50:asc=1`).
  - Integrated into `Clip`, `FFmpegCommandBuilder`, `RealtimePreviewViewport`, `EditorTool`, `DockedToolPanel`, `EditorScreen`, `EditingToolbar`, and `ToolSearchModal` (82 searchable tools indexed).
  - Added comprehensive unit test suite `test/echo_motion_ascii_sub_bass_test.dart`.
  - Bumped version to `1.0.88+89` in `pubspec.yaml` and `scripts/configure_android.py`.
- **2026-10-08 [Cinematic Radial Blur & Binaural Auto-Pan Dynamic Suite (Phase 26 - v1.0.89)]:**
  - Added Anamorphic Radial Zoom Blur Studio (`RadialZoomBlurConfig`, `RadialZoomBlurCompilerService`, `RadialZoomBlurSheet`) with 5 blur modes, focal center drag crosshairs, and FFmpeg filter pipeline.
  - Added Cyber HUD Hologram Grid & Tactical Sci-Fi Reticle Studio (`CyberHudConfig`, `CyberHudCompilerService`, `CyberHudSheet`) with 5 HUD modes, 5 emission colors, animated rotating radar sweep arm, and FFmpeg overlay pipeline.
  - Added 3D Binaural Auto-Pan & Doppler Swell Dynamic Studio (`BinauralAutoPanConfig`, `BinauralAutoPanCompilerService`, `BinauralAutoPanSheet`) with 5 trajectory modes, Doppler pitch shift, and strict AGENTS.md Rule 4 true-peak brickwall ceiling limiter (`alimiter=limit=0.95:attack=5:release=50:asc=1`).
  - Integrated into `Clip`, `FFmpegCommandBuilder`, `RealtimePreviewViewport`, `EditorTool`, `DockedToolPanel`, `EditorScreen`, `EditingToolbar`, and `ToolSearchModal` (85 searchable tools indexed).
  - Added comprehensive unit test suite `test/radial_blur_cyber_hud_binaural_test.dart`.
  - Bumped version to `1.0.89+90` in `pubspec.yaml` and `scripts/configure_android.py`.
  - Linter verification: 100% clean (494 files scanned).

---

## 5. Quick Reference & Commands

- **Run Architecture Linter:**
  ```powershell
  python scripts/verify_codebase.py
  ```
- **Run Unit Tests (when Dart/Flutter available or on CI):**
  ```powershell
  flutter test test/on_device_ai_infrastructure_test.dart test/on_device_whisper_test.dart
  ```
- **Git Commit Template:**
  ```powershell
  git add -A
  git commit -m "feat: <feature description> (F#)"
  ```
