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
import 'widgets/ai_studio_tab.dart';
import 'widgets/creative_studio_tab.dart';
import 'widgets/system_specs_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTabIndex = 0;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
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
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                      borderRadius: BorderRadius.circular(12),
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
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text(
                          'Available Editions:',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureSpecItem('Edito Pro: Universal Flutter + Skia 60 FPS Engine'),
                    _buildFeatureSpecItem('Edito Premium: Full Flagship Studio (Standalone APK)'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Engine Specs & Features:',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: 8),
              _buildFeatureSpecItem('4K / 8K Lanczos & Real-ESRGAN Super-Resolution'),
              _buildFeatureSpecItem('True-Peak Brickwall Audio Limiter (0.95 ceiling)'),
              _buildFeatureSpecItem('Deterministic FFmpeg Multi-Pass DSP Filter Pipeline'),
              _buildFeatureSpecItem('Real-time Skia GPU Viewport Shader Compositor'),
              _buildFeatureSpecItem('100% On-Device Neural STT, VAD, Segmenter & Tracker'),
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

  Widget _buildQuickActionItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            _buildEditWorkspaceTab(),
            AiStudioTab(onToolSelected: _handleToolShortcut),
            CreativeStudioTab(onToolSelected: _handleToolShortcut),
            const SystemSpecsTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _currentTabIndex,
            onDestinationSelected: (idx) => setState(() => _currentTabIndex = idx),
            backgroundColor: Colors.transparent,
            elevation: 0,
            indicatorColor: AppColors.primary.withOpacity(0.2),
            height: 62,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.video_library_outlined, size: 22, color: AppColors.textSecondary),
                selectedIcon: Icon(Icons.video_library, size: 22, color: AppColors.primaryLight),
                label: 'Edit',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined, size: 22, color: AppColors.accent),
                selectedIcon: Icon(Icons.auto_awesome, size: 22, color: AppColors.accent),
                label: 'AI Studio',
              ),
              NavigationDestination(
                icon: Icon(Icons.palette_outlined, size: 22, color: AppColors.textSecondary),
                selectedIcon: Icon(Icons.palette, size: 22, color: AppColors.primaryLight),
                label: 'Studio',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_suggest_outlined, size: 22, color: AppColors.textSecondary),
                selectedIcon: Icon(Icons.settings_suggest, size: 22, color: AppColors.accent),
                label: 'System',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 0: EDIT WORKSPACE ---
  Widget _buildEditWorkspaceTab() {
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

    return CustomScrollView(
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          sliver: SliverToBoxAdapter(
            child: NewProjectButton(
              onPressed: () async {
                final newProj = await ref.read(projectListProvider.notifier).createNewProject();
                if (mounted) {
                  _openEditorWithProject(newProj);
                }
              },
              onRatioSelected: (ratio) async {
                final newProj = await ref.read(projectListProvider.notifier).createNewProjectWithRatio(ratio);
                if (mounted) {
                  _openEditorWithProject(newProj);
                }
              },
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),
          ),
        ),

        // Quick Creator Tools Shortcuts Bar
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          sliver: SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickActionItem('Teleprompter', Icons.subtitles_outlined, const Color(0xFF00CEC9), () {
                    _handleToolShortcut(EditorTool.teleprompter);
                  }),
                  const SizedBox(width: 8),
                  _buildQuickActionItem('Auto Silence Cut', Icons.movie_filter_outlined, const Color(0xFFFF7675), () {
                    _handleToolShortcut(EditorTool.clipWorkflow);
                  }),
                  const SizedBox(width: 8),
                  _buildQuickActionItem('8K AI Boost', Icons.auto_awesome_motion, const Color(0xFF8854D0), () {
                    _handleToolShortcut(EditorTool.enhance);
                  }),
                  const SizedBox(width: 8),
                  _buildQuickActionItem('Voiceover', Icons.mic, const Color(0xFFFDCB6E), () {
                    _handleToolShortcut(EditorTool.audioRecord);
                  }),
                ],
              ),
            ),
          ),
        ),

        // Search Bar & Filter Header
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
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
                const SizedBox(height: 14),
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
