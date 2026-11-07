import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/language_select_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RouteNames.splash,
  routes: [
    GoRoute(
      path: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: RouteNames.languageSelect,
      builder: (context, state) => const LanguageSelectScreen(),
    ),
    GoRoute(
      path: RouteNames.login,
      builder: (context, state) => _placeholderScaffold('Login Screen (Part 1)'),
    ),
    GoRoute(
      path: RouteNames.verifyOtp,
      builder: (context, state) => _placeholderScaffold('Verify OTP (Part 1)'),
    ),
    GoRoute(
      path: RouteNames.roleSelect,
      builder: (context, state) => _placeholderScaffold('Role Select (Part 1)'),
    ),
    GoRoute(
      path: RouteNames.onboarding,
      builder: (context, state) => _placeholderScaffold('Onboarding (Part 1)'),
    ),
    GoRoute(
      path: RouteNames.farmerDashboard,
      builder: (context, state) => _placeholderScaffold('Farmer Dashboard (Part 1)'),
    ),
    GoRoute(
      path: RouteNames.consumerHome,
      builder: (context, state) => _placeholderScaffold('Consumer Marketplace (Part 1)'),
    ),
    GoRoute(
      path: RouteNames.cropAdvisor,
      builder: (context, state) => _placeholderScaffold('Crop Advisor (Part 2)'),
    ),
    GoRoute(
      path: RouteNames.diseaseDetection,
      builder: (context, state) => _placeholderScaffold('Disease Detection (Part 3)'),
    ),
    GoRoute(
      path: RouteNames.krishiSahayak,
      builder: (context, state) => _placeholderScaffold('Krishi Sahayak (Part 3)'),
    ),
    GoRoute(
      path: RouteNames.machinery,
      builder: (context, state) => _placeholderScaffold('Machinery Rentals (Part 4)'),
    ),
    GoRoute(
      path: RouteNames.store,
      builder: (context, state) => _placeholderScaffold('Agri Store (Part 4)'),
    ),
    GoRoute(
      path: RouteNames.admin,
      builder: (context, state) => _placeholderScaffold('Admin Verification (Part 1)'),
    ),
  ],
);

Widget _placeholderScaffold(String title) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
