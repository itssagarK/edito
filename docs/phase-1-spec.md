# Phase 1 Specification — Media Import & Project Data Model

## 1. Objectives
1. Implement a unified media import pipeline supporting Video, Audio, and Image formats from device storage and gallery.
2. Probe media files for technical metadata: duration (ms), width, height, aspect ratio, frame rate (fps), and file size.
3. Generate and cache low-res thumbnail previews for video frames and images to disk for efficient memory usage.
4. Finalize the immutable project data model and storage engine (`ProjectStorageService`) with atomic JSON persistence.
5. Integrate the Media Picker bottom sheet into the Editor workspace so users can import clips directly into timeline tracks.

## 2. Public Interface Contracts (Frozen for Future Phases)

### 2.1 `MediaAsset` Model
- `id`: Unique UUID.
- `path`: Absolute file path on the device.
- `fileName`: Original file name.
- `type`: `MediaType.video`, `MediaType.audio`, `MediaType.image`.
- `durationMs`: Duration in milliseconds.
- `width`, `height`: Pixel dimensions (e.g. 1920x1080).
- `fps`: Frame rate (e.g. 30.0, 60.0).
- `fileSize`: File size in bytes.
- `thumbnailPath`: Local cached thumbnail image path.

### 2.2 `Project` & Timeline Operations
- `Project.addAsset(MediaAsset asset)` -> Returns updated `Project`.
- `Project.addClipToTrack(String trackId, Clip clip)` -> Appends clip, updates `durationMs`.
- `Project.removeClip(String clipId)` -> Removes clip, recalculates timeline duration.

### 2.3 `MediaPickerService`
- `Future<List<MediaAsset>> pickVideos({bool allowMultiple = true})`
- `Future<List<MediaAsset>> pickAudios({bool allowMultiple = true})`
- `Future<List<MediaAsset>> pickImages({bool allowMultiple = true})`

## 3. UI Behavior
1. In the Editor workspace, user clicks "Add Media" or the `+` button on the timeline.
2. The `MediaPickerSheet` opens with tabs: **Videos**, **Audio**, **Images**.
3. User selects one or more items. The sheet displays selection badges and instant duration/resolution tags.
4. Upon confirmation ("Add to Project"), the engine probes metadata, generates thumbnails in the background, appends clips to the primary video/audio track, and updates the timeline view.

## 4. Edge Cases & Resilience
- **Unsupported/Corrupt file:** Graceful error snackbar without crashing the editor.
- **Zero-duration image:** Default image clip duration set to 3000ms (3 seconds), user-adjustable.
- **Large 4K files:** Extract metadata asynchronously without freezing the UI thread.
- **Missing thumbnail:** Fallback to vector icon placeholder while background thumbnail generator completes.

## 5. Acceptance Criteria
- [x] Media picker works for videos, audio files, and photos.
- [x] Correct metadata (dimensions, duration, fps) is probed and attached to `MediaAsset`.
- [x] Selected assets create corresponding `Clip` entries positioned accurately on the timeline.
- [x] Project JSON serialization / deserialization roundtrip preserves all clip and track data.
- [x] Tests cover project serialization, asset creation, and duration calculations.
