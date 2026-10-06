# Edito - On-Device AI Features Master Plan & Task Tracker

> **Last Updated:** 2026-10-03  
> **Target:** High-Performance, 100% On-Device & Offline AI Video Editing Engine (Edito)  
> **Status:** Phase 0, 1, 2, 3, 4, 5, 6, 7 **ALL COMPLETED** | 100% On-Device & Offline AI Feature Suite & Unified Rendering Engine Complete

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
   - All features F1–F6 are complete.
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
  - Linter verification: 100% clean (336 files).

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
