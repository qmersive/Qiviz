import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final response = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();

        if (mounted) {
          setState(() {
            _profile = response;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  void _showQRCode() {
    if (_profile == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('My QR Code', style: TextStyle(color: AppTheme.textWhite)),
        content: SizedBox(
          width: 250,
          height: 250,
          child: QrImageView(
            data: _profile!['qr_code_id'] ?? _profile!['id'],
            version: QrVersions.auto,
            backgroundColor: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppTheme.electricBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple)),
      );
    }

    if (_profile == null) {
      return const Scaffold(
        body: Center(child: Text('Profile not found', style: TextStyle(color: AppTheme.textWhite))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code, color: AppTheme.electricBlue),
            onPressed: _showQRCode,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.neonPink),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryPurple,
              child: Text(
                _profile!['name']?[0] ?? 'U',
                style: const TextStyle(fontSize: 40, color: AppTheme.textWhite),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _profile!['name'] ?? 'Unknown User',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textWhite,
              ),
            ),
            Text(
              '@${_profile!['nickname'] ?? 'user'}',
              style: const TextStyle(color: AppTheme.textGrey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildInfoCard('Country', _profile!['country'], Icons.flag),
            _buildInfoCard('University', _profile!['university'], Icons.school),
            _buildInfoCard('City', _profile!['city'], Icons.location_city),
            _buildInfoCard('Bio', _profile!['bio'], Icons.person),
            const SizedBox(height: 16),
            
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Interests',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.electricBlue,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_profile!['interests'] as List<dynamic>? ?? [])
                  .map((interest) => Chip(
                        label: Text(interest.toString(), style: const TextStyle(color: AppTheme.textWhite)),
                        backgroundColor: AppTheme.surfaceDark,
                        side: const BorderSide(color: AppTheme.primaryPurple),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String? value, IconData icon) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Card(
      color: AppTheme.surfaceDark,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.textGrey),
        title: Text(title, style: const TextStyle(color: AppTheme.textGrey, fontSize: 14)),
        subtitle: Text(value, style: const TextStyle(color: AppTheme.textWhite, fontSize: 16)),
      ),
    );
  }
}
