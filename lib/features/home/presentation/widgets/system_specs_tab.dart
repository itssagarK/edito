import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/edito_brand.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/ai/device_tier_service.dart';

class SystemSpecsTab extends StatefulWidget {
  const SystemSpecsTab({super.key});

  @override
  State<SystemSpecsTab> createState() => _SystemSpecsTabState();
}

class _SystemSpecsTabState extends State<SystemSpecsTab> {
  static const MethodChannel _channel = MethodChannel('com.edito.app/gallery');

  DeviceHardwareInfo? _hardwareInfo;
  int? _freeDiskMb;

  @override
  void initState() {
    super.initState();
    _loadTelemetry();
  }

  Future<void> _loadTelemetry() async {
    try {
      final info = await DeviceTierService.getHardwareInfo();
      int? diskMb;
      if (Platform.isAndroid) {
        try {
          diskMb = await _channel.invokeMethod<int>('getDiskFreeSpaceMb');
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _hardwareInfo = info;
          _freeDiskMb = diskMb;
        });
      }
    } catch (_) {}
  }

  void _showLicensesDialog(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: EditoBrand.appTitle,
      applicationVersion: 'v1.0.72 (Build 73)',
      applicationLegalese: '100% On-Device & Offline AI Video Editor.\nLicensed under MIT, Apache-2.0, and BSD-3.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.settings_suggest, color: AppColors.accent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'System & Engine Specs',
                      style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Hardware telemetry, deterministic render pipeline and local model specs.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),

        // Device Diagnostics Card
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'HARDWARE TELEMETRY',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                      if (_hardwareInfo != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _hardwareInfo!.tier.label,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSpecRow(
                    'Device Model',
                    _hardwareInfo?.modelName ?? 'Standard Device',
                    Icons.phone_android,
                  ),
                  _buildSpecRow(
                    'CPU Cores',
                    '${_hardwareInfo?.cpuCores ?? Platform.numberOfProcessors} Threads',
                    Icons.developer_board,
                  ),
                  _buildSpecRow(
                    'Total RAM',
                    '${_hardwareInfo?.totalRamMb ?? 4096} MB',
                    Icons.memory,
                  ),
                  _buildSpecRow(
                    'Available Storage',
                    _freeDiskMb != null ? '${(_freeDiskMb! / 1024).toStringAsFixed(1)} GB Free' : 'Storage Available',
                    Icons.storage,
                  ),
                  _buildSpecRow(
                    'AI Preview Skip',
                    'Every ${_hardwareInfo?.previewFrameSkip ?? 2} Frames (Optimized)',
                    Icons.speed,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Offline Guarantee & Privacy Card
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF20BF6B).withOpacity(0.12),
                    AppColors.surfaceElevated,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF20BF6B).withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Color(0xFF20BF6B), size: 20),
                      SizedBox(width: 8),
                      Text(
                        '100% On-Device & Offline Privacy',
                        style: TextStyle(
                          color: Color(0xFF20BF6B),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Edito operates completely offline. All video decoding, neural network inference (Whisper, MediaPipe, Real-ESRGAN, RNNoise, Silero) and FFmpeg export renders occur strictly inside your device. No cloud telemetry, no account login required.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Core Engine Components
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NATIVE ENGINE INTEGRATIONS',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildEngineItem('FFmpeg 6.0 Multi-Pass DSP Filtergraph Pipeline', Icons.code),
                  _buildEngineItem('Skia GPU Shader Compositor & 60 FPS Viewport', Icons.layers),
                  _buildEngineItem('True-Peak Brickwall Audio Limiter (alimiter ceiling)', Icons.volume_up),
                  _buildEngineItem('Whisper Tiny INT8 Speech-to-Text Model (MIT)', Icons.subtitles),
                  _buildEngineItem('MediaPipe Selfie Segmenter & Optical Tracker (Apache-2.0)', Icons.camera),
                  _buildEngineItem('Real-ESRGAN Compact Tiled Super-Resolution (BSD-3)', Icons.auto_awesome),
                  _buildEngineItem('RNNoise Neural Spectral Noise Suppressor (BSD-3)', Icons.noise_control_off),
                ],
              ),
            ),
          ),
        ),

        // Action Buttons: Licenses & Version
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () => _showLicensesDialog(context),
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('Third-Party Open-Source Licenses'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '${EditoBrand.appTitle} • v1.0.72 (Build 73)\nUniversal Flutter + Android Platform Engine',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 15, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
