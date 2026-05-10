import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:qiviz/features/auth/presentation/screens/splash_screen.dart';
import 'package:qiviz/features/auth/presentation/screens/login_screen.dart';
import 'package:qiviz/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:qiviz/features/home/presentation/screens/main_scaffold.dart';
import 'package:qiviz/features/home/presentation/screens/home_screen.dart';
import 'package:qiviz/features/games/presentation/screens/game_screen.dart';
import 'package:qiviz/features/blind_date/presentation/screens/blind_date_screen.dart';
import 'package:qiviz/features/admin/presentation/screens/admin_dashboard_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainScaffold(),
      ),
      GoRoute(
        path: '/game',
        builder: (context, state) {
          final opponent = state.extra as Map<String, dynamic>? ?? {'name': 'Player'};
          return GameScreen(opponent: opponent);
        },
      ),
      GoRoute(
        path: '/blind-date',
        builder: (context, state) => const BlindDateScreen(),
      ),
    ],
    redirect: (context, state) {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToSplash = state.matchedLocation == '/splash';
      
      // If we're on the splash screen, let the splash screen handle the initial navigation logic
      if (isGoingToSplash) return null;

      // If no session and not going to login, redirect to login
      if (session == null && !isGoingToLogin) {
        return '/login';
      }

      // If there is a session and going to login, redirect to home
      if (session != null && isGoingToLogin) {
        return '/';
      }

      return null;
    },
  );
});
