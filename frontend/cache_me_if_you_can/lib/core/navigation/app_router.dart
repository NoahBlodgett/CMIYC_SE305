import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Feature barrels
import 'package:cache_me_if_you_can/features/home/presentation/pages/pages.dart';
import 'package:cache_me_if_you_can/features/auth/presentation/pages/pages.dart';
import 'package:cache_me_if_you_can/features/onboarding/presentation/pages/pages.dart';
import 'package:cache_me_if_you_can/features/settings/presentation/pages/pages.dart';
import 'package:cache_me_if_you_can/features/security/presentation/pages/pages.dart';
import 'package:cache_me_if_you_can/features/workouts/presentation/pages/pages.dart';

/// Centralized route names for the application.
/// Use these constants with Navigator.pushNamed / popUntil.
abstract class Routes {
  static const root = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const settings = '/settings';
  static const security = '/settings/security';
  static const workouts = '/workouts';
  static const workoutLogTimed = '/workouts/log_timed';
  static const workoutLogStrength = '/workouts/log_strength';
  static const workoutRecent = '/workouts/recent';
  static const workoutAi = '/workouts/ai';
  static const workoutBuild = '/workouts/build';
  static const workoutPlan = '/workouts/plan';
  static const workoutSessions = '/workouts/sessions';
  static const workoutFeedback = '/workouts/feedback';
}

/// AppRouter provides a single onGenerateRoute handler plus convenience
/// methods for auth-aware initial route resolution.
class AppRouter {
  const AppRouter();

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? Routes.root;
    switch (name) {
      case Routes.root:
      case Routes.home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case Routes.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case Routes.signup:
        return MaterialPageRoute(builder: (_) => const CreateUserPage());
      case Routes.onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingPage());
      case Routes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case Routes.security:
        return MaterialPageRoute(builder: (_) => const SecurityPage());
      case Routes.workouts:
        return MaterialPageRoute(builder: (_) => const WorkoutPage());
      case Routes.workoutLogTimed:
        return MaterialPageRoute(builder: (_) => const TimedLogPage());
      case Routes.workoutLogStrength:
        return MaterialPageRoute(builder: (_) => const StrengthLogPage());
      case Routes.workoutRecent:
        return MaterialPageRoute(builder: (_) => const RecentProgramsPage());
      case Routes.workoutAi:
        return MaterialPageRoute(builder: (_) => const AiProgramPage());
      case Routes.workoutBuild:
        return MaterialPageRoute(builder: (_) => const BuildProgramPage());
      case Routes.workoutPlan:
        return MaterialPageRoute(builder: (_) => const PlanOverviewPage());
      case Routes.workoutSessions:
        return MaterialPageRoute(builder: (_) => const RecentSessionsPage());
      case Routes.workoutFeedback:
        return MaterialPageRoute(builder: (_) => const FeedbackInsightsPage());
      default:
        return _unknownRoute(name);
    }
  }

  /// Return a simple unknown route screen to avoid crashing when an invalid
  /// named route is used.
  Route<dynamic> _unknownRoute(String attempted) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Page not found')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text('No route for "$attempted"'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, Routes.home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Determine the initial route based on auth state and onboarding completion.
  /// Returns one of login, onboarding, or home.
  Future<String> resolveInitialRoute() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      debugPrint(
        '[resolveInitialRoute] user: '
        '${user == null ? 'null' : user.uid} at ${DateTime.now()}',
      );
      if (user == null) return Routes.login;
      // Check Firestore for onboarding_completed flag
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      debugPrint(
        '[resolveInitialRoute] Firestore user doc: ${data?.toString()}',
      );
      // If doc is missing or onboarding_completed is not true, go to onboarding
      if (data == null || data['onboarding_completed'] != true)
        return Routes.onboarding;
      return Routes.home;
    } catch (e, stack) {
      debugPrint('[resolveInitialRoute] Exception: $e\n$stack');
      // If Firebase isn't initialized in this environment (tests, new installs),
      // default to login instead of throwing.
      return Routes.login;
    }
  }
}
