# Phase 6 Specification — Audio Tools & On-Device AI Voice Enhancement

## 1. Objectives
1. Implement **On-Device AI Voice Enhancement & Noise Suppression**:
   - Neural speech de-noising engine (DeepFilterNet / RNNoise ONNX pipeline abstraction).
   - Real-time parameter graph: De-noise intensity (0–100%), Voice Clarity boost, and Low-cut rumble filter.
   - A/B **Before / After** preview toggle for instant speech comparison.
2. Build comprehensive **Audio Mixing Tools**:
   - Volume adjustment from 0% (silence) up to 200% (boost).
   - Non-destructive Fade-In and Fade-Out envelopes (0 to 5000ms).
   - **Smart Auto-Ducking**: Automatically attenuates background music tracks (by -10dB to -20dB) when speech is active on video tracks.
3. Build **Waveform Generation & Visualization**:
   - Extracts and renders visual amplitude peaks on audio and video clips in the timeline.
4. Provide a cohesive **Audio & AI Voice Modal** in the editor workspace.

---

## 2. Public Interface Contracts (Frozen)

### 2.1 `AudioEffectsConfig` Model
```dart
class AudioEffectsConfig {
  final bool isVoiceEnhancerEnabled;
  final double denoiseIntensity;      // 0.0 to 1.0
  final double voiceClarityGain;       // 0.0 to 2.0 (1.0 = neutral)
  final int fadeInMs;                 // 0 to 5000ms
  final int fadeOutMs;                // 0 to 5000ms
  final bool isDuckingEnabled;        // Duck this track during speech
  final double duckingAttenuation;    // 0.1 to 0.9 (default 0.3)
}
```

### 2.2 `AIVoiceEnhancerService`
- `String generateFFmpegFilter(AudioEffectsConfig config)`
- `Future<bool> runOnDeviceDenoise(String inputAudioPath, String outputAudioPath, {double intensity})`

### 2.3 `AudioDuckingService`
- `double calculateDuckingFactor(Project project, Track currentTrack, int timestampMs)`

---

## 3. UI Behavior
1. User selects an audio or video clip and taps **"Audio / AI"** in the toolbar.
2. `AudioMixerSheet` slides up presenting:
   - Volume slider with decibel / percentage readout.
   - **AI Voice Clean** toggle with intensity slider.
   - Fade In & Fade Out sliders.
   - **Auto-Ducking** switch.
   - "Before / After" A/B testing button.
3. Modifications immediately update the project state and are reflected in the preview engine and timeline waveforms.

---

## 4. Acceptance Criteria
- [x] Audio configuration serializes/deserializes into `Clip.toJson()` without data loss.
- [x] Auto-ducking algorithm calculates correct attenuation factors when speech clips are active.
- [x] AI Voice Enhancer produces valid audio filter graphs for both preview and Phase 8 FFmpeg export.
- [x] Audio mixer modal allows adjusting volume, fade envelopes, and AI speech clarity.
- [x] Waveform painter renders amplitude bars on timeline audio clips.
- [x] Unit tests verify ducking attenuation, volume curves, and audio filter string compilation.
