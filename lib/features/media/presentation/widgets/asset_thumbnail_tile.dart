import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/timecode_formatter.dart';
import '../../../../models/media_asset.dart';

class AssetThumbnailTile extends StatelessWidget {
  final MediaAsset asset;
  final bool isSelected;
  final VoidCallback onTap;

  const AssetThumbnailTile({
    super.key,
    required this.asset,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Media Icon / Thumbnail placeholder
            Center(
              child: Icon(
                asset.type == MediaType.video
                    ? Icons.movie_outlined
                    : (asset.type == MediaType.audio ? Icons.audiotrack : Icons.image_outlined),
                size: 32,
                color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
              ),
            ),

            // Duration tag (bottom right)
            if (asset.durationMs > 0)
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    TimecodeFormatter.formatMilliseconds(asset.durationMs),
                    style: AppTypography.timecode.copyWith(fontSize: 10),
                  ),
                ),
              ),

            // Resolution / File Name (bottom left)
            Positioned(
              bottom: 6,
              left: 6,
              right: 50,
              child: Text(
                asset.fileName,
                style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Selection Checkmark (top right)
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
