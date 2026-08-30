# Phase 0 Specification — Project Skeleton & Automated CI/CD

## 1. Objectives
1. Bootstrap the Flutter project structure adhering to the modular Clean Architecture.
2. Establish a production-grade dark cinematic theme suitable for high-end video editors (inspired by DaVinci Resolve & CapCut).
3. Set up the GitHub Actions CI/CD pipeline to automatically compile debug APKs on push and signed release APKs on version tags (`v*`).
4. Build the core app navigation shell: Splash Screen, Project Management Home Screen, and the Editor workspace shell.

## 2. In-Scope Components
- **`lib/main.dart`**: Global application initialization and Riverpod provider scope.
- **`lib/core/theme/`**: Theme definitions, high-contrast dark palette, accent colors, typography, and button styling.
- **`lib/core/constants/`**: App-wide constants (routes, limits, dimension tokens).
- **`lib/features/home/`**:
  - Home dashboard with project cards, search, and "New Project" launcher.
  - Project card showing thumbnail, title, duration, last modified timestamp, and delete/duplicate actions.
- **`lib/features/editor/`**:
  - Responsive workspace shell (Preview viewport, Timeline placeholder, and bottom editing toolbar).
  - Top app bar with back navigation, project title, undo/redo buttons, and export action.
- **`.github/workflows/build-apk.yml`**:
  - Lint and unit test stage.
  - Build Android APK (`flutter build apk --split-per-abi` or universal fat APK).
  - Upload build artifacts & create GitHub Release with APK attachment upon tag creation.

## 3. Out of Scope (Deferred to Future Phases)
- Real media decode and hardware surface composition (Phase 1 & Phase 3).
- Live multi-track timeline interactions (Phase 2).
- FFmpeg export invocation (Phase 8).

## 4. Acceptance Criteria
- [x] Flutter project compiles with zero analyzer warnings.
- [x] App boots into Home screen with fluid transitions.
- [x] User can click "New Project" to transition into the Editor workspace shell.
- [x] Editor workspace renders top bar, preview area, timeline placeholder, and tool selector.
- [x] GitHub Actions workflow is valid and ready to execute on repository push.
