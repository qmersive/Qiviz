import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;

  final _supabase = Supabase.instance.client;

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await _supabase.auth.signUp(
          email: email,
          password: password,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signup successful! Welcome to Qiviz.')),
          );
          // Wait for trigger to handle profile creation if necessary
          await Future.delayed(const Duration(seconds: 1));
          context.go('/profile-setup');
        }
      } else {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (mounted) {
          context.go('/splash'); // Let splash check profile status
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unexpected error occurred')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Qiviz',
                style: GoogleFonts.outfit(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.electricBlue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp ? 'Create your account' : 'Welcome back, vibe check?',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  color: AppTheme.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textGrey),
                ),
                style: const TextStyle(color: AppTheme.textWhite),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textGrey),
                ),
                style: const TextStyle(color: AppTheme.textWhite),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleAuth,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: AppTheme.textWhite, strokeWidth: 2),
                      )
                    : Text(_isSignUp ? 'Sign Up' : 'Login'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                  });
                },
                child: Text(
                  _isSignUp
                      ? 'Already have an account? Login'
                      : 'Don\'t have an account? Sign Up',
                  style: const TextStyle(color: AppTheme.neonPink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
