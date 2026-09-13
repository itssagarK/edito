import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/clip.dart';
import '../../models/hd_converter_config.dart';

class HdConverterSheet extends StatefulWidget {
  final Clip clip;
  final Function(Clip updatedClip, {bool applyToAll}) onSave;
  final VoidCallback? onDone;

  const HdConverterSheet({
    super.key,
    required this.clip,
    required this.onSave,
    this.onDone,
  });

  static Future<void> show(
    BuildContext context, {
    required Clip clip,
    required Function(Clip, {bool applyToAll}) onSave,
    VoidCallback? onDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HdConverterSheet(
        clip: clip,
        onSave: onSave,
        onDone: onDone,
      ),
    );
  }

  @override
  State<HdConverterSheet> createState() => _HdConverterSheetState();
}

class _HdConverterSheetState extends State<HdConverterSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late HdConverterConfig _config;
  bool _applyToAll = false;
  double _splitRatio = 0.5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _config = widget.clip.hdConverter;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _applyChanges() {
    final updatedClip = widget.clip.copyWith(hdConverter: _config);
    widget.onSave(updatedClip, applyToAll: _applyToAll);
  }

  void _updateConfig(HdConverterConfig Function(HdConverterConfig) updater) {
    setState(() {
      _config = updater(_config);
    });
    _applyChanges();
  }

  void _selectPreset(HdConverterPreset preset) {
    final newConfig = preset.createConfig();
    setState(() {
      _config = newConfig;
    });
    _applyChanges();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.76,
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
                        const Icon(Icons.high_quality, color: AppColors.accent, size: 24),
                        const SizedBox(width: 8),
                        Text('HD Video Converter', style: AppTypography.titleLarge),
                      ],
                    ),
                    Row(
                      children: [
                        Switch.adaptive(
                          value: _config.isEnabled,
                          activeColor: AppColors.accent,
                          onChanged: (val) {
                            _updateConfig((c) => c.copyWith(isEnabled: val));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: AppColors.accent, size: 24),
                          onPressed: () {
                            _applyChanges();
                            widget.onDone?.call();
                            Navigator.pop(context);
                          },
                          tooltip: 'Done',
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.accent.withOpacity(0.15),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Interactive Before / After Comparison Preview Card
          _buildComparisonCard(),

          // Tabs: Presets | Resolution & Scale | Detail & Clarity
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
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              tabs: const [
                Tab(icon: Icon(Icons.auto_awesome, size: 15), text: '1-Tap Presets'),
                Tab(icon: Icon(Icons.aspect_ratio, size: 15), text: 'Resolution'),
                Tab(icon: Icon(Icons.tune, size: 15), text: 'Detail & Clean'),
              ],
            ),
          ),

          // Tab Contents
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPresetsTab(),
                _buildResolutionTab(),
                _buildDetailTab(),
              ],
            ),
          ),

          // Bottom Bar: Apply to All
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _applyToAll,
                      activeColor: AppColors.accent,
                      onChanged: (val) {
                        setState(() => _applyToAll = val ?? false);
                        _applyChanges();
                      },
                    ),
                    const Text('Apply HD conversion to all clips', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
                Text(
                  _config.isEnabled
                      ? '${_config.targetResolution.shortTag} • ${_config.algorithm.label.toUpperCase()}'
                      : 'DISABLED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _config.isEnabled ? AppColors.accent : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- INTERACTIVE BEFORE / AFTER PREVIEW CARD ---
  Widget _buildComparisonCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: 86,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final splitWidth = constraints.maxWidth * _splitRatio;

            return GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _splitRatio = (_splitRatio + details.delta.dx / constraints.maxWidth).clamp(0.1, 0.9);
                });
              },
              child: Stack(
                children: [
                  // Converted HD side (Right)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.diamond_outlined, size: 14, color: AppColors.accent),
                                      const SizedBox(width: 4),
                                      Text(
                                        _config.targetResolution.label.toUpperCase(),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${_config.targetResolution.width}x${_config.targetResolution.height} • ${_config.targetResolution.bitrateLabel}',
                                    style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Original side (Left)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: splitWidth,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A1F2C),
                        border: Border(right: BorderSide(color: Colors.white, width: 2)),
                      ),
                      child: Center(
                        child: Row(
                          children: const [
                            Padding(
                              padding: EdgeInsets.only(left: 16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ORIGINAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70)),
                                  Text('Source Canvas', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Split slider handle
                  Positioned(
                    left: splitWidth - 12,
                    top: (86 - 24) / 2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 4),
                        ],
                      ),
                      child: const Icon(Icons.unfold_more, size: 14, color: Colors.black),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- PRESETS TAB ---
  Widget _buildPresetsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: HdConverterPreset.values.length,
      itemBuilder: (context, index) {
        final preset = HdConverterPreset.values[index];
        final presetConfig = preset.createConfig();
        final isSelected = _config.isEnabled &&
            _config.targetResolution == presetConfig.targetResolution &&
            _config.algorithm == presetConfig.algorithm;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected ? AppColors.accent : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: ListTile(
            dense: true,
            title: Text(
              preset.label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? AppColors.accent : Colors.white,
              ),
            ),
            subtitle: Text(
              preset.description,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_circle, color: AppColors.accent, size: 20)
                : const Icon(Icons.arrow_forward_ios, color: AppColors.textMuted, size: 14),
            onTap: () => _selectPreset(preset),
          ),
        );
      },
    );
  }

  // --- RESOLUTION & SCALE TAB ---
  Widget _buildResolutionTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        const Text('Target Output Resolution', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        ...HdResolution.values.map((res) {
          final isSelected = _config.targetResolution == res;
          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            color: isSelected ? AppColors.primary.withOpacity(0.25) : AppColors.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isSelected ? AppColors.accent : AppColors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: ListTile(
              dense: true,
              leading: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent.withOpacity(0.2) : AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  res.shortTag,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isSelected ? AppColors.accent : Colors.white,
                  ),
                ),
              ),
              title: Text(
                res.label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? AppColors.accent : Colors.white,
                ),
              ),
              subtitle: Text(
                '${res.width} x ${res.height} px • Bitrate: ${res.bitrateLabel}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              trailing: Radio<HdResolution>(
                value: res,
                groupValue: _config.targetResolution,
                activeColor: AppColors.accent,
                onChanged: (newRes) {
                  if (newRes != null) {
                    _updateConfig((c) => c.copyWith(targetResolution: newRes, isEnabled: true));
                  }
                },
              ),
              onTap: () {
                _updateConfig((c) => c.copyWith(targetResolution: res, isEnabled: true));
              },
            ),
          );
        }),
        const SizedBox(height: 12),

        const Text('Interpolation & Scaling Algorithm', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: HdScalingAlgorithm.values.map((alg) {
            final isSelected = _config.algorithm == alg;
            return ChoiceChip(
              label: Text(
                alg.label,
                style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.textMuted),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceElevated,
              onSelected: (selected) {
                if (selected) {
                  _updateConfig((c) => c.copyWith(algorithm: alg, isEnabled: true));
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- DETAIL & CLEAN TAB ---
  Widget _buildDetailTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        // Detail Clarity Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Super-Resolution Detail Clarity', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
            Text('${(_config.detailClarity * 100).round()}%', style: const TextStyle(fontSize: 11, color: AppColors.accent)),
          ],
        ),
        Slider(
          value: _config.detailClarity,
          min: 0.5,
          max: 2.0,
          activeColor: AppColors.accent,
          onChanged: (val) => _updateConfig((c) => c.copyWith(detailClarity: val, isEnabled: true)),
        ),
        const SizedBox(height: 8),

        // Edge Sharpness Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Edge Sharpening Strength', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
            Text('${(_config.sharpness * 100).round()}%', style: const TextStyle(fontSize: 11, color: AppColors.accent)),
          ],
        ),
        Slider(
          value: _config.sharpness,
          min: 0.5,
          max: 2.0,
          activeColor: AppColors.primary,
          onChanged: (val) => _updateConfig((c) => c.copyWith(sharpness: val, isEnabled: true)),
        ),
        const SizedBox(height: 8),

        // De-noise Slider
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('AI Noise & Grain Reduction', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
            Text('${(_config.denoiseStrength * 100).round()}%', style: const TextStyle(fontSize: 11, color: AppColors.accent)),
          ],
        ),
        Slider(
          value: _config.denoiseStrength,
          min: 0.0,
          max: 1.0,
          activeColor: AppColors.accentWarm,
          onChanged: (val) => _updateConfig((c) => c.copyWith(denoiseStrength: val, isEnabled: true)),
        ),
        const Divider(color: AppColors.border),

        // Deblocking Switch
        SwitchListTile.adaptive(
          title: const Text('MPEG Macroblock Cleaner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          subtitle: const Text('Removes pixelation blocks from blurry social downloads', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          value: _config.deblocking,
          activeColor: AppColors.accent,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) => _updateConfig((c) => c.copyWith(deblocking: val, isEnabled: true)),
        ),

        // Dynamic HDR Expand Switch
        SwitchListTile.adaptive(
          title: const Text('Dynamic Range (HDR) Expansion', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          subtitle: const Text('Enhances peak contrast and rich darks for HDR displays', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          value: _config.hdrColorExpand,
          activeColor: AppColors.accent,
          contentPadding: EdgeInsets.zero,
          onChanged: (val) => _updateConfig((c) => c.copyWith(hdrColorExpand: val, isEnabled: true)),
        ),
      ],
    );
  }
}
