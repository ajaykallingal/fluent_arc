import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluent_arc/features/dashboard/presentation/view_models/dashboard_view_model.dart';
import 'package:fluent_arc/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthNotifier extends Notifier<AuthState> with Mock implements AuthNotifier {}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('DashboardViewModel Tests', () {
    test('initial state contains mock values', () {
      final stats = container.read(dashboardViewModelProvider);
      
      expect(stats.streakDays, equals(3));
      expect(stats.overallProgress, equals(45));
      expect(stats.grammarScore, equals(78.0));
      expect(stats.speakingScore, equals(82.0));
      expect(stats.vocabularyCount, equals(15));
    });

    test('refreshStats resets to initial stats', () {
      final notifier = container.read(dashboardViewModelProvider.notifier);
      notifier.refreshStats();

      final stats = container.read(dashboardViewModelProvider);
      expect(stats.streakDays, equals(3));
    });
  });
}
