# Edito - On-Device AI Features Master Plan & Task Tracker

> **Last Updated:** 2026-10-03  
> **Target:** High-Performance, 100% On-Device & Offline AI Video Editing Engine (Edito)  
> **Status:** Phase 0, 1, 2, 3, 4, 5 **COMPLETED** | Phase 6 (F6: AI Upscaler & Enhancer) **IN PROGRESS**

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
   - Look at the **[IN PROGRESS]** tag.
   - Read the **Immediate Next Steps** in that section.
4. **Resume Coding Directly** without needing to re-prompt from scratch.

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
| **3** | **F3** | Auto Subject Tracking (Zoom) | MediaPipe Face / Centroid + Kalman/EMA | Apache-2.0 | ✅ **COMPLETED** |
| **4** | **F4** | Neural Noise Removal | FFmpeg `arnndn` (RNNoise) | BSD-3 | ✅ **COMPLETED** (`397f2e1`) |
| **5** | **F5** | Smart Auto-Ducking & Beat Sync | Silero VAD / Energy VAD + Onset Detection | MIT | ✅ **COMPLETED** |
| **6** | **F6** | AI Upscaler & Enhancer | Real-ESRGAN Compact (ncnn/ONNX, Tiled) | BSD-3 | 🔄 **IN PROGRESS** |

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

### Phase 6: F6 - AI Upscaler & Image Enhancer 🔄 [IN PROGRESS]
**Goal:** Super-resolution for thumbnails, cover images, and short clip frames.
- **Model:** Real-ESRGAN Compact (BSD-3-Clause) via ncnn/ONNX.
- **Safety:** Tiled execution (256x256 tiles with 16px overlap) to prevent Android out-of-memory.
- **UI:** Honest progress indicator in `VideoEnhancementSheet` / `HdConverterSheet`.

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
