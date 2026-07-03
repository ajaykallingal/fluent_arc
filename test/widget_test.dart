import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluent_arc/main.dart';
import 'package:fluent_arc/features/auth/presentation/views/login_view.dart';

void main() {
  testWidgets('App startup smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(child: FluentArcApp(isBackendInitialized: false)),
    );

    // Let the GoRouter route and pages load
    await tester.pumpAndSettle();

    // Verify that the login view is rendered.
    expect(find.byType(LoginView), findsOneWidget);
  });
}
