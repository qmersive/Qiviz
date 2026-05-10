import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
        final response = await _supabase.from('profiles').select().eq('id', user.id).single();
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

  Future<void> _uploadProfilePhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    
    if (image == null) return;

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      final file = File(image.path);
      final fileName = '${user?.id}_profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'profiles/$fileName';

      // Upload to media bucket
      await _supabase.storage.from('media').upload(path, file);
      final url = _supabase.storage.from('media').getPublicUrl(path);

      // Update profile
      await _supabase.from('profiles').update({'profile_photo_url': url}).eq('id', user?.id ?? '');
      _fetchProfile();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      setState(() => _isLoading = false);
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
              child: Text('Scan Friend\'s QR', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    debugPrint('Barcode found! ${barcode.rawValue}');
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Friend Added: ${barcode.rawValue}')));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: AppTheme.darkBackground, body: Center(child: CircularProgressIndicator(color: AppTheme.electricBlue)));
    if (_profile == null) return const Scaffold(backgroundColor: AppTheme.darkBackground, body: Center(child: Text('Profile not found.')));

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          children: [
            GestureDetector(
              onTap: _uploadProfilePhoto,
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppTheme.electricBlue, AppTheme.neonPink])),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.surfaceDark,
                      backgroundImage: _profile!['profile_photo_url'] != null ? NetworkImage(_profile!['profile_photo_url']) : null,
                      child: _profile!['profile_photo_url'] == null ? const Icon(Icons.add_a_photo, size: 30, color: Colors.white) : null,
                    ),
                  ),
                  Positioned(right: 0, bottom: 0, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: AppTheme.electricBlue, shape: BoxShape.circle), child: const Icon(Icons.edit, size: 16, color: Colors.white))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(_profile!['name'] ?? 'User', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
            Text('@${_profile!['username'] ?? 'user'}', style: const TextStyle(color: AppTheme.electricBlue, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            if (_profile!['is_admin'] == true)
              FadeInUp(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/admin'),
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Admin Dashboard'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple, foregroundColor: AppTheme.textWhite, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildGlassCard(Icons.flag, 'From', _profile!['country']),
            _buildGlassCard(Icons.school, 'University', _profile!['university']),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildActionBtn(Icons.qr_code, 'My QR', () => _showMyQR())),
                const SizedBox(width: 16),
                Expanded(child: _buildActionBtn(Icons.qr_code_scanner, 'Scan', _scanQRCode)),
              ],
            ),
            const SizedBox(height: 32),
            _buildStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard(IconData icon, String title, String? value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surfaceDark.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.textWhite.withValues(alpha: 0.05))),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.electricBlue, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
              Text(value ?? 'Not set', style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceDark, foregroundColor: AppTheme.textWhite, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppTheme.textWhite.withValues(alpha: 0.1)))),
    );
  }

  void _showMyQR() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Scan to Connect', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: QrImageView(data: _profile!['id'], version: QrVersions.auto, size: 200.0)),
            const SizedBox(height: 20),
            Text('@${_profile!['username']}', style: const TextStyle(color: AppTheme.electricBlue, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('342', 'Friends'),
        _buildStatItem('12', 'Dares'),
        _buildStatItem('850', 'XP'),
      ],
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
        Text(label, style: const TextStyle(color: AppTheme.textGrey)),
      ],
    );
  }
}
