import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aau_pc_verify/app/app.dart';
import 'package:aau_pc_verify/core/constants/app_constants.dart';

void main() {
  testWidgets('App renders initial phase 1 screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AssetTraceApp(),
      ),
    );

    // Initial pump and settle
    await tester.pumpAndSettle();

    // Verify that the initial screen displays the app name and phase status
    expect(find.text(AppConstants.appName), findsAtLeastNWidgets(1));
    expect(find.text(AppConstants.phaseStatus), findsOneWidget);
  });
}
