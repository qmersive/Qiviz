import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qiviz/features/profile/presentation/screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  List<dynamic> _myDares = [];
  bool _isLoading = true;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchMyDares();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      final response = await _supabase.from('profiles').select().eq('id', user?.id ?? '').single();
      if (mounted) setState(() => _profile = response);
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMyDares() async {
    try {
      final user = _supabase.auth.currentUser;
      final response = await _supabase.from('dares').select().eq('creator_id', user?.id ?? '').order('created_at', ascending: false);
      if (mounted) setState(() => _myDares = response as List<dynamic>);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _uploadProfilePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updating Profile Photo...')));

      final user = _supabase.auth.currentUser;
      final fileName = '${user?.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'profiles/$fileName';

      // Web-friendly binary upload
      final bytes = await image.readAsBytes();
      await _supabase.storage.from('media').uploadBinary(
        path, 
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
      
      final photoUrl = _supabase.storage.from('media').getPublicUrl(path);

      await _supabase.from('profiles').update({'profile_photo_url': photoUrl}).eq('id', user!.id);
      _fetchProfile();
      
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated! ✨')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.electricBlue)));
    if (_profile == null) return const Scaffold(body: Center(child: Text('Please log in')));

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildProfileInfo()),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
            delegate: SliverChildBuilderDelegate((context, index) => _buildGridItem(_myDares[index]), childCount: _myDares.length),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: AppTheme.surfaceDark,
      flexibleSpace: FlexibleSpaceBar(
        title: Text('@${_profile!['username']}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      actions: [IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () {})],
    );
  }

  Widget _buildProfileInfo() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat('Posts', _myDares.length.toString()),
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
                        child: _profile!['profile_photo_url'] == null ? Text(_profile!['name'][0], style: const TextStyle(fontSize: 32)) : null,
                      ),
                    ),
                    Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: AppTheme.neonPink, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, size: 16, color: Colors.white))),
                  ],
                ),
              ),
              _buildStat('Likes', '12.4k'),
            ],
          ),
          const SizedBox(height: 16),
          Text(_profile!['name'] ?? 'User', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(_profile!['bio'] ?? 'No bio yet', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textGrey)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen(profile: _profile!)));
                    if (result == true) _fetchProfile();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Edit Profile'),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(icon: const Icon(Icons.share, color: Colors.white), onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)), Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12))]);
  }

  Widget _buildGridItem(dynamic dare) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.surfaceDark, image: dare['video_url'] != null ? const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=500&q=80'), fit: BoxFit.cover) : null),
      child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 30)),
    );
  }
}
