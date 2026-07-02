import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/avatar_widget.dart';
import '../../../../core/widgets/progress_card.dart';
import '../../../../core/widgets/score_card.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../view_models/dashboard_view_model.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final stats = ref.watch(dashboardViewModelProvider);

    // Watch auth status and redirect if unauthenticated
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated) {
        context.go('/login');
      }
    });

    final user = authState.user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FluentArc',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Greeting Section
              Row(
                children: [
                  AvatarWidget(
                    displayName: user.displayName,
                    photoUrl: user.photoUrl,
                    radius: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome,',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          '${user.displayName} 👋',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Overall Progress Card
              ProgressCard(
                title: 'Overall Fluency Goal',
                value: stats.overallProgress / 100.0,
                progressText: 'Keep practicing speaking to hit 100%',
                icon: Icons.emoji_events_outlined,
              ),
              const SizedBox(height: 20),

              // Streak & Vocab highlights
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Daily Streak',
                      value: '${stats.streakDays} days',
                      icon: Icons.local_fire_department_rounded,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Words Learned',
                      value: '${stats.vocabularyCount}',
                      icon: Icons.auto_stories_rounded,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Score Highlights
              Text(
                'Skill Levels',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ScoreCard(
                title: 'Grammar Accuracy',
                score: stats.grammarScore,
                description: 'Based on grammar corrections checks.',
              ),
              const SizedBox(height: 12),
              ScoreCard(
                title: 'Pronunciation & Rhythm',
                score: stats.speakingScore,
                description: 'Analyzed speaking audio sessions.',
                customColor: theme.colorScheme.secondary,
              ),
              const SizedBox(height: 28),

              // Grid of modules
              Text(
                'Practice Modules',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _buildModuleCard(
                    context,
                    title: 'AI Conversation',
                    description: 'Chat with your AI Tutor',
                    icon: Icons.chat_bubble_outline_rounded,
                    color: theme.colorScheme.primary,
                    route: '/conversation',
                  ),
                  _buildModuleCard(
                    context,
                    title: 'Grammar Coach',
                    description: 'Correct your sentences',
                    icon: Icons.spellcheck_rounded,
                    color: theme.colorScheme.tertiary,
                    route: '/grammar',
                  ),
                  _buildModuleCard(
                    context,
                    title: 'Vocabulary list',
                    description: 'Review saved words',
                    icon: Icons.style_outlined,
                    color: Colors.amber[700]!,
                    route: '/vocabulary',
                  ),
                  _buildModuleCard(
                    context,
                    title: 'Accent Coach',
                    description: 'Improve pronunciation',
                    icon: Icons.mic_none_rounded,
                    color: theme.colorScheme.secondary,
                    route: '/accent',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
