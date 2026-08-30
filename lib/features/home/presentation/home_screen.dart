import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../editor/presentation/editor_screen.dart';
import '../../editor/providers/editor_provider.dart';
import '../providers/project_list_provider.dart';
import 'widgets/project_card.dart';
import 'widgets/new_project_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectListProvider);
    final filteredProjects = projects.where((p) {
      return p.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header Bar
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              sliver: SliverToBoxAdapter(
                child: Column(
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
                          child: const Icon(Icons.movie_filter, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'EDITO',
                          style: AppTypography.displayMedium.copyWith(
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    NewProjectButton(
                      onPressed: () async {
                        final newProj = await ref.read(projectListProvider.notifier).createNewProject();
                        if (context.mounted) {
                          ref.read(editorProvider.notifier).initProject(newProj);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditorScreen()),
                          );
                        }
                      },
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                  ],
                ),
              ),
            ),

            // Search Bar & Filter Header
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                          hintText: 'Search projects...',
                          hintStyle: AppTypography.bodyMedium,
                          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Projects', style: AppTypography.titleLarge),
                        Text('${filteredProjects.length} projects', style: AppTypography.labelSmall),
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
                      Icon(Icons.video_library_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('No projects found', style: AppTypography.titleMedium),
                      const SizedBox(height: 4),
                      Text('Tap "New Project" to get started', style: AppTypography.bodyMedium),
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
                        onTap: () {
                          ref.read(editorProvider.notifier).initProject(project);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditorScreen()),
                          );
                        },
                        onDelete: () {
                          ref.read(projectListProvider.notifier).deleteProject(project.id);
                        },
                      ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.05, end: 0);
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
}
