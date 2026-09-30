import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/face_reshape_config.dart';

class FaceReshapeSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip, {bool applyToAll}) onSave;
  final VoidCallback onDone;
  final bool isDocked;

  const FaceReshapeSheet({
    super.key,
    required this.clip,
    required this.onSave,
    required this.onDone,
    this.isDocked = false,
  });

  @override
  State<FaceReshapeSheet> createState() => _FaceReshapeSheetState();
}

class _FaceReshapeSheetState extends State<FaceReshapeSheet> with SingleTickerProviderStateMixin {
  late FaceReshapeConfig _config;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _config = widget.clip.faceReshape;
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _update(FaceReshapeConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    widget.onSave(widget.clip.copyWith(faceReshape: _config));
  }

  void _applyPreset(FaceReshapePreset preset) {
    final newConfig = FaceReshapeConfig.fromPreset(preset);
    _update(newConfig);
  }

  void _resetAll() {
    _update(const FaceReshapeConfig(isEnabled: true));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: widget.isDocked
            ? null
            : const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: [
                  _buildEnableCard(),
                  const SizedBox(height: 12),
                  if (_config.isEnabled) ...[
                    _buildIntensitySlider(),
                    const SizedBox(height: 12),
                    _buildTabBar(),
                    const SizedBox(height: 12),
                    _buildActiveTabContent(),
                    const SizedBox(height: 16),
                    _buildActionButtons(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.face,
              color: Color(0xFF00E5FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3D Face Reshape',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Edito Pro AI Feature Sculpting',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.accent),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.accent.withOpacity(0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: widget.onDone,
          ),
        ],
      ),
    );
  }

  Widget _buildEnableCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _config.isEnabled ? const Color(0xFF00E5FF) : AppColors.border,
          width: _config.isEnabled ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Face Sculpting',
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  _config.isEnabled
                      ? 'Active — 3D mesh distortion & landmark sculpting'
                      : 'Enable to sculpt face, jawline, eyes, nose & smile',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: _config.isEnabled,
            activeColor: const Color(0xFF00E5FF),
            onChanged: (val) {
              _update(_config.copyWith(isEnabled: val));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIntensitySlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Master Sculpt Intensity', style: AppTypography.bodySmall),
              Text('${(_config.intensity * 100).toInt()}%', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF00E5FF))),
            ],
          ),
          Slider(
            value: _config.intensity,
            min: 0.0,
            max: 1.0,
            activeColor: const Color(0xFF00E5FF),
            inactiveColor: AppColors.border,
            onChanged: (val) => _update(_config.copyWith(intensity: val)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFF00E5FF),
        labelColor: const Color(0xFF00E5FF),
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: '🌟 Presets'),
          Tab(text: '👤 Face & Jaw'),
          Tab(text: '👁️ Eyes'),
          Tab(text: '👃 Nose'),
          Tab(text: '👄 Lips & Smile'),
        ],
        onTap: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_tabController.index) {
      case 0:
        return _buildPresetsTab();
      case 1:
        return _buildFaceJawTab();
      case 2:
        return _buildEyesTab();
      case 3:
        return _buildNoseTab();
      case 4:
        return _buildLipsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPresetsTab() {
    return Column(
      children: FaceReshapePreset.values.map((preset) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            dense: true,
            title: Text(
              preset.label,
              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              preset.description,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textMuted),
            onTap: () => _applyPreset(preset),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFaceJawTab() {
    return Column(
      children: [
        _buildSculptSlider('Face Slimming', _config.faceSlimming, (v) => _update(_config.copyWith(faceSlimming: v))),
        _buildSculptSlider('V-Face Jawline', _config.vFace, (v) => _update(_config.copyWith(vFace: v))),
        _buildSculptSlider('Jawbone Width', _config.jawbone, (v) => _update(_config.copyWith(jawbone: v))),
        _buildSculptSlider('Pointy Chin', _config.pointyChin, (v) => _update(_config.copyWith(pointyChin: v))),
        _buildSculptSlider('Chin Length', _config.chinLength, (v) => _update(_config.copyWith(chinLength: v))),
        _buildSculptSlider('Cheekbone Slim', _config.cheekbone, (v) => _update(_config.copyWith(cheekbone: v))),
        _buildSculptSlider('Forehead Height', _config.forehead, (v) => _update(_config.copyWith(forehead: v))),
        _buildSculptSlider('Temple Width', _config.temple, (v) => _update(_config.copyWith(temple: v))),
      ],
    );
  }

  Widget _buildEyesTab() {
    return Column(
      children: [
        _buildSculptSlider('Eye Size (Zoom)', _config.eyeSize, (v) => _update(_config.copyWith(eyeSize: v))),
        _buildSculptSlider('Eye Distance (Span)', _config.eyeDistance, (v) => _update(_config.copyWith(eyeDistance: v))),
        _buildSculptSlider('Eye Angle (Tilt)', _config.eyeAngle, (v) => _update(_config.copyWith(eyeAngle: v))),
        _buildSculptSlider('Eye Corner (Canthus)', _config.eyeCorner, (v) => _update(_config.copyWith(eyeCorner: v))),
        _buildSculptSlider('Eye Vertical Position', _config.eyePosition, (v) => _update(_config.copyWith(eyePosition: v))),
      ],
    );
  }

  Widget _buildNoseTab() {
    return Column(
      children: [
        _buildSculptSlider('Nose Slimming', _config.noseSize, (v) => _update(_config.copyWith(noseSize: v))),
        _buildSculptSlider('Nose Bridge Height', _config.noseBridge, (v) => _update(_config.copyWith(noseBridge: v))),
      ],
    );
  }

  Widget _buildLipsTab() {
    return Column(
      children: [
        _buildSculptSlider('Mouth Size', _config.mouthSize, (v) => _update(_config.copyWith(mouthSize: v))),
        _buildSculptSlider('Plump Lip Volume', _config.lipEnhance, (v) => _update(_config.copyWith(lipEnhance: v))),
        _buildSculptSlider('Smile Corner Lift', _config.smileCorners, (v) => _update(_config.copyWith(smileCorners: v))),
        _buildSculptSlider('Mouth Position', _config.mouthPosition, (v) => _update(_config.copyWith(mouthPosition: v))),
      ],
    );
  }

  Widget _buildSculptSlider(String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
              Text(
                '${(value * 100).toInt()}%',
                style: AppTypography.caption.copyWith(
                  color: value.abs() > 0.01 ? const Color(0xFF00E5FF) : AppColors.textSecondary,
                  fontWeight: value.abs() > 0.01 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: -1.0,
            max: 1.0,
            activeColor: const Color(0xFF00E5FF),
            inactiveColor: AppColors.border,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Reset All Sculpting'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _resetAll,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.copy_all, size: 16),
          label: const Text('Apply 3D Sculpting to All Video Clips'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            widget.onSave(widget.clip.copyWith(faceReshape: _config), applyToAll: true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('3D Face Sculpting applied to all clips'),
                duration: Duration(milliseconds: 900),
                backgroundColor: AppColors.surfaceElevated,
              ),
            );
          },
        ),
      ],
    );
  }
}
