import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/screens/initial_screen.dart';
import 'route_paths.dart';

/// Riverpod provider exposing the application's GoRouter instance.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.initial,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: RoutePaths.initial,
        name: RouteNames.initial,
        builder: (context, state) => const InitialScreen(),
      ),
    ],
  );
});
