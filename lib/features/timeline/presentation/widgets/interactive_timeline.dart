import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/project.dart';
import '../../../../models/track.dart';
import '../../../../models/clip.dart';
import '../../services/timeline_editing_service.dart';
import '../../../beats/presentation/widgets/beat_detection_sheet.dart';
import 'timeline_track_lane.dart';
import 'timeline_context_bar.dart';
import 'timeline_clip_widget.dart';

class InteractiveTimeline extends StatefulWidget {
  final Project project;
  final int playheadPositionMs;
  final double zoomScale;
  final String? selectedClipId;
  final Function(int positionMs) onSeek;
  final Function(double zoom) onZoomChanged;
  final Function(String? clipId, {String? trackId}) onSelectClip;
  final Function(Project updatedProject) onProjectMutated;
  final VoidCallback onAddMedia;

  const InteractiveTimeline({
    super.key,
    required this.project,
    required this.playheadPositionMs,
    required this.zoomScale,
    this.selectedClipId,
    required this.onSeek,
    required this.onZoomChanged,
    required this.onSelectClip,
    required this.onProjectMutated,
    required this.onAddMedia,
  });

  @override
  State<InteractiveTimeline> createState() => _InteractiveTimelineState();
}

class _InteractiveTimelineState extends State<InteractiveTimeline> {
  final ScrollController _horizontalScrollController = ScrollController();
  double _baseZoomScale = 1.0;
  bool _isRippleEnabled = true;
  int? _activeSnapGuideMs;
  String? _activeSnapTarget;

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InteractiveTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playheadPositionMs != oldWidget.playheadPositionMs && _horizontalScrollController.hasClients) {
      final pps = AppConstants.timelinePixelsPerSecond * widget.zoomScale;
      final playheadPx = (widget.playheadPositionMs / 1000.0) * pps;
      final currentScroll = _horizontalScrollController.offset;
      final viewportWidth = _horizontalScrollController.position.viewportDimension;

      // Auto-follow playhead during playback or long seeks
      if (playheadPx > currentScroll + viewportWidth - 60) {
        _horizontalScrollController.jumpTo((playheadPx - viewportWidth / 3).clamp(0.0, _horizontalScrollController.position.maxScrollExtent));
      } else if (playheadPx < currentScroll) {
        _horizontalScrollController.jumpTo((playheadPx - 40).clamp(0.0, _horizontalScrollController.position.maxScrollExtent));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pps = AppConstants.timelinePixelsPerSecond * widget.zoomScale;
    final totalDurationMs = widget.project.durationMs > 0 ? widget.project.durationMs : 30000;
    final timelineWidth = (totalDurationMs / 1000.0) * pps + 800; // Buffer for dragging

    final totalTracksHeight = 32.0 + (widget.project.tracks.length * (AppConstants.timelineTrackHeight + 8.0)) + 60.0;

    return GestureDetector(
      onScaleStart: (details) {
        _baseZoomScale = widget.zoomScale;
      },
      onScaleUpdate: (details) {
        if (details.scale != 1.0) {
          final newZoom = (_baseZoomScale * details.scale).clamp(0.2, 5.0);
          widget.onZoomChanged(newZoom);
        }
      },
      child: Container(
        color: AppColors.background,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          physics: const ClampingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Fixed Left Track Headers Column
              SizedBox(
                width: AppConstants.timelineHeaderWidth,
                child: Column(
                  children: [
                    // Corner Header: Magnetic Ripple Toggle
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isRippleEnabled = !_isRippleEnabled;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isRippleEnabled ? '🧲 Magnetic Ripple: ON' : '🔓 Freeform Gaps: ON'),
                            duration: const Duration(milliseconds: 600),
                            backgroundColor: AppColors.surfaceElevated,
                          ),
                        );
                      },
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: _isRippleEnabled ? AppColors.accent.withOpacity(0.15) : AppColors.surfaceElevated,
                          border: const Border(
                            top: BorderSide(color: AppColors.border),
                            bottom: BorderSide(color: AppColors.border),
                            right: BorderSide(color: AppColors.border),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.linear_scale,
                              size: 13,
                              color: _isRippleEnabled ? AppColors.accent : AppColors.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _isRippleEnabled ? 'Ripple' : 'Free',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _isRippleEnabled ? AppColors.accent : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Track Control Headers
                    ...widget.project.tracks.map((track) {
                      return Container(
                        height: AppConstants.timelineTrackHeight,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: track.isLocked ? AppColors.accentWarm.withOpacity(0.4) : AppColors.border,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  track.type == TrackType.video
                                      ? Icons.videocam
                                      : (track.type == TrackType.audio ? Icons.audiotrack : Icons.title),
                                  size: 13,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    track.name,
                                    style: AppTypography.labelSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Mute
                                InkWell(
                                  onTap: () {
                                    final updated = track.copyWith(isMuted: !track.isMuted);
                                    widget.onProjectMutated(widget.project.copyWith(
                                      tracks: widget.project.tracks.map((t) => t.id == updated.id ? updated : t).toList(),
                                    ));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Icon(
                                      track.isMuted ? Icons.volume_off : Icons.volume_up,
                                      size: 14,
                                      color: track.isMuted ? AppColors.accentWarm : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Lock
                                InkWell(
                                  onTap: () {
                                    final updated = track.copyWith(isLocked: !track.isLocked);
                                    widget.onProjectMutated(widget.project.copyWith(
                                      tracks: widget.project.tracks.map((t) => t.id == updated.id ? updated : t).toList(),
                                    ));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Icon(
                                      track.isLocked ? Icons.lock : Icons.lock_open,
                                      size: 14,
                                      color: track.isLocked ? AppColors.accentGold : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    // Add Track Header Placeholder
                    SizedBox(
                      height: 48,
                      child: Center(
                        child: IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.accent),
                          onPressed: widget.onAddMedia,
                          tooltip: 'Add Track',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Synchronized Horizontal Timeline Canvas (Ruler + All Tracks + Playhead Line)
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    width: timelineWidth,
                    height: totalTracksHeight,
                    child: Stack(
                      clipBehavior: ui.Clip.none,
                      children: [
                        // Column of Ruler & Track Clip Surfaces
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Ruler
                            Container(
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceElevated,
                                border: Border(
                                  top: BorderSide(color: AppColors.border),
                                  bottom: BorderSide(color: AppColors.border),
                                ),
                              ),
                              child: GestureDetector(
                                onTapDown: (details) => _handleRulerTap(details.localPosition.dx, pps),
                                onHorizontalDragUpdate: (details) => _handleRulerDrag(details.localPosition.dx, pps),
                                child: CustomPaint(
                                  size: Size(timelineWidth, 32),
                                  painter: _TimelineRulerPainter(pps: pps, totalDurationMs: totalDurationMs),
                                ),
                              ),
                            ),

                            // Track Clip Lanes
                            ...widget.project.tracks.map((track) {
                              return Container(
                                height: AppConstants.timelineTrackHeight,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surface.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: track.isLocked ? AppColors.accentWarm.withOpacity(0.3) : AppColors.border.withOpacity(0.5),
                                  ),
                                ),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTapDown: (details) {
                                    final rawMs = ((details.localPosition.dx / pps) * 1000).toInt();
                                    final snappedMs = TimelineEditingService.calculateSnapTime(widget.project, rawMs);
                                    widget.onSeek(snappedMs);
                                  },
                                  child: Stack(
                                    alignment: Alignment.centerLeft,
                                    children: track.clips.map((clip) {
                                      final clipX = (clip.startTimeMs / 1000.0) * pps;
                                      return Positioned(
                                        left: clipX,
                                        child: TimelineClipWidget(
                                          clip: clip,
                                          trackType: track.type,
                                          pps: pps,
                                          isSelected: widget.selectedClipId == clip.id,
                                          onTap: () => widget.onSelectClip(clip.id, trackId: track.id),
                                          onTrimLeft: (dx) => _handleTrimLeft(clip.id, dx, pps),
                                          onTrimRight: (dx) => _handleTrimRight(clip.id, dx, pps),
                                          onDragMove: (dx) => _handleMoveClip(clip.id, track.id, dx, pps),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            }),

                            // Add Media Button Row
                            _buildAddTrackRow(),
                          ],
                        ),

                        // Playhead Vertical Line & Needle
                        Positioned(
                          left: (widget.playheadPositionMs / 1000.0) * pps,
                          top: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            child: Column(
                              children: [
                                Container(
                                  width: 14,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: AppColors.playhead,
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(4),
                                      bottomRight: Radius.circular(4),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.arrow_drop_down, size: 12, color: Colors.white),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    width: AppConstants.playheadWidth,
                                    color: AppColors.playhead,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Magnetic Snap Vertical Glowing Guideline
                        if (_activeSnapGuideMs != null)
                          Positioned(
                            left: (_activeSnapGuideMs! / 1000.0) * pps,
                            top: 0,
                            bottom: 0,
                            child: IgnorePointer(
                              child: Stack(
                                clipBehavior: ui.Clip.none,
                                children: [
                                  Container(
                                    width: 2.0,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.accent.withOpacity(0.75),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_activeSnapTarget != null)
                                    Positioned(
                                      top: 2,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceElevated,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppColors.accent, width: 0.8),
                                        ),
                                        child: Text(
                                          '🧲 ${_activeSnapTarget!}',
                                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.accent),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                        // Floating Context Bar when clip is selected
                        if (widget.selectedClipId != null)
                          Positioned(
                            top: 36,
                            left: ((widget.playheadPositionMs / 1000.0) * pps - 160).clamp(10.0, timelineWidth - 360),
                            child: TimelineContextBar(
                              onSplit: _handleSplitSelectedClip,
                              onDuplicate: _handleDuplicateSelectedClip,
                              onFreezeFrame: _handleFreezeSelectedClip,
                              onReverse: _handleReverseSelectedClip,
                              onExtractAudio: _handleExtractAudioSelectedClip,
                              onBeats: _handleBeatsSelectedClip,
                              onDelete: _handleDeleteSelectedClip,
                              onTrimHeadToPlayhead: _handleTrimHeadToPlayhead,
                              onTrimTailToPlayhead: _handleTrimTailToPlayhead,
                              onDeselect: () => widget.onSelectClip(null),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRulerTap(double localX, double pps) {
    final rawMs = ((localX / pps) * 1000).toInt();
    final snap = TimelineEditingService.calculateDetailedSnap(
      widget.project,
      rawMs,
      playheadMs: widget.playheadPositionMs,
    );
    setState(() {
      _activeSnapGuideMs = snap.isSnapped ? snap.snappedTimeMs : null;
      _activeSnapTarget = snap.snapTarget;
    });
    widget.onSeek(snap.snappedTimeMs);
  }

  void _handleRulerDrag(double localX, double pps) {
    final rawMs = ((localX / pps) * 1000).toInt();
    final snap = TimelineEditingService.calculateDetailedSnap(
      widget.project,
      rawMs,
      playheadMs: widget.playheadPositionMs,
    );
    setState(() {
      _activeSnapGuideMs = snap.isSnapped ? snap.snappedTimeMs : null;
      _activeSnapTarget = snap.snapTarget;
    });
    widget.onSeek(snap.snappedTimeMs);
  }

  void _handleTrimLeft(String clipId, double dx, double pps) {
    final deltaMs = ((dx / pps) * 1000).toInt();
    for (final track in widget.project.tracks) {
      for (final clip in track.clips) {
        if (clip.id == clipId) {
          final newStart = clip.startTimeMs + deltaMs;
          final snap = TimelineEditingService.calculateDetailedSnap(
            widget.project,
            newStart,
            ignoreClipId: clipId,
            playheadMs: widget.playheadPositionMs,
          );
          setState(() {
            _activeSnapGuideMs = snap.isSnapped ? snap.snappedTimeMs : null;
            _activeSnapTarget = snap.snapTarget;
          });
          final updated = TimelineEditingService.trimClipHead(
            widget.project,
            clipId,
            snap.snappedTimeMs,
            ripple: _isRippleEnabled,
          );
          if (updated != null) {
            widget.onProjectMutated(updated);
          }
          return;
        }
      }
    }
  }

  void _handleTrimRight(String clipId, double dx, double pps) {
    final deltaMs = ((dx / pps) * 1000).toInt();
    for (final track in widget.project.tracks) {
      for (final clip in track.clips) {
        if (clip.id == clipId) {
          final newEnd = clip.startTimeMs + clip.durationMs + deltaMs;
          final snap = TimelineEditingService.calculateDetailedSnap(
            widget.project,
            newEnd,
            ignoreClipId: clipId,
            playheadMs: widget.playheadPositionMs,
          );
          setState(() {
            _activeSnapGuideMs = snap.isSnapped ? snap.snappedTimeMs : null;
            _activeSnapTarget = snap.snapTarget;
          });
          final updated = TimelineEditingService.trimClipTail(
            widget.project,
            clipId,
            snap.snappedTimeMs,
            ripple: _isRippleEnabled,
          );
          if (updated != null) {
            widget.onProjectMutated(updated);
          }
          return;
        }
      }
    }
  }

  void _handleMoveClip(String clipId, String trackId, double dx, double pps) {
    final deltaMs = ((dx / pps) * 1000).toInt();
    for (final track in widget.project.tracks) {
      for (final clip in track.clips) {
        if (clip.id == clipId) {
          final newStart = (clip.startTimeMs + deltaMs).clamp(0, 3600000);
          final snap = TimelineEditingService.calculateDetailedSnap(
            widget.project,
            newStart,
            ignoreClipId: clipId,
            playheadMs: widget.playheadPositionMs,
          );
          setState(() {
            _activeSnapGuideMs = snap.isSnapped ? snap.snappedTimeMs : null;
            _activeSnapTarget = snap.snapTarget;
          });
          final updated = TimelineEditingService.moveClip(widget.project, clipId, trackId, snap.snappedTimeMs);
          widget.onProjectMutated(updated);
          return;
        }
      }
    }
  }

  void _handleSplitSelectedClip() {
    if (widget.selectedClipId == null) return;
    final updated = TimelineEditingService.splitClip(
      widget.project,
      widget.selectedClipId!,
      widget.playheadPositionMs,
    );
    if (updated != null) {
      widget.onProjectMutated(updated);
    }
  }

  void _handleDuplicateSelectedClip() {
    if (widget.selectedClipId == null) return;
    final updated = TimelineEditingService.duplicateClip(widget.project, widget.selectedClipId!);
    widget.onProjectMutated(updated);
  }

  void _handleFreezeSelectedClip() {
    if (widget.selectedClipId == null) return;
    final updated = TimelineEditingService.freezeFrame(
      widget.project,
      widget.selectedClipId!,
      widget.playheadPositionMs,
    );
    if (updated != null) {
      widget.onProjectMutated(updated);
    }
  }

  void _handleReverseSelectedClip() {
    if (widget.selectedClipId == null) return;
    final updated = TimelineEditingService.toggleReverseClip(
      widget.project,
      widget.selectedClipId!,
    );
    if (updated != null) {
      widget.onProjectMutated(updated);
    }
  }

  void _handleExtractAudioSelectedClip() {
    if (widget.selectedClipId == null) return;
    final updated = TimelineEditingService.extractAudio(
      widget.project,
      widget.selectedClipId!,
    );
    if (updated != null) {
      widget.onProjectMutated(updated);
    }
  }

  void _handleBeatsSelectedClip() {
    if (widget.selectedClipId == null) return;
    Clip? selectedClip;
    for (final track in widget.project.tracks) {
      for (final clip in track.clips) {
        if (clip.id == widget.selectedClipId) {
          selectedClip = clip;
          break;
        }
      }
      if (selectedClip != null) break;
    }
    if (selectedClip == null) return;

    BeatDetectionSheet.show(
      context,
      clip: selectedClip,
      currentPlayheadMs: widget.playheadPositionMs,
      onSave: (updatedClip) {
        final updatedProject = widget.project.updateClip(updatedClip);
        widget.onProjectMutated(updatedProject);
      },
    );
  }

  void _handleDeleteSelectedClip() {
    if (widget.selectedClipId == null) return;
    final updated = TimelineEditingService.deleteClip(
      widget.project,
      widget.selectedClipId!,
      ripple: _isRippleEnabled,
    );
    widget.onSelectClip(null);
    widget.onProjectMutated(updated);
  }

  void _handleTrimHeadToPlayhead() {
    if (widget.selectedClipId == null) return;
    final updated = TimelineEditingService.trimClipHead(
      widget.project,
      widget.selectedClipId!,
      widget.playheadPositionMs,
      ripple: _isRippleEnabled,
    );
    if (updated != null) {
      widget.onProjectMutated(updated);
    }
  }

  void _handleTrimTailToPlayhead() {
    if (widget.selectedClipId == null) return;
    final updated = TimelineEditingService.trimClipTail(
      widget.project,
      widget.selectedClipId!,
      widget.playheadPositionMs,
      ripple: _isRippleEnabled,
    );
    if (updated != null) {
      widget.onProjectMutated(updated);
    }
  }

  Widget _buildAddTrackRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: OutlinedButton.icon(
        onPressed: widget.onAddMedia,
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Add Media Clip to Timeline', style: TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          foregroundColor: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _TimelineRulerPainter extends CustomPainter {
  final double pps;
  final int totalDurationMs;

  _TimelineRulerPainter({required this.pps, required this.totalDurationMs});

  @override
  void paint(Canvas canvas, Size size) {
    final minorPaint = Paint()
      ..color = AppColors.textMuted.withOpacity(0.3)
      ..strokeWidth = 1;

    final majorPaint = Paint()
      ..color = AppColors.textSecondary
      ..strokeWidth = 1.2;

    final textStyle = AppTypography.timecode.copyWith(
      fontSize: 9,
      color: AppColors.textSecondary,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final totalSeconds = (totalDurationMs / 1000.0).ceil() + 15;

    for (int s = 0; s <= totalSeconds; s++) {
      final x = s * pps;

      // Major second tick
      canvas.drawLine(Offset(x, 16), Offset(x, 32), majorPaint);

      textPainter.text = TextSpan(text: '${s}s', style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + 3, 2));

      // Minor sub-second ticks (4 divisions per second)
      for (int sub = 1; sub <= 3; sub++) {
        final subX = x + (sub * (pps / 4));
        canvas.drawLine(Offset(subX, 22), Offset(subX, 32), minorPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineRulerPainter oldDelegate) {
    return oldDelegate.pps != pps || oldDelegate.totalDurationMs != totalDurationMs;
  }
}
