import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../../../models/project.dart';
import '../../../overlays/models/text_overlay_config.dart';
import '../../models/caption_line.dart';
import '../../services/auto_caption_service.dart';

class CaptionManagerSheet extends StatefulWidget {
  final Project project;
  final Function(Project updatedProject) onSave;
  final Function(int timestampMs)? onSeek;

  const CaptionManagerSheet({
    super.key,
    required this.project,
    required this.onSave,
    this.onSeek,
  });

  static Future<void> show(
    BuildContext context, {
    required Project project,
    required Function(Project) onSave,
    Function(int)? onSeek,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CaptionManagerSheet(
        project: project,
        onSave: onSave,
        onSeek: onSeek,
      ),
    );
  }

  @override
  State<CaptionManagerSheet> createState() => _CaptionManagerSheetState();
}

class _CaptionManagerSheetState extends State<CaptionManagerSheet> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _previewAnimController;
  final TextEditingController _selfDescriptionController = TextEditingController();

  List<CaptionLine> _captions = [];
  CaptionPreset _activePreset = CaptionPreset.tiktokViral;
  late TextOverlayConfig _currentStyle;
  int? _selectedCaptionIndex;
  bool _applyToAll = true;

  static const List<String> availableFonts = [
    'Anton',
    'Inter',
    'Bebas Neue',
    'Montserrat',
    'Poppins',
    'Roboto',
    'Oswald',
    'JetBrains Mono',
    'Permanent Marker',
    'Caveat',
    'Pacifico',
  ];

  static const List<int> textColors = [
    0xFFFFFFFF, // Pure White
    0xFFFFE600, // Vibrant Yellow
    0xFF00E5FF, // Cyan
    0xFF00FF66, // Neon Green
    0xFFFF2A85, // Hot Pink
    0xFFFF6B00, // Blaze Orange
    0xFFFFB703, // Amber Gold
    0xFFFF3344, // Bright Red
    0xFFA855F7, // Purple
    0xFF111827, // Charcoal Black
  ];

  static const List<int?> bgColors = [
    null,       // Transparent
    0xCC000000, // Translucent Black
    0xFF000000, // Solid Black
    0xDD0B132B, // Deep Navy
    0xDD1E293B, // Slate Grey
    0xDD7F1D1D, // Crimson Red
    0xDDEE8800, // Amber Brown
    0xDD0F766E, // Dark Teal
    0xDD581C87, // Dark Violet
  ];

  static const List<int> strokeColors = [
    0xFF000000, // Pure Black
    0xFFFFFFFF, // Pure White
    0xFFFFE600, // Vibrant Yellow
    0xFF00B0FF, // Cyan
    0xFFFF3344, // Red
    0xFFFFD700, // Gold
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _previewAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _captions = AutoCaptionService.extractCaptionsFromProject(widget.project);
    if (_captions.isNotEmpty) {
      _currentStyle = _captions.first.style;
    } else {
      _currentStyle = _activePreset.createStyle('SAMPLE CAPTION');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _previewAnimController.dispose();
    _selfDescriptionController.dispose();
    super.dispose();
  }

  TextStyle _resolveStyle(TextOverlayConfig config, {double? overrideSize}) {
    final name = config.fontFamily.trim().toLowerCase().replaceAll(' ', '');
    final weight = config.isBold ? FontWeight.w800 : FontWeight.w500;
    final fontStyle = config.isItalic ? FontStyle.italic : FontStyle.normal;
    final decoration = config.isUnderline ? TextDecoration.underline : TextDecoration.none;
    final spacing = config.letterSpacing;
    final color = Color(config.textColor);
    final size = overrideSize ?? config.fontSize;

    try {
      switch (name) {
        case 'anton':
          return GoogleFonts.anton(fontSize: size, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
        case 'bebasneue':
          return GoogleFonts.bebasNeue(fontSize: size, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
        case 'montserrat':
          return GoogleFonts.montserrat(fontSize: size, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
        case 'poppins':
          return GoogleFonts.poppins(fontSize: size, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
        case 'oswald':
          return GoogleFonts.oswald(fontSize: size, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
        case 'jetbrainsmono':
          return GoogleFonts.jetbrainsMono(fontSize: size, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
        case 'caveat':
          return GoogleFonts.caveat(fontSize: size, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
        case 'pacifico':
          return GoogleFonts.pacifico(fontSize: size, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
        case 'permanentmarker':
          return GoogleFonts.permanentMarker(fontSize: size, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
        case 'roboto':
          return GoogleFonts.roboto(fontSize: size, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
        case 'inter':
        default:
          return GoogleFonts.inter(fontSize: size, fontWeight: weight, fontStyle: fontStyle, decoration: decoration, letterSpacing: spacing, color: color);
      }
    } catch (_) {
      return TextStyle(
        fontFamily: config.fontFamily,
        fontSize: size,
        fontWeight: weight,
        fontStyle: fontStyle,
        decoration: decoration,
        letterSpacing: spacing,
        color: color,
      );
    }
  }

  void _applyAndSave() {
    final updatedProject = AutoCaptionService.syncCaptionsToProject(widget.project, _captions);
    widget.onSave(updatedProject);
  }

  void _updateCurrentStyle(TextOverlayConfig Function(TextOverlayConfig) updater) {
    setState(() {
      _currentStyle = updater(_currentStyle);

      if (_applyToAll || _selectedCaptionIndex == null) {
        _captions = _captions.map((cap) {
          return cap.copyWith(
            style: _currentStyle.copyWith(text: cap.text),
          );
        }).toList();
      } else if (_selectedCaptionIndex != null && _selectedCaptionIndex! < _captions.length) {
        final idx = _selectedCaptionIndex!;
        _captions[idx] = _captions[idx].copyWith(
          style: _currentStyle.copyWith(text: _captions[idx].text),
        );
      }
    });
    _applyAndSave();
  }

  void _changePreset(CaptionPreset preset) {
    setState(() {
      _activePreset = preset;
      final template = preset.createStyle('SAMPLE CAPTION');
      _currentStyle = template;

      _captions = _captions.map((cap) {
        return cap.copyWith(style: preset.createStyle(cap.text));
      }).toList();
    });
    _applyAndSave();
  }

  void _generateAuto() {
    setState(() {
      _captions = AutoCaptionService.generateAutoCaptions(
        widget.project,
        preset: _activePreset,
      );
      if (_captions.isNotEmpty) {
        _captions = _captions.map((c) => c.copyWith(style: _currentStyle.copyWith(text: c.text))).toList();
      }
    });
    _applyAndSave();
    if (_captions.isNotEmpty && widget.onSeek != null) {
      widget.onSeek!(_captions.first.startTimeMs);
    }
  }

  void _generateFromDescription() {
    final text = _selfDescriptionController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _captions = AutoCaptionService.generateFromSelfDescription(
        text,
        widget.project.durationMs,
        preset: _activePreset,
      );
      if (_captions.isNotEmpty) {
        _captions = _captions.map((c) => c.copyWith(style: _currentStyle.copyWith(text: c.text))).toList();
      }
    });
    _applyAndSave();
    if (_captions.isNotEmpty && widget.onSeek != null) {
      widget.onSeek!(_captions.first.startTimeMs);
    }
  }

  void _addNewCaptionLine() {
    final lastEnd = _captions.isNotEmpty ? _captions.last.endTimeMs : 0;
    const defaultText = 'New Caption Line';
    final newCap = CaptionLine(
      id: const Uuid().v4(),
      text: defaultText,
      startTimeMs: lastEnd,
      durationMs: 2500,
      style: _currentStyle.copyWith(text: defaultText),
    );
    setState(() {
      _captions.add(newCap);
      _selectedCaptionIndex = _captions.length - 1;
    });
    _applyAndSave();
    widget.onSeek?.call(newCap.startTimeMs);
  }

  void _deleteCaptionLine(int index) {
    setState(() {
      _captions.removeAt(index);
      if (_selectedCaptionIndex == index) {
        _selectedCaptionIndex = null;
      } else if (_selectedCaptionIndex != null && _selectedCaptionIndex! > index) {
        _selectedCaptionIndex = _selectedCaptionIndex! - 1;
      }
    });
    _applyAndSave();
  }

  void _editCaptionText(int index, String newText) {
    setState(() {
      _captions[index] = _captions[index].copyWith(
        text: newText,
        style: _captions[index].style.copyWith(text: newText),
      );
    });
    _applyAndSave();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 6),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.closed_caption, color: AppColors.primaryLight, size: 24),
                        const SizedBox(width: 8),
                        Text('Caption Studio', style: AppTypography.titleLarge),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: AppColors.accent, size: 24),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Save & Close',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Live Animated Caption Preview Canvas
          _buildLivePreviewCard(),

          // Navigation Tabs: Presets | Font & Size | Colors & Box | Animation | Auto AI
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMuted,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [
                Tab(icon: Icon(Icons.auto_awesome, size: 15), text: 'AI Generate'),
                Tab(icon: Icon(Icons.style, size: 15), text: 'Presets'),
                Tab(icon: Icon(Icons.font_download, size: 15), text: 'Font & Size'),
                Tab(icon: Icon(Icons.color_lens, size: 15), text: 'Colors & Stroke'),
                Tab(icon: Icon(Icons.animation, size: 15), text: 'Animation & Pos'),
              ],
            ),
          ),

          // Tab Controls
          SizedBox(
            height: 195,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAutoGenerateTab(),
                _buildPresetsTab(),
                _buildFontAndSizeTab(),
                _buildColorsAndStrokeTab(),
                _buildAnimationAndPositionTab(),
              ],
            ),
          ),

          const Divider(color: AppColors.border, height: 12),

          // Caption Lines List Header & Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'TIMELINE CAPTIONS (${_captions.length})',
                      style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => setState(() => _applyToAll = !_applyToAll),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _applyToAll ? AppColors.accent.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _applyToAll ? AppColors.accent : AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _applyToAll ? Icons.check_box : Icons.check_box_outline_blank,
                              size: 13,
                              color: _applyToAll ? AppColors.accent : AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Apply to All',
                              style: TextStyle(
                                fontSize: 10,
                                color: _applyToAll ? AppColors.accent : AppColors.textMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_captions.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _captions.clear();
                            _selectedCaptionIndex = null;
                          });
                          _applyAndSave();
                        },
                        icon: const Icon(Icons.delete_sweep, size: 15, color: Colors.redAccent),
                        label: const Text('Clear', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                      ),
                    TextButton.icon(
                      onPressed: _addNewCaptionLine,
                      icon: const Icon(Icons.add, size: 15, color: AppColors.accent),
                      label: const Text('Add Line', style: TextStyle(color: AppColors.accent, fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List of Caption Lines
          Expanded(
            child: _captions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.subtitles_off, size: 36, color: AppColors.textMuted),
                        const SizedBox(height: 6),
                        Text('No captions on timeline', style: AppTypography.bodyMedium),
                        const SizedBox(height: 2),
                        Text('Use AI Generate or tap "Add Line" above', style: AppTypography.labelSmall),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: _captions.length,
                    itemBuilder: (context, index) {
                      final cap = _captions[index];
                      final isSelected = _selectedCaptionIndex == index;
                      final timeStr = '${TimecodeFormatter.formatMilliseconds(cap.startTimeMs)} - ${TimecodeFormatter.formatMilliseconds(cap.endTimeMs)}';

                      return Card(
                        color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceElevated,
                        margin: const EdgeInsets.only(bottom: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: isSelected ? AppColors.accent : AppColors.border),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCaptionIndex = index;
                              _currentStyle = cap.style;
                            });
                            widget.onSeek?.call(cap.startTimeMs);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.play_circle_outline, color: AppColors.accent, size: 20),
                                  onPressed: () => widget.onSeek?.call(cap.startTimeMs),
                                  tooltip: 'Seek to caption',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        timeStr,
                                        style: AppTypography.timecode.copyWith(fontSize: 10, color: AppColors.textMuted),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        cap.style.isUppercase ? cap.text.toUpperCase() : cap.text,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(cap.style.textColor),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 16, color: AppColors.textSecondary),
                                  onPressed: () async {
                                    final controller = TextEditingController(text: cap.text);
                                    final edited = await showDialog<String>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: AppColors.surfaceElevated,
                                        title: const Text('Edit Caption Text', style: TextStyle(fontSize: 16)),
                                        content: TextField(
                                          controller: controller,
                                          autofocus: true,
                                          decoration: const InputDecoration(border: OutlineInputBorder()),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, controller.text),
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (edited != null && edited.trim().isNotEmpty) {
                                      _editCaptionText(index, edited.trim());
                                    }
                                  },
                                  tooltip: 'Edit text',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                                  onPressed: () => _deleteCaptionLine(index),
                                  tooltip: 'Delete line',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: 70,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle grid guide
          Positioned(
            left: 10,
            top: 6,
            child: Text(
              'PREVIEW: ${_currentStyle.fontFamily} • ${_currentStyle.fontSize.round()}pt • ${_currentStyle.animationType.label}',
              style: const TextStyle(fontSize: 9, color: AppColors.textMuted, letterSpacing: 0.5),
            ),
          ),

          // Animated Caption Sample
          AnimatedBuilder(
            animation: _previewAnimController,
            builder: (context, child) {
              final tVal = _previewAnimController.value;
              final elapsedMs = (tVal * 2500).round();

              double animScale = 1.0;
              double animOpacity = 1.0;
              double animOffsetY = 0.0;

              final fullText = _selectedCaptionIndex != null && _selectedCaptionIndex! < _captions.length
                  ? _captions[_selectedCaptionIndex!].text
                  : 'DISCOVER NEXT-LEVEL CAPTIONS ✨';

              String sampleText = _currentStyle.isUppercase ? fullText.toUpperCase() : fullText;

              switch (_currentStyle.animationType) {
                case TextAnimationType.none:
                  break;
                case TextAnimationType.fadeIn:
                  if (elapsedMs < 400) {
                    animOpacity = (elapsedMs / 400.0).clamp(0.0, 1.0);
                  } else if (elapsedMs > 2100) {
                    animOpacity = ((2500 - elapsedMs) / 400.0).clamp(0.0, 1.0);
                  }
                  break;
                case TextAnimationType.popScale:
                  if (elapsedMs < 300) {
                    final t = elapsedMs / 300.0;
                    animScale = t < 0.6 ? (t / 0.6) * 1.25 : 1.25 - ((t - 0.6) / 0.4) * 0.25;
                  }
                  break;
                case TextAnimationType.bounce:
                  if (elapsedMs < 400) {
                    final t = elapsedMs / 400.0;
                    animScale = 1.0 + 0.35 * math.sin(t * 3.14159);
                  }
                  break;
                case TextAnimationType.slideUp:
                  if (elapsedMs < 350) {
                    final t = elapsedMs / 350.0;
                    animOffsetY = (1.0 - t) * 20.0;
                    animOpacity = t;
                  }
                  break;
                case TextAnimationType.zoomIn:
                  if (elapsedMs < 400) {
                    final t = elapsedMs / 400.0;
                    animScale = 0.5 + (0.5 * t);
                    animOpacity = t;
                  }
                  break;
                case TextAnimationType.shimmer:
                  final tSec = elapsedMs / 1000.0;
                  animScale = 1.0 + 0.04 * math.sin(tSec * 6.28);
                  animOpacity = 0.88 + 0.12 * math.cos(tSec * 6.28);
                  break;
                case TextAnimationType.karaoke:
                  final phase = ((elapsedMs % 500) / 500.0);
                  animScale = 1.0 + 0.08 * math.sin(phase * 3.14159);
                  break;
                case TextAnimationType.typewriter:
                  final t = (elapsedMs / 1500.0).clamp(0.0, 1.0);
                  final count = (t * sampleText.length).ceil().clamp(0, sampleText.length);
                  sampleText = sampleText.substring(0, count);
                  break;
              }

              final baseStyle = _resolveStyle(_currentStyle, overrideSize: (_currentStyle.fontSize * 0.75).clamp(12.0, 26.0));

              return Transform.translate(
                offset: Offset(0, animOffsetY),
                child: Transform.scale(
                  scale: animScale,
                  child: Opacity(
                    opacity: animOpacity.clamp(0.0, 1.0),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _currentStyle.boxPadding * 0.8,
                        vertical: _currentStyle.boxPadding * 0.35,
                      ),
                      decoration: BoxDecoration(
                        color: _currentStyle.backgroundColor != null
                            ? Color(_currentStyle.backgroundColor!)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(_currentStyle.boxCornerRadius),
                      ),
                      child: _currentStyle.strokeWidth > 0 && _currentStyle.strokeColor != null
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  sampleText,
                                  style: baseStyle.copyWith(
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = _currentStyle.strokeWidth * 1.5
                                      ..color = Color(_currentStyle.strokeColor!),
                                  ),
                                ),
                                Text(
                                  sampleText,
                                  style: baseStyle.copyWith(color: Color(_currentStyle.textColor)),
                                ),
                              ],
                            )
                          : Text(
                              sampleText,
                              style: baseStyle.copyWith(
                                color: Color(_currentStyle.textColor),
                                shadows: [
                                  if (_currentStyle.shadowColor != null)
                                    Shadow(color: Color(_currentStyle.shadowColor!), blurRadius: 4, offset: const Offset(0, 2))
                                  else
                                    const Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 2)),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 1. Auto-Generate AI Tab
  Widget _buildAutoGenerateTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generateAuto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('AI Auto-Speech Sync', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _selfDescriptionController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Or paste script / dialogue to auto-slice into timed captions...',
                      hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.surfaceElevated,
                      contentPadding: const EdgeInsets.all(10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  height: double.infinity,
                  child: ElevatedButton(
                    onPressed: _generateFromDescription,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceElevated,
                      foregroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.all(8),
                    ),
                    child: const Text('Convert\nScript', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Presets Tab
  Widget _buildPresetsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CaptionPreset.values.map((preset) {
            final isSelected = _activePreset == preset;
            return ChoiceChip(
              label: Text(preset.label, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              selectedColor: AppColors.accent,
              backgroundColor: AppColors.surfaceElevated,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) _changePreset(preset);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // 3. Font & Size Tab
  Widget _buildFontAndSizeTab() {
    final sizes = [18.0, 24.0, 30.0, 38.0, 48.0];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      children: [
        // Font Family Selector
        const Text('FONT FAMILY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: availableFonts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final font = availableFonts[index];
              final isSelected = _currentStyle.fontFamily == font;

              return ChoiceChip(
                label: Text(
                  font,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.accent,
                backgroundColor: AppColors.surfaceElevated,
                labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                onSelected: (_) => _updateCurrentStyle((s) => s.copyWith(fontFamily: font)),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Font Size & Quick Size Chips
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FONT SIZE: ${_currentStyle.fontSize.round()}pt',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
            ),
            Row(
              children: sizes.map((sz) {
                final isSelected = (_currentStyle.fontSize - sz).abs() < 2;
                final label = sz <= 18 ? 'S' : (sz <= 24 ? 'M' : (sz <= 30 ? 'L' : (sz <= 38 ? 'XL' : 'XXL')));
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: InkWell(
                    onTap: () => _updateCurrentStyle((s) => s.copyWith(fontSize: sz)),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accent : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        Slider(
          value: _currentStyle.fontSize.clamp(14.0, 64.0),
          min: 14.0,
          max: 64.0,
          activeColor: AppColors.accent,
          inactiveColor: AppColors.border,
          onChanged: (val) => _updateCurrentStyle((s) => s.copyWith(fontSize: val)),
        ),

        // Style Toggles: Bold | Italic | ALL CAPS | Underline
        Row(
          children: [
            _buildStyleToggle(
              icon: Icons.format_bold,
              label: 'Bold',
              isActive: _currentStyle.isBold,
              onTap: () => _updateCurrentStyle((s) => s.copyWith(isBold: !s.isBold)),
            ),
            const SizedBox(width: 8),
            _buildStyleToggle(
              icon: Icons.format_italic,
              label: 'Italic',
              isActive: _currentStyle.isItalic,
              onTap: () => _updateCurrentStyle((s) => s.copyWith(isItalic: !s.isItalic)),
            ),
            const SizedBox(width: 8),
            _buildStyleToggle(
              icon: Icons.text_fields,
              label: 'ALL CAPS',
              isActive: _currentStyle.isUppercase,
              onTap: () => _updateCurrentStyle((s) => s.copyWith(isUppercase: !s.isUppercase)),
            ),
            const SizedBox(width: 8),
            _buildStyleToggle(
              icon: Icons.format_underlined,
              label: 'Underline',
              isActive: _currentStyle.isUnderline,
              onTap: () => _updateCurrentStyle((s) => s.copyWith(isUnderline: !s.isUnderline)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStyleToggle({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent.withOpacity(0.25) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? AppColors.accent : AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isActive ? AppColors.accent : AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? AppColors.accent : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Colors & Stroke Tab
  Widget _buildColorsAndStrokeTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      children: [
        // Text Color
        const Text('TEXT COLOR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: textColors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final color = textColors[index];
              final isSelected = _currentStyle.textColor == color;
              return GestureDetector(
                onTap: () => _updateCurrentStyle((s) => s.copyWith(textColor: color)),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: isSelected ? 2.5 : 1.0,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: (color == 0xFFFFFFFF || color == 0xFFFFE600) ? Colors.black : Colors.white,
                        )
                      : null,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Background Box Style
        const Text('BACKGROUND BOX', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: bgColors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final bg = bgColors[index];
              final isSelected = _currentStyle.backgroundColor == bg;

              return GestureDetector(
                onTap: () => _updateCurrentStyle((s) => s.copyWith(backgroundColor: bg)),
                child: Container(
                  width: 44,
                  height: 32,
                  decoration: BoxDecoration(
                    color: bg != null ? Color(bg) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Center(
                    child: bg == null
                        ? Text('None', style: TextStyle(fontSize: 10, color: isSelected ? AppColors.accent : AppColors.textMuted))
                        : (isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Stroke Outline Width & Color
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'OUTLINE STROKE: ${_currentStyle.strokeWidth.toStringAsFixed(1)}px',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
            ),
            Row(
              children: strokeColors.map((sc) {
                final isSelected = _currentStyle.strokeColor == sc && _currentStyle.strokeWidth > 0;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: () => _updateCurrentStyle((s) => s.copyWith(
                          strokeColor: sc,
                          strokeWidth: s.strokeWidth == 0.0 ? 2.5 : s.strokeWidth,
                        )),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Color(sc),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.accent : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        Slider(
          value: _currentStyle.strokeWidth.clamp(0.0, 8.0),
          min: 0.0,
          max: 8.0,
          activeColor: AppColors.accent,
          inactiveColor: AppColors.border,
          onChanged: (val) => _updateCurrentStyle((s) => s.copyWith(
                strokeWidth: val,
                strokeColor: s.strokeColor ?? 0xFF000000,
              )),
        ),
      ],
    );
  }

  // 5. Animation & Position Tab
  Widget _buildAnimationAndPositionTab() {
    const anims = [
      TextAnimationType.none,
      TextAnimationType.popScale,
      TextAnimationType.bounce,
      TextAnimationType.fadeIn,
      TextAnimationType.slideUp,
      TextAnimationType.zoomIn,
      TextAnimationType.shimmer,
      TextAnimationType.karaoke,
      TextAnimationType.typewriter,
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      children: [
        // Animation Cards
        const Text('CAPTION ANIMATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: anims.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final a = anims[index];
              final isSelected = _currentStyle.animationType == a;
              return ChoiceChip(
                label: Text(a.label, style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                selectedColor: AppColors.accent,
                backgroundColor: AppColors.surfaceElevated,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => _updateCurrentStyle((s) => s.copyWith(animationType: a)),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Position Y Presets: Bottom (0.84) | Center (0.50) | Top (0.16)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('POSITION ON SCREEN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
            Row(
              children: [
                _buildPositionPresetBtn('Top', 0.16),
                const SizedBox(width: 4),
                _buildPositionPresetBtn('Center', 0.50),
                const SizedBox(width: 4),
                _buildPositionPresetBtn('Bottom', 0.84),
              ],
            ),
          ],
        ),
        Slider(
          value: _currentStyle.positionY.clamp(0.05, 0.95),
          min: 0.05,
          max: 0.95,
          activeColor: AppColors.accent,
          inactiveColor: AppColors.border,
          onChanged: (val) => _updateCurrentStyle((s) => s.copyWith(positionY: val)),
        ),
      ],
    );
  }

  Widget _buildPositionPresetBtn(String label, double y) {
    final isSelected = (_currentStyle.positionY - y).abs() < 0.05;
    return InkWell(
      onTap: () => _updateCurrentStyle((s) => s.copyWith(positionY: y)),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
