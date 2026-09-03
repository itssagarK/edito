# Edito Project Rules & Coding Guidelines for Antigravity AI Agents

Welcome to **Edito**, a professional high-performance video and image editor application built with Flutter and modern Android platform bindings.

---

## 1. Project Architecture & Directory Layout

The project follows a clean, feature-driven modular structure:
```
lib/
├── core/                         # Shared utilities, themes, services
│   ├── services/                 # Crash reporting, storage, system services
│   └── theme/                    # App colors, typography, themes
├── models/                       # Global domain models (Project, Track, Clip, MediaAsset)
└── features/                     # Feature modules
    ├── audio/                    # Voice booster, dynamic limiter, audio mixer
    ├── captions/                 # Auto-captions, script converter, SRT formatter
    ├── chroma/                   # Chroma Key green/blue screen removal
    ├── color_grading/            # Color looks, 4x5 GPU matrices, RGB curves
    ├── editor/                   # Main editor screen, toolbar, providers
    ├── enhancement/              # 8K Lanczos upscaler & detail enhancer
    ├── export/                   # Export render service, FFmpegCommandBuilder
    ├── history/                  # Undo/Redo stack manager
    ├── home/                     # Project list, recent projects, template cards
    ├── image_editor/             # Thumbnail & cover designer, layout ratios, stickers
    ├── media/                    # Gallery picker, 4K proxy generator, probe
    ├── overlays/                 # Text titles, keyframe motion animation
    ├── preview/                  # VideoPlaybackBridge, viewport, compositor
    ├── smoothing/                # Video smoother & anti-flutter
    ├── speed/                    # Speed ramping & curve presets
    ├── timeline/                 # Interactive multi-track timeline widget
    └── transitions/              # Video transition selector & compiler
```

---

## 2. Strict Coding & Import Rules

1. **Relative Imports**:
   - When importing from `lib/features/<feature>/presentation/widgets/`, relative imports to `models/` or `services/` within that feature require `../../` (two directory levels up), NOT `../`.
   - Always prefer `import '../../models/xyz.dart';` or package imports.
2. **List-Based Assets**:
   - `project.assets` is a `List<MediaAsset>`, NOT a `Map<String, MediaAsset>`. Lookup by ID requires `.firstWhere` or loop search; never use `project.assets[id]`.
3. **No Phantom Feature Claims**:
   - Do not claim neural network super-resolution if using algorithmic Lanczos interpolation.
   - Do not claim 3D LUT `.cube` parsing if using 4x5 color matrices. Keep UI and code labels technically honest.
4. **Audio Limiter Safeguards**:
   - Any audio boost must include a true-peak brickwall ceiling (`alimiter=limit=0.95:attack=5:release=50:asc=1`) to eliminate digital clipping.
5. **Widget Styling**:
   - Use `IconButton.styleFrom(...)` instead of `IconButton.filledStyleFrom(...)` for universal Flutter compatibility.

---

## 3. Release & CI/CD Pipeline

- CI builds run on GitHub Actions (`.github/workflows/build-apk.yml`) triggered on pushes to `main` and version tags (`v*`).
- Automated releases: pushing a new version tag (e.g., `v1.0.9`) automatically runs all unit tests, compiles `app-release.apk` with Android SDK 36, and publishes it to GitHub Releases.
- When bumping versions:
  - Update `version: X.Y.Z+W` in `pubspec.yaml`.
  - Update `versionCode = W` and `versionName = "X.Y.Z"` in `scripts/configure_android.py`.
