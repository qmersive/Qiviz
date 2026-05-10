import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Artificial delay for splash screen branding
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // Check if profile exists and is onboarded
      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', session.user.id)
            .maybeSingle();

        if (profile != null && profile['is_onboarded'] == true) {
          if (mounted) context.go('/');
        } else {
          if (mounted) context.go('/profile-setup');
        }
      } catch (e) {
        // Fallback if error fetching profile
        if (mounted) context.go('/profile-setup');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.darkBackground,
              AppTheme.surfaceDark,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo placeholder or animated text
              Text(
                'Qiviz',
                style: GoogleFonts.outfit(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.electricBlue,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Connect. Play. Vibe.',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  color: AppTheme.textGrey,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                color: AppTheme.neonPink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
