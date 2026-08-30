# Phase 2 Specification — Timeline UI & Multi-Track Editing

## 1. Objectives
1. Build a high-performance, 60fps multi-track timeline UI supporting pinch-to-zoom, horizontal pan, and vertical track scrolling.
2. Implement non-destructive clip operations:
   - **Split at Playhead**: Splits selected clip into two contiguous clips adjusting `sourceInMs` and `sourceOutMs`.
   - **Trim Handles**: Interactive left/right drag handles on active clip with visual timestamp feedback.
   - **Drag & Reorder**: Reposition clips within or across compatible tracks (video/video, audio/audio).
   - **Magnetic Snapping**: Auto-snap playhead and clip edges to adjacent clip boundaries within a configurable snap threshold (150ms).
   - **Delete / Duplicate**: Quick deletion (with optional ripple shifting) and instant clip duplication.
3. Provide track-level controls: Mute audio, Lock track (prevent edits), and Hide visual layer.
4. Establish frozen interface contracts for Timeline engine so Phase 3 (Real-Time Preview) and Phase 8 (FFmpeg Export) can consume the project state without modifications.

---

## 2. Public Interface Contracts (Frozen)

### 2.1 `TimelineEditingService`
- `Project splitClip(Project project, String clipId, int splitPositionMs)`
- `Project trimClipHead(Project project, String clipId, int deltaMs)`
- `Project trimClipTail(Project project, String clipId, int deltaMs)`
- `Project moveClip(Project project, String clipId, String targetTrackId, int newStartTimeMs)`
- `Project duplicateClip(Project project, String clipId)`
- `Project deleteClip(Project project, String clipId, {bool ripple = true})`
- `int calculateSnapTime(Project project, int targetTimeMs, {int thresholdMs = 150, String? ignoreClipId})`

### 2.2 `TimelineTrackLane`
- Accepts `Track`, `zoomScale`, `selectedClipId`, `playheadPositionMs`, and callbacks for clip selection, drag, and trim events.

---

## 3. UI Interactions & Gestures
1. **Pinch-to-Zoom:** Scales timeline horizontally between `0.2x` (overview) and `5.0x` (frame-accurate editing).
2. **Playhead Scrubbing:** Dragging the ruler or playhead needle smoothly updates playhead timestamp with haptic-ready snapping.
3. **Clip Selection:** Tapping a clip highlights it with a glowing border and reveals the left & right trim handles plus the floating context action bar.
4. **Trimming:** Dragging the left handle alters `startTimeMs`, `sourceInMs`, and `durationMs`. Dragging the right handle alters `sourceOutMs` and `durationMs`.
5. **Splitting:** Tapping "Split" in the toolbar cuts the selected clip directly at the playhead position.

---

## 4. Acceptance Criteria
- [x] Splitting a clip preserves exact audio/video synchronization across both halves.
- [x] Trimming handles cannot reduce clip duration below 100ms or exceed source media duration.
- [x] Snapping accurately locks to adjacent clip start/end times within 150ms.
- [x] Track controls (Mute, Lock, Hide) update track state without mutating media files.
- [x] All timeline operations update project duration dynamically and trigger auto-save.
- [x] Comprehensive unit tests verify split, trim, move, and snap algorithms.
