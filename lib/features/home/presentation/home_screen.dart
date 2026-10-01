import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/edito_brand.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../editor/presentation/editor_screen.dart';
import '../../editor/providers/editor_provider.dart';
import '../../image_editor/models/video_layout_config.dart';
import '../../../models/project.dart';
import '../providers/project_list_provider.dart';
import 'widgets/project_card.dart';
import 'widgets/new_project_button.dart';
import 'widgets/ai_tools_hub.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0: All, 1: 9:16, 2: 16:9

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEditorWithProject(Project project, [EditorTool? initialTool]) {
    ref.read(editorProvider.notifier).initProject(project);
    if (initialTool != null) {
      ref.read(editorProvider.notifier).setActiveTool(initialTool);
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditorScreen()),
    );
  }

  Future<void> _handleToolShortcut(EditorTool tool) async {
    final projects = ref.read(projectListProvider);
    if (projects.isNotEmpty) {
      _openEditorWithProject(projects.first, tool);
    } else {
      final newProj = await ref.read(projectListProvider.notifier).createNewProject();
      if (mounted) {
        _openEditorWithProject(newProj, tool);
      }
    }
  }

  void _showRenameDialog(Project project) {
    final controller = TextEditingController(text: project.title);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          title: Text('Rename Project', style: AppTypography.titleLarge),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: AppTypography.bodyLarge,
            decoration: const InputDecoration(
              hintText: 'Enter project title',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                final newTitle = controller.text.trim();
                if (newTitle.isNotEmpty) {
                  ref.read(projectListProvider.notifier).renameProject(project.id, newTitle);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.movie_filter, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        EditoBrand.appTitle,
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        EditoBrand.brandTagline,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                        ),
                        child: Text(
                          EditoBrand.guestName,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Engine Specs & Features:',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: 8),
              _buildFeatureSpecItem('4K / 8K Lanczos Super-Resolution Upscaler'),
              _buildFeatureSpecItem('True-Peak Brickwall Audio Limiter (Rule 4 Safeguard)'),
              _buildFeatureSpecItem('Deterministic FFmpeg DSP Filter Pipeline'),
              _buildFeatureSpecItem('Real-time Skia GPU Viewport Shader Compositor'),
              _buildFeatureSpecItem('Multi-Track Timeline with Magnetic Snapping & Ripple Edit'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureSpecItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 14, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: AppTypography.caption.copyWith(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectListProvider);

    final filteredProjects = projects.where((p) {
      final matchesSearch = p.title.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_selectedFilterIndex == 1) {
        return p.width < p.height; // Vertical (9:16)
      } else if (_selectedFilterIndex == 2) {
        return p.width >= p.height; // Horizontal / Square (16:9, 1:1)
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top Edito Pro Studio Header
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.movie_filter, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'EDITO',
                              style: AppTypography.displayMedium.copyWith(
                                letterSpacing: 2.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.amberAccent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'AI Creative Studio',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primaryLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user_outlined, size: 13, color: AppColors.accent),
                          const SizedBox(width: 5),
                          Text(
                            EditoBrand.guestName,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: AppColors.textSecondary),
                      onPressed: _showAboutDialog,
                    ),
                  ],
                ),
              ),
            ),

            // Hero New Project Creation Banner
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              sliver: SliverToBoxAdapter(
                child: NewProjectButton(
                  onPressed: () async {
                    final newProj = await ref.read(projectListProvider.notifier).createNewProject();
                    if (context.mounted) {
                      _openEditorWithProject(newProj);
                    }
                  },
                  onRatioSelected: (ratio) async {
                    final newProj = await ref.read(projectListProvider.notifier).createNewProjectWithRatio(ratio);
                    if (context.mounted) {
                      _openEditorWithProject(newProj);
                    }
                  },
                ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),
              ),
            ),

            // AI Studio & Quick Tools Hub
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              sliver: SliverToBoxAdapter(
                child: AiToolsHub(
                  onToolSelected: _handleToolShortcut,
                ).animate().fadeIn(delay: 100.ms, duration: 350.ms),
              ),
            ),

            // Search Bar & Filter Header
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: AppTypography.bodyLarge,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search projects by name...',
                          hintStyle: AppTypography.bodyMedium,
                          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Projects section title and filter chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Projects', style: AppTypography.titleLarge),
                        Text(
                          '${filteredProjects.length} total',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.primaryLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildFilterChip('All', 0),
                        const SizedBox(width: 8),
                        _buildFilterChip('Vertical (9:16)', 1),
                        const SizedBox(width: 8),
                        _buildFilterChip('Landscape (16:9)', 2),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Projects List
            if (filteredProjects.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library_outlined,
                        size: 56,
                        color: AppColors.textMuted.withOpacity(0.4),
                      ),
                      const SizedBox(height: 12),
                      Text('No projects found', style: AppTypography.titleMedium),
                      const SizedBox(height: 4),
                      Text('Tap "+ New Project" to start creating', style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final project = filteredProjects[index];
                      return ProjectCard(
                        project: project,
                        onTap: () => _openEditorWithProject(project),
                        onDelete: () {
                          ref.read(projectListProvider.notifier).deleteProject(project.id);
                        },
                        onRename: () => _showRenameDialog(project),
                        onDuplicate: () async {
                          final duplicated = await ref.read(projectListProvider.notifier).duplicateProject(project);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Duplicated: ${duplicated.title}'),
                                duration: const Duration(milliseconds: 900),
                                backgroundColor: AppColors.surfaceElevated,
                              ),
                            );
                          }
                        },
                      ).animate().fadeIn(delay: (index * 40).ms).slideX(begin: 0.04, end: 0);
                    },
                    childCount: filteredProjects.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary.withOpacity(0.25),
      backgroundColor: AppColors.cardBackground,
      labelStyle: AppTypography.caption.copyWith(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _selectedFilterIndex = index);
        }
      },
    );
  }
}
