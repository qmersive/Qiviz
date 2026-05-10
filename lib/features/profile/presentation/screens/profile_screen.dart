import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qiviz/features/profile/presentation/screens/edit_profile_screen.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  List<dynamic> _myDares = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchProfile();
    _fetchMyDares();
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

  Future<void> _fetchMyDares() async {
    try {
      final user = _supabase.auth.currentUser;
      final response = await _supabase
          .from('dares')
          .select()
          .eq('creator_id', user?.id ?? '')
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() => _myDares = response as List<dynamic>);
      }
    } catch (e) {
      debugPrint('Error fetching dares: $e');
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

      await _supabase.storage.from('media').upload(path, file);
      final url = _supabase.storage.from('media').getPublicUrl(path);

      await _supabase.from('profiles').update({'profile_photo_url': url}).eq('id', user?.id ?? '');
      _fetchProfile();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: AppTheme.darkBackground, body: Center(child: CircularProgressIndicator(color: AppTheme.electricBlue)));
    if (_profile == null) return const Scaffold(backgroundColor: AppTheme.darkBackground, body: Center(child: Text('Profile not found.')));

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.neonPink,
                indicatorWeight: 3,
                labelColor: AppTheme.textWhite,
                unselectedLabelColor: AppTheme.textGrey,
                tabs: const [
                  Tab(icon: Icon(Icons.grid_on)),
                  Tab(icon: Icon(Icons.favorite_border)),
                ],
              ),
            ),
            pinned: true,
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDaresGrid(),
            const Center(child: Text('Liked videos will appear here', style: TextStyle(color: AppTheme.textGrey))),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        GestureDetector(
          onTap: _uploadProfilePhoto,
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.primaryGradient),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.surfaceDark,
                  backgroundImage: _profile!['profile_photo_url'] != null ? NetworkImage(_profile!['profile_photo_url']) : null,
                  child: _profile!['profile_photo_url'] == null ? const Icon(Icons.add_a_photo, size: 24, color: Colors.white) : null,
                ),
              ),
              Positioned(right: 0, bottom: 0, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: AppTheme.neonPink, shape: BoxShape.circle), child: const Icon(Icons.edit, size: 14, color: Colors.white))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(_profile!['name'] ?? 'User', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
        Text('@${_profile!['username'] ?? 'user'}', style: const TextStyle(color: AppTheme.electricBlue, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(_myDares.length.toString(), 'Reels'),
        _buildStatItem('2.1k', 'Followers'),
        _buildStatItem('456', 'Likes'),
      ],
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      children: [
        Text(val, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
        Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen(profile: _profile!)),
              );
              if (result == true) _fetchProfile();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Edit Profile'),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(12)),
          child: IconButton(icon: const Icon(Icons.qr_code, color: AppTheme.textWhite), onPressed: _showMyQR),
        ),
        if (_profile!['is_admin'] == true) ...[
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(color: AppTheme.primaryPurple, borderRadius: BorderRadius.circular(12)),
            child: IconButton(icon: const Icon(Icons.admin_panel_settings, color: AppTheme.textWhite), onPressed: () => context.push('/admin')),
          ),
        ],
      ],
    );
  }

  Widget _buildDaresGrid() {
    if (_myDares.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_collection_outlined, size: 48, color: AppTheme.textGrey),
            const SizedBox(height: 16),
            const Text('No reels posted yet', style: TextStyle(color: AppTheme.textGrey)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.7,
      ),
      itemCount: _myDares.length,
      itemBuilder: (context, index) {
        final dare = _myDares[index];
        return Container(
          color: AppTheme.surfaceDark,
          child: Stack(
            children: [
              const Center(child: Icon(Icons.play_arrow, color: AppTheme.textGrey)),
              Positioned(
                bottom: 8, left: 8,
                child: Row(
                  children: [
                    const Icon(Icons.play_arrow_outlined, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text('1.2k', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: AppTheme.darkBackground, child: _tabBar);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
