import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/parallax_3d_config.dart';
import '../../services/parallax_3d_compiler_service.dart';

/// CapCut Pro 3D Zoom & Parallax Motion Studio Sheet
class Parallax3DSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip) onSave;
  final bool isDocked;
  final VoidCallback? onDone;

  const Parallax3DSheet({
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
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Parallax3DSheet(
        clip: clip,
        onSave: onSave,
      ),
    );
  }

  @override
  State<Parallax3DSheet> createState() => _Parallax3DSheetState();
}

class _Parallax3DSheetState extends State<Parallax3DSheet> {
  late Parallax3DConfig _config;
  bool _isPeekingRaw = false;
  double _previewProgress = 0.5;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.parallax3d;
  }

  void _updateConfig(Parallax3DConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    final updatedClip = widget.clip.copyWith(parallax3d: _config);
    widget.onSave(updatedClip);
  }

  void _resetToDefault() {
    _updateConfig(const Parallax3DConfig());
  }

  IconData _getIconForStyle(Parallax3DStyle style) {
    switch (style) {
      case Parallax3DStyle.none:
        return Icons.block;
      case Parallax3DStyle.classicZoomIn:
        return Icons.zoom_in;
      case Parallax3DStyle.dollyZoomOut:
        return Icons.zoom_out;
      case Parallax3DStyle.orbitalLeft:
        return Icons.rotate_left;
      case Parallax3DStyle.orbitalRight:
        return Icons.rotate_right;
      case Parallax3DStyle.vertigoDolly:
        return Icons.camera;
      case Parallax3DStyle.elasticBounce:
        return Icons.speed;
      case Parallax3DStyle.craneGlider:
        return Icons.flight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeConfig = _isPeekingRaw ? const Parallax3DConfig() : _config;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(20)),
        border: widget.isDocked
            ? const Border(top: BorderSide(color: AppColors.border, width: 1))
            : null,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            _buildHeaderBar(),

            // Interactive 3D Depth Visualizer
            _buildDepthVisualizer(activeConfig),

            // Scrollable Controls
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Style Selector Carousel
                    _buildSectionHeader('3D MOTION STYLES'),
                    const SizedBox(height: 8),
                    _buildStyleCarousel(),

                    const SizedBox(height: 16),

                    if (_config.isEnabled && _config.style != Parallax3DStyle.none) ...[
                      // Fine-Tuning Sliders
                      _buildSectionHeader('CAMERA KINEMATICS'),
                      const SizedBox(height: 8),

                      _buildSliderRow(
                        label: 'Intensity (Travel)',
                        value: _config.intensity,
                        min: 0.1,
                        max: 1.0,
                        unit: '%',
                        displayFactor: 100,
                        onChanged: (val) {
                          _updateConfig(_config.copyWith(intensity: val));
                        },
                      ),

                      _buildSliderRow(
                        label: 'Depth Scale',
                        value: _config.depthScale,
                        min: 1.0,
                        max: 2.5,
                        unit: 'x',
                        displayFactor: 1,
                        fractionDigits: 2,
                        onChanged: (val) {
                          _updateConfig(_config.copyWith(depthScale: val));
                        },
                      ),

                      _buildSliderRow(
                        label: 'Perspective Tilt',
                        value: _config.perspectiveTilt,
                        min: 0.0,
                        max: 1.0,
                        unit: '%',
                        displayFactor: 100,
                        onChanged: (val) {
                          _updateConfig(_config.copyWith(perspectiveTilt: val));
                        },
                      ),

                      _buildSliderRow(
                        label: 'Optical Depth Blur',
                        value: _config.depthBlur,
                        min: 0.0,
                        max: 1.0,
                        unit: '%',
                        displayFactor: 100,
                        onChanged: (val) {
                          _updateConfig(_config.copyWith(depthBlur: val));
                        },
                      ),

                      const SizedBox(height: 14),

                      // Focal Plane Selector
                      _buildSectionHeader('OPTICAL FOCAL PLANE'),
                      const SizedBox(height: 8),
                      _buildFocalPlaneSelector(),

                      const SizedBox(height: 14),

                      // Motion Easing Curve Selector
                      _buildSectionHeader('ACCELERATION & EASING'),
                      const SizedBox(height: 8),
                      _buildDynamicsCurveSelector(),

                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.view_in_ar,
              color: Color(0xFF00E676),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CapCut Pro 3D Zoom & Parallax',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _config.isEnabled && _config.style != Parallax3DStyle.none
                      ? 'Mode: ${_config.style.label}'
                      : 'Camera Parallax Off',
                  style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Peek / Raw Compare Button
          GestureDetector(
            onTapDown: (_) => setState(() => _isPeekingRaw = true),
            onTapUp: (_) => setState(() => _isPeekingRaw = false),
            onTapCancel: () => setState(() => _isPeekingRaw = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isPeekingRaw
                    ? const Color(0xFF00E676)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isPeekingRaw
                      ? const Color(0xFF00E676)
                      : AppColors.border,
                ),
              ),
              child: Text(
                'RAW',
                style: TextStyle(
                  color: _isPeekingRaw ? Colors.black : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Reset button
          IconButton(
            onPressed: _resetToDefault,
            icon: const Icon(Icons.refresh, size: 18, color: Colors.white70),
            tooltip: 'Reset to default',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceElevated,
              padding: const EdgeInsets.all(6),
            ),
          ),

          if (widget.isDocked && widget.onDone != null) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: widget.onDone,
              icon: const Icon(Icons.check, size: 20, color: Color(0xFF00E676)),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceElevated,
                padding: const EdgeInsets.all(6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Interactive 3D Depth Card Visualizer
  Widget _buildDepthVisualizer(Parallax3DConfig activeConfig) {
    if (!activeConfig.isEnabled || activeConfig.style == Parallax3DStyle.none) {
      return const SizedBox.shrink();
    }

    final matrix = Parallax3DCompilerService.computePreviewMatrix(
      activeConfig,
      _previewProgress,
      viewportSize: const Size(260, 90),
    );
    final blur = Parallax3DCompilerService.computePreviewBlur(activeConfig, _previewProgress);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF14181F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Simulated Background Depth Grid
            Positioned.fill(
              child: CustomPaint(
                painter: _DepthGridPainter(),
              ),
            ),

            // Simulated 3D Card Subject
            Transform(
              transform: matrix,
              alignment: Alignment.center,
              child: Container(
                width: 140,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00E676).withOpacity(0.4),
                      const Color(0xFF00B0FF).withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00E676),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withOpacity(0.2),
                      blurRadius: (10.0 + blur).clamp(0.0, 30.0),
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIconForStyle(activeConfig.style),
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '3D: ${activeConfig.style.label}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Live Camera Metrics Overlay
            Positioned(
              bottom: 6,
              left: 10,
              child: Text(
                'Z-SCALE: ${(1.0 + (activeConfig.depthScale - 1.0) * activeConfig.intensity * _previewProgress).toStringAsFixed(2)}x  •  3D PERSPECTIVE: ${(activeConfig.perspectiveTilt * 100).round()}%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  /// 3D Motion Style Selector Carousel
  Widget _buildStyleCarousel() {
    final styles = Parallax3DStyle.values;

    return SizedBox(
      height: 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: styles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final style = styles[index];
          final isSelected = _config.style == style && _config.isEnabled;

          return GestureDetector(
            onTap: () {
              if (style == Parallax3DStyle.none) {
                _updateConfig(_config.copyWith(
                  isEnabled: false,
                  style: Parallax3DStyle.none,
                ));
              } else {
                _updateConfig(_config.copyWith(
                  isEnabled: true,
                  style: style,
                ));
              }
            },
            child: Container(
              width: 105,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00E676).withOpacity(0.2)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? const Color(0xFF00E676) : AppColors.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIconForStyle(style),
                    size: 26,
                    color: isSelected ? const Color(0xFF00E676) : Colors.white70,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    style.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required double displayFactor,
    int fractionDigits = 0,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                fractionDigits > 0
                    ? '${(value * displayFactor).toStringAsFixed(fractionDigits)}$unit'
                    : '${(value * displayFactor).round()}$unit',
                style: const TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF00E676),
              inactiveTrackColor: AppColors.surfaceElevated,
              thumbColor: const Color(0xFF00E676),
              overlayColor: const Color(0xFF00E676).withOpacity(0.2),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocalPlaneSelector() {
    return Row(
      children: FocalPlane.values.map((plane) {
        final isSelected = _config.focalPlane == plane;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                _updateConfig(_config.copyWith(focalPlane: plane));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00E676).withOpacity(0.2)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00E676) : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    plane.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDynamicsCurveSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MotionDynamicsCurve.values.map((curve) {
        final isSelected = _config.dynamicsCurve == curve;
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            _updateConfig(_config.copyWith(dynamicsCurve: curve));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF00E676).withOpacity(0.2)
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFF00E676) : AppColors.border,
              ),
            ),
            child: Text(
              curve.label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Simulated 3D Depth Grid Painter
class _DepthGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;

    for (double x = 0; x <= size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += 15) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
