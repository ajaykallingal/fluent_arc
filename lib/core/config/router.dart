import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/dashboard/presentation/views/dashboard_view.dart';
import '../../features/conversation/presentation/views/conversation_view.dart';
import '../../features/grammar/presentation/views/grammar_view.dart';
import '../../features/vocabulary/presentation/views/vocabulary_view.dart';
import '../../features/pronunciation/presentation/views/accent_coach_view.dart';
import '../../features/progress/presentation/views/progress_view.dart';

final goRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginView(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardView(),
    ),
    GoRoute(
      path: '/conversation',
      builder: (context, state) => const ConversationView(),
    ),
    GoRoute(
      path: '/grammar',
      builder: (context, state) => const GrammarView(),
    ),
    GoRoute(
      path: '/vocabulary',
      builder: (context, state) => const VocabularyView(),
    ),
    GoRoute(
      path: '/accent',
      builder: (context, state) => const AccentCoachView(),
    ),
    GoRoute(
      path: '/progress',
      builder: (context, state) => const ProgressView(),
    ),
  ],
);
