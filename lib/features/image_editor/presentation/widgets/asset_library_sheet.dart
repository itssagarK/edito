import 'package:flutter/material.dart' hide Clip;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../models/project.dart';
import '../models/creative_asset.dart';
import '../services/asset_library_service.dart';

class AssetLibrarySheet extends StatefulWidget {
  final Project project;
  final String? activeClipId;
  final Function(Project updatedProject) onProjectUpdated;
  final VoidCallback? onOpenThumbnailEditor;

  const AssetLibrarySheet({
    super.key,
    required this.project,
    this.activeClipId,
    required this.onProjectUpdated,
    this.onOpenThumbnailEditor,
  });

  static Future<void> show(
    BuildContext context, {
    required Project project,
    String? activeClipId,
    required Function(Project) onProjectUpdated,
    VoidCallback? onOpenThumbnailEditor,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssetLibrarySheet(
        project: project,
        activeClipId: activeClipId,
        onProjectUpdated: onProjectUpdated,
        onOpenThumbnailEditor: onOpenThumbnailEditor,
      ),
    );
  }

  @override
  State<AssetLibrarySheet> createState() => _AssetLibrarySheetState();
}

class _AssetLibrarySheetState extends State<AssetLibrarySheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: AssetCategory.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleAssetTap(CreativeAsset asset) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(asset.primaryColor).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(asset.primaryColor)),
                  ),
                  alignment: Alignment.center,
                  child: Text(asset.iconEmoji, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(asset.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(asset.subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Option 1: Apply to Video
            ListTile(
              leading: const Icon(Icons.layers_outlined, color: AppColors.primary),
              title: const Text('Apply to Video Clip as Overlay / PiP', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: const Text('Pins graphic on top of the current video frame', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              onTap: () {
                final updated = AssetLibraryService.applyAssetToProject(
                  widget.project,
                  asset,
                  targetClipId: widget.activeClipId,
                );
                widget.onProjectUpdated(updated);
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Applied "${asset.title}" overlay to video!'),
                    backgroundColor: AppColors.accent,
                  ),
                );
              },
            ),

            // Option 2: Apply to Video Layout / Frame
            if (asset.category == AssetCategory.frame || asset.category == AssetCategory.background)
              ListTile(
                leading: const Icon(Icons.aspect_ratio, color: AppColors.accent),
                title: const Text('Set as Video Canvas Layout', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Applies frame borders & background canvas to project', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                onTap: () {
                  final updated = AssetLibraryService.applyAssetToProject(widget.project, asset);
                  widget.onProjectUpdated(updated);
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎬 Configured project layout: ${asset.title}'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),

            // Option 3: Use in Thumbnail Designer
            if (widget.onOpenThumbnailEditor != null)
              ListTile(
                leading: const Icon(Icons.photo_size_select_actual_outlined, color: Colors.orangeAccent),
                title: const Text('Design in Thumbnail & Cover Studio', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('Open in image editor canvas to position with text & filters', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  widget.onOpenThumbnailEditor!();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
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
                        const Icon(Icons.auto_awesome_mosaic, color: AppColors.accent, size: 22),
                        const SizedBox(width: 8),
                        Text('Creative Assets & Overlays', style: AppTypography.titleLarge),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted, size: 22),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Categories TabBar
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
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              tabs: [
                for (final cat in AssetCategory.values)
                  Tab(text: cat.label.split(' ').first),
              ],
            ),
          ),

          // Assets Grid TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                for (final cat in AssetCategory.values)
                  _buildCategoryGrid(cat),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(AssetCategory category) {
    final assets = AssetLibraryService.getAssetsByCategory(category);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        return InkWell(
          onTap: () => _handleAssetTap(asset),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Color(asset.primaryColor).withOpacity(0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(asset.primaryColor).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(asset.iconEmoji, style: const TextStyle(fontSize: 18)),
                    ),
                    const Icon(Icons.touch_app_outlined, size: 16, color: AppColors.textMuted),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      asset.subtitle,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
