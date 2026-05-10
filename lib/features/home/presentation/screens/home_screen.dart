import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _nearbyUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNearbyUsers();
  }

  Future<void> _fetchNearbyUsers() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      // In a real app with PostGIS, we'd query by distance.
      // For MVP, we fetch users who are not the current user.
      final response = await _supabase
          .from('profiles')
          .select()
          .neq('id', currentUser.id)
          .eq('is_onboarded', true)
          .limit(20);

      if (mounted) {
        setState(() {
          _nearbyUsers = response as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Discover',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.electricBlue,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppTheme.textWhite),
            onPressed: () {
              // Navigate to QR scanner
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPink))
          : _nearbyUsers.isEmpty
              ? Center(
                  child: Text(
                    'No one nearby right now.\nCheck back later!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: AppTheme.textGrey, fontSize: 18),
                  ),
                )
              : _buildUserCards(),
    );
  }

  Widget _buildUserCards() {
    // Simple ListView for MVP, full version would use swipeable cards (e.g. flutter_card_swiper)
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _nearbyUsers.length,
      itemBuilder: (context, index) {
        final user = _nearbyUsers[index];
        return Card(
          color: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryPurple,
                      child: Text(
                        user['name']?[0] ?? '?',
                        style: const TextStyle(fontSize: 24, color: AppTheme.textWhite),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user['name']}, ${user['country']}',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textWhite,
                            ),
                          ),
                          Text(
                            user['university'] ?? 'Unknown University',
                            style: const TextStyle(color: AppTheme.textGrey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user['bio'] ?? 'No bio provided.',
                  style: const TextStyle(color: AppTheme.textWhite),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push('/game', extra: user);
                      },
                      icon: const Icon(Icons.gamepad),
                      label: const Text('Play Game'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryPurple,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push('/blind-date');
                      },
                      icon: const Icon(Icons.coffee),
                      label: const Text('Blind Date'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonPink,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
