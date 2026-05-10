import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qiviz/features/auth/presentation/screens/login_screen.dart';
import 'package:qiviz/features/auth/presentation/screens/splash_screen.dart';
import 'package:qiviz/features/profile/presentation/screens/profile_setup_screen.dart';
import 'package:qiviz/features/home/presentation/screens/main_scaffold.dart';
import 'package:qiviz/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:qiviz/features/chat/presentation/screens/chat_room_screen.dart';
import 'package:qiviz/features/games/presentation/screens/game_screen.dart';
import 'package:qiviz/features/blind_date/presentation/screens/blind_date_screen.dart';
import 'package:qiviz/features/dares/presentation/screens/dares_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/profile-setup', builder: (context, state) => const ProfileSetupScreen()),
      GoRoute(path: '/admin', builder: (context, state) => const AdminDashboardScreen()),
      GoRoute(path: '/', builder: (context, state) => const MainScaffold()),
      GoRoute(path: '/blind-date', builder: (context, state) => const BlindDateScreen()),
      
      // Deep Linking: Direct path to a specific viral reel
      GoRoute(
        path: '/reel/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          // In a real app, you would fetch this specific reel data
          return const DaresScreen(); 
        },
      ),

      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) {
          final chatData = state.extra as Map<String, dynamic>;
          return ChatRoomScreen(chatData: chatData);
        },
      ),
      
      GoRoute(
        path: '/game',
        builder: (context, state) {
          final opponent = state.extra as Map<String, dynamic>;
          return GameScreen(opponent: opponent);
        },
      ),
    ],
  );
}
