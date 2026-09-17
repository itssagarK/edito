import 'dart:io';
import 'package:flutter/material.dart' hide Clip;
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/image_overlay_config.dart';
import '../../services/pip_compiler_service.dart';

class ImageOverlaySheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const ImageOverlaySheet({
    super.key,
    required this.clip,
    required this.onSave,
    this.isDocked = false,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required Clip clip,
    required Function(Clip) onSave,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.15),
      builder: (context) => ImageOverlaySheet(clip: clip, onSave: onSave, onDone: onDone),
    );
  }

  @override
  State<ImageOverlaySheet> createState() => _ImageOverlaySheetState();
}

class _ImageOverlaySheetState extends State<ImageOverlaySheet> {
  late ImageOverlayConfig _config;
  late TextEditingController _labelController;

  static const List<int> _borderColorPalette = [
    0xFFFFFFFF, // Pure White
    0xFFFFD700, // Golden Yellow
    0xFF00E5FF, // Neon Cyan
    0xFFFF1493, // Hot Pink
    0xFF00E676, // Spring Green
    0xFF9C27B0, // Vivid Purple
    0xFF000000, // Deep Black
  ];

  @override
  void initState() {
    super.initState();
    _config = widget.clip.imageOverlay;
    if (!_config.isEnabled) {
      _config = _config.copyWith(isEnabled: true);
    }
    _labelController = TextEditingController(text: _config.assetLabel);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _applyChange() {
    final updated = widget.clip.copyWith(imageOverlay: _config);
    widget.onSave(updated);
  }

  void _selectPreset(PipPreset preset) {
    setState(() {
      _config = ImageOverlayConfig.getPresetConfig(
        preset,
        mediaPath: _config.mediaPath,
        assetLabel: _config.assetLabel.isNotEmpty ? _config.assetLabel : preset.label,
      );
      _labelController.text = _config.assetLabel;
    });
    _applyChange();
  }

  Future<void> _pickMedia({required bool isVideo}) async {
    try {
      final picker = ImagePicker();
      final XFile? file = isVideo
          ? await picker.pickVideo(source: ImageSource.gallery)
          : await picker.pickImage(source: ImageSource.gallery);

      if (file != null) {
        final filename = file.name;
        setState(() {
          _config = _config.copyWith(
            isEnabled: true,
            mediaPath: file.path,
            assetLabel: _config.assetLabel.isEmpty ? filename : _config.assetLabel,
          );
          if (_config.assetLabel.isEmpty) {
            _labelController.text = filename;
          }
        });
        _applyChange();
      }
    } catch (_) {}
  }

  void _showMediaSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Pick Photo from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickMedia(isVideo: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library, color: AppColors.accent),
                title: const Text('Pick Video from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickMedia(isVideo: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final badgeLabel = PipCompilerService.getPipBadge(_config);

    return Container(
      height: widget.isDocked ? null : MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: widget.isDocked ? Colors.transparent : AppColors.surface,
        borderRadius: widget.isDocked ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(24)),
        border: widget.isDocked ? null : const Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          if (!widget.isDocked)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 6),
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
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.picture_in_picture_alt_outlined, color: AppColors.accent, size: 22),
                          const SizedBox(width: 8),
                          Text('Picture-in-Picture (PiP) Studio', style: AppTypography.titleLarge),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMuted, size: 22),
                        onPressed: widget.onDone ?? () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Master Enable Toggle Card with Live Badge
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _config.isEnabled ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _config.shape == PipShape.circle ? Icons.videocam : Icons.picture_in_picture,
                      color: _config.isEnabled ? AppColors.accent : AppColors.textMuted,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badgeLabel.isNotEmpty ? badgeLabel : 'PiP Window Layer',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          _config.isEnabled ? 'Composited over primary video' : 'Disabled',
                          style: TextStyle(
                            color: _config.isEnabled ? AppColors.accent : AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: _config.isEnabled,
                  activeColor: AppColors.accent,
                  onChanged: (val) {
                    setState(() => _config = _config.copyWith(isEnabled: val));
                    _applyChange();
                  },
                ),
              ],
            ),
          ),

          // Scrollable Settings Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                // 1. PiP Presets Carousel
                const Text(
                  'PiP LAYOUT PRESETS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: PipPreset.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final preset = PipPreset.values[idx];
                      final isSelected = _config.preset == preset;
                      return ChoiceChip(
                        label: Text(
                          preset.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.black : Colors.white70,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.accent,
                        backgroundColor: AppColors.surfaceElevated,
                        onSelected: (_) => _selectPreset(preset),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Window Shape Selector
                const Text(
                  'WINDOW SHAPE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: PipShape.values.map((shape) {
                    final isSelected = _config.shape == shape;
                    return ChoiceChip(
                      label: Text(
                        shape.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.black : Colors.white70,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primaryLight,
                      backgroundColor: AppColors.surfaceElevated,
                      onSelected: (_) {
                        setState(() {
                          _config = _config.copyWith(
                            shape: shape,
                            cornerRadius: shape == PipShape.circle
                                ? 999.0
                                : shape == PipShape.rectangle
                                    ? 0.0
                                    : 14.0,
                          );
                        });
                        _applyChange();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // 3. Media Source & Label
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.add_photo_alternate_outlined, size: 18, color: AppColors.primary),
                        label: Text(
                          _config.mediaPath.isNotEmpty
                              ? 'Change Media (${_config.mediaPath.split(Platform.pathSeparator).last})'
                              : 'Select PiP Media File',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _showMediaSourceDialog,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _labelController,
                  decoration: InputDecoration(
                    labelText: 'PiP Overlay Name / Stream Badge',
                    labelStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    hintText: 'e.g. Webcam, Screen Share, Guest Host',
                    hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.label_outline, size: 18, color: AppColors.accent),
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.surfaceElevated,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                  onChanged: (text) {
                    setState(() => _config = _config.copyWith(assetLabel: text));
                    _applyChange();
                  },
                ),
                const SizedBox(height: 14),

                // 4. Quick Alignment Presets
                const Text(
                  'QUICK ANCHOR POSITION',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildAnchorBtn('Top-Left', 0.20, 0.20),
                    const SizedBox(width: 6),
                    _buildAnchorBtn('Top-Right', 0.80, 0.20),
                    const SizedBox(width: 6),
                    _buildAnchorBtn('Center', 0.50, 0.50),
                    const SizedBox(width: 6),
                    _buildAnchorBtn('Bot-Left', 0.20, 0.80),
                    const SizedBox(width: 6),
                    _buildAnchorBtn('Bot-Right', 0.80, 0.80),
                  ],
                ),
                const SizedBox(height: 14),

                // 5. Geometry Controls
                _buildSlider(
                  label: 'Window Scale',
                  valueDisplay: '${(_config.scale * 100).round()}%',
                  value: _config.scale,
                  min: 0.15,
                  max: 1.20,
                  activeColor: AppColors.accent,
                  onChanged: (v) {
                    setState(() => _config = _config.copyWith(scale: v));
                    _applyChange();
                  },
                ),
                _buildSlider(
                  label: 'Horizontal Position (X)',
                  valueDisplay: '${(_config.positionX * 100).round()}%',
                  value: _config.positionX,
                  min: 0.0,
                  max: 1.0,
                  activeColor: AppColors.primary,
                  onChanged: (v) {
                    setState(() => _config = _config.copyWith(positionX: v));
                    _applyChange();
                  },
                ),
                _buildSlider(
                  label: 'Vertical Position (Y)',
                  valueDisplay: '${(_config.positionY * 100).round()}%',
                  value: _config.positionY,
                  min: 0.0,
                  max: 1.0,
                  activeColor: AppColors.primary,
                  onChanged: (v) {
                    setState(() => _config = _config.copyWith(positionY: v));
                    _applyChange();
                  },
                ),
                _buildSlider(
                  label: 'Rotation',
                  valueDisplay: '${_config.rotation.round()}°',
                  value: _config.rotation,
                  min: 0.0,
                  max: 360.0,
                  activeColor: Colors.orangeAccent,
                  onChanged: (v) {
                    setState(() => _config = _config.copyWith(rotation: v));
                    _applyChange();
                  },
                ),
                _buildSlider(
                  label: 'Opacity',
                  valueDisplay: '${(_config.opacity * 100).round()}%',
                  value: _config.opacity,
                  min: 0.0,
                  max: 1.0,
                  activeColor: Colors.white70,
                  onChanged: (v) {
                    setState(() => _config = _config.copyWith(opacity: v));
                    _applyChange();
                  },
                ),

                // 6. Border & Frame Styling
                if (_config.shape != PipShape.circle)
                  _buildSlider(
                    label: 'Corner Radius',
                    valueDisplay: '${_config.cornerRadius.round()}px',
                    value: _config.cornerRadius,
                    min: 0.0,
                    max: 48.0,
                    activeColor: AppColors.primaryLight,
                    onChanged: (v) {
                      setState(() => _config = _config.copyWith(cornerRadius: v));
                      _applyChange();
                    },
                  ),

                _buildSlider(
                  label: 'Border Width',
                  valueDisplay: '${_config.borderWidth.toStringAsFixed(1)}px',
                  value: _config.borderWidth,
                  min: 0.0,
                  max: 12.0,
                  activeColor: AppColors.accent,
                  onChanged: (v) {
                    setState(() => _config = _config.copyWith(borderWidth: v));
                    _applyChange();
                  },
                ),

                const SizedBox(height: 6),
                const Text(
                  'BORDER STROKE COLOR',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.8),
                ),
                const SizedBox(height: 8),
                Row(
                  children: _borderColorPalette.map((colVal) {
                    final isSelected = _config.borderColor == colVal;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _config = _config.copyWith(borderColor: colVal));
                        _applyChange();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(colVal),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.accent : Colors.white30,
                            width: isSelected ? 2.5 : 1.0,
                          ),
                        ),
                        child: isSelected
                            ? Icon(Icons.check, size: 16, color: colVal == 0xFFFFFFFF ? Colors.black : Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // 7. Drop Shadow Controls
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cinematic Drop Shadow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Renders skia ambient shadow behind the PiP frame', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  value: _config.hasShadow,
                  activeColor: AppColors.accent,
                  onChanged: (v) {
                    setState(() => _config = _config.copyWith(hasShadow: v));
                    _applyChange();
                  },
                ),
                if (_config.hasShadow)
                  _buildSlider(
                    label: 'Shadow Blur Radius',
                    valueDisplay: '${_config.shadowBlur.round()}px',
                    value: _config.shadowBlur,
                    min: 0.0,
                    max: 30.0,
                    activeColor: Colors.deepPurpleAccent,
                    onChanged: (v) {
                      setState(() => _config = _config.copyWith(shadowBlur: v));
                      _applyChange();
                    },
                  ),

                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.restart_alt, size: 16, color: AppColors.textMuted),
                    label: const Text('Reset PiP Defaults', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    onPressed: () {
                      setState(() {
                        _config = const ImageOverlayConfig(isEnabled: true);
                        _labelController.text = '';
                      });
                      _applyChange();
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnchorBtn(String label, double x, double y) {
    final isCurrent = (_config.positionX - x).abs() < 0.05 && (_config.positionY - y).abs() < 0.05;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _config = _config.copyWith(positionX: x, positionY: y));
          _applyChange();
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isCurrent ? AppColors.accent.withOpacity(0.2) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isCurrent ? AppColors.accent : AppColors.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isCurrent ? AppColors.accent : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required String valueDisplay,
    required double value,
    required double min,
    required double max,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            Text(valueDisplay, style: TextStyle(fontSize: 12, color: activeColor, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: activeColor,
            inactiveColor: AppColors.border,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
