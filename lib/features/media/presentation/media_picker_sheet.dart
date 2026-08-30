import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/media_asset.dart';
import '../providers/media_import_provider.dart';
import 'widgets/asset_thumbnail_tile.dart';

class MediaPickerSheet extends ConsumerStatefulWidget {
  const MediaPickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MediaPickerSheet(),
    );
  }

  @override
  ConsumerState<MediaPickerSheet> createState() => _MediaPickerSheetState();
}

class _MediaPickerSheetState extends ConsumerState<MediaPickerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _selectedAssetIds = {};
  final List<MediaAsset> _sessionAssets = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(mediaImportProvider);
    final isLoading = importState.isLoading;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    Text('Import Media', style: AppTypography.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabs (Videos, Audio, Photos)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.videocam_outlined, size: 18), text: 'Videos'),
                Tab(icon: Icon(Icons.audiotrack_outlined, size: 18), text: 'Audio'),
                Tab(icon: Icon(Icons.photo_library_outlined, size: 18), text: 'Photos'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tab Views with Action to Pick from Device
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMediaTypeTab(
                  type: MediaType.video,
                  icon: Icons.video_library_outlined,
                  title: 'Select Videos from Device',
                  subtitle: 'MP4, MOV, MKV, AVI supported',
                  onPick: () async {
                    final picked = await ref.read(mediaImportProvider.notifier).importVideos();
                    if (picked.isNotEmpty && mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
                _buildMediaTypeTab(
                  type: MediaType.audio,
                  icon: Icons.audio_file_outlined,
                  title: 'Select Audio from Device',
                  subtitle: 'MP3, WAV, AAC, M4A supported',
                  onPick: () async {
                    final picked = await ref.read(mediaImportProvider.notifier).importAudios();
                    if (picked.isNotEmpty && mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
                _buildMediaTypeTab(
                  type: MediaType.image,
                  icon: Icons.image_search_outlined,
                  title: 'Select Photos from Gallery',
                  subtitle: 'JPG, PNG, WEBP supported',
                  onPick: () async {
                    final picked = await ref.read(mediaImportProvider.notifier).importImages();
                    if (picked.isNotEmpty && mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
          ),

          // Loading Indicator if importing
          if (isLoading)
            const LinearProgressIndicator(
              backgroundColor: AppColors.surfaceElevated,
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildMediaTypeTab({
    required MediaType type,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPick,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 48, color: AppColors.primaryLight),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTypography.titleMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTypography.bodyMedium),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('Browse Files'),
            ),
          ),
        ],
      ),
    );
  }
}
