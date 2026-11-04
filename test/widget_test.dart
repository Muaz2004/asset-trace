import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aau_pc_verify/app/app.dart';
import 'package:aau_pc_verify/core/constants/app_constants.dart';

void main() {
  testWidgets('App renders staff login portal smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AssetTraceApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the login portal displays the app name and institutional login subtitle
    expect(find.text(AppConstants.appName), findsAtLeastNWidgets(1));
    expect(find.text(AppConstants.loginSubtitle), findsOneWidget);
  });
}
