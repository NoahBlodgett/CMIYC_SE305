import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Feature barrels
import 'package:cache_me_if_you_can/features/home/presentation/pages/pages.dart';
import 'package:cache_me_if_you_can/features/auth/presentation/pages/pages.dart';
import 'package:cache_me_if_you_can/features/onboarding/presentation/pages/pages.dart';
import 'package:cache_me_if_you_can/features/settings/presentation/pages/pages.dart';
import 'package:cache_me_if_you_can/features/security/presentation/pages/pages.dart';
import 'package:cache_me_if_you_can/features/workouts/presentation/pages/pages.dart';
import 'package:cache_me_if_you_can/features/nutrition/presentation/pages/pages.dart';
import 'package:cache_me_if_you_can/features/profile/presentation/pages/profile_page.dart';

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
  static const workoutRecent = '/workouts/recent';
  static const workoutAi = '/workouts/ai';
  static const workoutBuild = '/workouts/build';
  static const nutrition = '/nutrition';
  static const profile = '/profile';
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
      case Routes.workoutRecent:
        return MaterialPageRoute(builder: (_) => const RecentProgramsPage());
      case Routes.workoutAi:
        return MaterialPageRoute(builder: (_) => const AiProgramPage());
      case Routes.workoutBuild:
        return MaterialPageRoute(builder: (_) => const BuildProgramPage());
      case Routes.nutrition:
        return MaterialPageRoute(builder: (_) => const NutritionPage());
      case Routes.profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Routes.login;
    // Minimal heuristic: if displayName is empty OR a Firestore flag is false, send to onboarding.
    // (Extend by checking Firestore doc if needed.)
    final dn = user.displayName?.trim();
    if (dn == null || dn.isEmpty) return Routes.onboarding;
    return Routes.home;
  }
}
