import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/image_overlay_config.dart';

class PipPreviewOverlay extends StatelessWidget {
  final ImageOverlayConfig config;
  final VoidCallback? onTap;

  const PipPreviewOverlay({
    super.key,
    required this.config,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.isEnabled) return const SizedBox.shrink();

    // Map 0.0 -> 1.0 coordinates into Alignment(-1.0 -> 1.0)
    final alignX = (config.positionX - 0.5) * 2.0;
    final alignY = (config.positionY - 0.5) * 2.0;

    final widthFactor = config.scale.clamp(0.15, 1.5);
    final borderColor = Color(config.borderColor);
    final shadowColor = Color(config.shadowColor);

    return Align(
      alignment: Alignment(alignX, alignY),
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: AspectRatio(
          aspectRatio: config.shape == PipShape.circle ? 1.0 : 16 / 9,
          child: Transform.rotate(
            angle: config.rotation * (math.pi / 180.0),
            child: Opacity(
              opacity: config.opacity.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  shape: config.shape == PipShape.circle ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: config.shape == PipShape.circle
                      ? null
                      : BorderRadius.circular(config.cornerRadius),
                  boxShadow: config.hasShadow
                      ? [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: config.shadowBlur,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: ClipPath(
                  clipper: _resolveClipper(config.shape, config.cornerRadius),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      border: config.borderWidth > 0
                          ? Border.all(color: borderColor, width: config.borderWidth)
                          : null,
                      shape: config.shape == PipShape.circle ? BoxShape.circle : BoxShape.rectangle,
                      borderRadius: config.shape == PipShape.circle
                          ? null
                          : BorderRadius.circular(config.cornerRadius),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildContent(context),
                        if (config.assetLabel.trim().isNotEmpty)
                          Positioned(
                            left: 8,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                config.assetLabel,
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (config.mediaPath.isNotEmpty) {
      if (config.mediaPath.startsWith('http')) {
        return Image.network(
          config.mediaPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      }
      final file = File(config.mediaPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      }
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1A1D24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            config.shape == PipShape.circle ? Icons.videocam : Icons.picture_in_picture_alt,
            color: AppColors.accent,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            config.assetLabel.isNotEmpty ? config.assetLabel : 'PiP Window',
            style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  CustomClipper<Path>? _resolveClipper(PipShape shape, double cornerRadius) {
    if (shape == PipShape.diamond) {
      return const _DiamondClipper();
    }
    return null;
  }
}

class _DiamondClipper extends CustomClipper<Path> {
  const _DiamondClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height / 2);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
