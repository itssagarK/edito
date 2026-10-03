# Third-Party Licenses & Open Source ML Attribution

This document records the exact licenses and copyright details for all on-device machine learning models, libraries, and weights utilized in **Edito Video Editor**.

In strict accordance with the project guidelines, **all models and runtime dependencies operate 100% on-device and offline**, without any cloud API keys, external servers, or network telemetry. Furthermore, **only permissive open-source licenses (MIT, Apache-2.0, BSD)** are permitted. Copyleft (GPL, AGPL) or non-commercial (CC-BY-NC) models and code are strictly prohibited.

---

## 1. Speech-to-Text: OpenAI Whisper / whisper.cpp

- **Purpose**: Offline speech recognition, automatic transcription, and word-level timestamp generation for auto-captions.
- **Model**: Whisper `tiny` / `base` quantized GGML / ONNX format.
- **License**: MIT License
- **Original Model Copyright**: © OpenAI (2022–2023)
- **whisper.cpp Engine Copyright**: © 2023–2024 Georgi Gerganov and contributors
- **License Text (MIT)**:
```
MIT License

Copyright (c) 2023 Georgi Gerganov
Copyright (c) 2022 OpenAI

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 2. Vision & Cutout: MediaPipe Selfie Segmentation

- **Purpose**: Real-time on-device human selfie & portrait background segmentation (replacing manual coordinates with automated alpha matte).
- **Model**: MediaPipe Selfie Segmentation (`selfie_segmentation.tflite` / `selfie_multiclass.tflite`).
- **Model Size**: ~250 KB
- **License**: Apache License, Version 2.0
- **Copyright**: © 2021–2024 Google LLC
- **License Text (Apache-2.0)**:
```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## 3. Vision & Motion: MediaPipe BlazeFace

- **Purpose**: Ultra-fast facial landmark & bounding box detection for auto-subject tracking, main character zoom, and auto-reframe centering.
- **Model**: MediaPipe Face Detection Short Range (`face_detection_short_range.tflite`).
- **Model Size**: ~220 KB
- **License**: Apache License, Version 2.0
- **Copyright**: © 2020–2024 Google LLC
- **License Reference**: https://github.com/google/mediapipe

---

## 4. Audio Processing: RNNoise (Neural Noise Suppression)

- **Purpose**: Recurrent neural network for real-time speech noise suppression and background hum removal.
- **Weights & Algorithm**: RNNoise GRU model (~1.8 MB).
- **License**: BSD 3-Clause License
- **Copyright**: © 2017–2020 Jean-Marc Valin / Xiph.Org Foundation
- **License Text (BSD-3-Clause)**:
```
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

---

## 5. Audio Intelligence: Silero VAD (Voice Activity Detector)

- **Purpose**: High-precision enterprise voice activity detection for smart auto-ducking envelopes and beat synchronization.
- **Model**: Silero VAD v4 / v5 (`silero_vad.onnx`).
- **Model Size**: ~1.8 MB
- **License**: MIT License
- **Copyright**: © 2020–2024 Silero Team
- **License Reference**: https://github.com/snakers4/silero-vad

---

## 6. Super Resolution: Real-ESRGAN Compact

- **Purpose**: Practical image and short-clip super-resolution upscaling (anime/video compact model with tiling).
- **Model**: Real-ESRGAN Compact (`realesr-animevideov3` / RealESRGAN_x4plus).
- **Model Size**: ~5.3 MB
- **License**: BSD 3-Clause License
- **Copyright**: © 2021–2024 Xintao Wang, Liangbin Xie, Chao Dong, Ying Shan (Applied Research Center, Tencent PCG)
- **License Reference**: https://github.com/xinntao/Real-ESRGAN

---

## Summary of License Compliance

| Feature | Model / Component | License | Size | Offline | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **F1. Auto Captions** | Whisper Tiny (int8) | **MIT** | ~39 MB | 100% On-Device | Approved |
| **F2. Segmentation** | MediaPipe Selfie Seg | **Apache-2.0** | ~250 KB | 100% On-Device | Approved |
| **F3. Tracking** | MediaPipe BlazeFace | **Apache-2.0** | ~220 KB | 100% On-Device | Approved |
| **F4. Noise Removal** | RNNoise Neural Filter | **BSD-3-Clause** | ~1.8 MB | 100% On-Device | Approved |
| **F5. Auto-Ducking** | Silero VAD | **MIT** | ~1.8 MB | 100% On-Device | Approved |
| **F6. AI Upscaler** | Real-ESRGAN Compact | **BSD-3-Clause** | ~5.3 MB | 100% On-Device | Approved |

*All items comply with the Edito strict permissive license policy.*
