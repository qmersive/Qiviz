import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scanQRCode() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Scan QR to Add Friend', style: GoogleFonts.outfit(color: AppTheme.textWhite, fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      Navigator.pop(context);
                      _navigateToUser(barcode.rawValue!);
                      break;
                    }
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToUser(String qrCodeId) {
    // In a real app, you'd fetch the user ID from the qrCodeId
    // For now, let's just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Scanned user: $qrCodeId. Navigating...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple)));
    if (_profile == null) return const Scaffold(body: Center(child: Text('Profile not found')));

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text('My Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner, color: AppTheme.electricBlue), onPressed: _scanQRCode),
          IconButton(icon: const Icon(Icons.logout, color: AppTheme.neonPink), onPressed: () => _supabase.auth.signOut().then((_) => context.go('/login'))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            FadeInDown(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppTheme.neonPink, AppTheme.primaryPurple]), boxShadow: [BoxShadow(color: AppTheme.primaryPurple.withValues(alpha: 0.5), blurRadius: 20)]),
                  ),
                  const CircleAvatar(radius: 55, backgroundColor: AppTheme.surfaceDark, child: Icon(Icons.person, size: 60, color: AppTheme.textWhite)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(_profile!['name'] ?? 'User', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
            Text(
              '@${_profile!['username'] ?? 'user'}',
              style: const TextStyle(color: AppTheme.electricBlue, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (_profile!['is_admin'] == true)
              FadeInUp(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/admin'),
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Admin Dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      foregroundColor: AppTheme.textWhite,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            _buildGlassCard(Icons.flag, 'From', _profile!['country']),
            _buildGlassCard(Icons.school, 'University', _profile!['university']),
            _buildGlassCard(Icons.info_outline, 'Bio', _profile!['bio']),

            const SizedBox(height: 32),
            _buildQRSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard(IconData icon, String title, String? value) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.textWhite.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.electricBlue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: AppTheme.textGrey.withValues(alpha: 0.7), fontSize: 12)),
                  Text(value ?? 'N/A', style: const TextStyle(color: AppTheme.textWhite, fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          QrImageView(
            data: _profile!['qr_code_id'] ?? _profile!['id'],
            version: QrVersions.auto,
            size: 200.0,
          ),
          const SizedBox(height: 12),
          const Text('Your Unique Qiviz QR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
