import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:animate_do/animate_do.dart';
import 'package:qiviz/features/dares/presentation/screens/create_post_screen.dart';

class DaresScreen extends StatefulWidget {
  const DaresScreen({super.key});

  @override
  State<DaresScreen> createState() => _DaresScreenState();
}

class _DaresScreenState extends State<DaresScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _dares = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDares();
  }

  Future<void> _fetchDares() async {
    try {
      final response = await _supabase
          .from('dares')
          .select('*, profiles(name, username, country, profile_photo_url)')
          .eq('is_active', true)
          .not('video_url', 'is', null)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _dares = response as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.electricBlue))
          : _dares.isEmpty
              ? _buildEmptyState()
              : PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: _dares.length,
                  itemBuilder: (context, index) {
                    return DareVideoItem(dare: _dares[index]);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library_outlined, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            Text('No viral reels yet!', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen())),
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Post First Reel 🔥'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.neonPink,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DareVideoItem extends StatefulWidget {
  final dynamic dare;
  const DareVideoItem({super.key, required this.dare});

  @override
  State<DareVideoItem> createState() => _DareVideoItemState();
}

class _DareVideoItemState extends State<DareVideoItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.dare['video_url'] ?? 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'),
    )..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          _controller.setLooping(true);
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creator = widget.dare['profiles'] ?? {};
    
    return Stack(
      children: [
        Positioned.fill(
          child: _isInitialized
              ? GestureDetector(
                  onTap: () => _controller.value.isPlaying ? _controller.pause() : _controller.play(),
                  child: VideoPlayer(_controller),
                )
              : const Center(child: CircularProgressIndicator(color: AppTheme.neonPink)),
        ),
        
        // Multi-colored Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.2),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
        ),

        // UI Overlay
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Global Reels', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 10)])),
                    const Icon(Icons.search, color: Colors.white),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.electricBlue,
                                backgroundImage: creator['profile_photo_url'] != null ? NetworkImage(creator['profile_photo_url']) : null,
                                child: creator['profile_photo_url'] == null ? Text(creator['username']?[0].toUpperCase() ?? 'U') : null,
                              ),
                              const SizedBox(width: 12),
                              Text('@${creator['username'] ?? 'user'}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(widget.dare['title'] ?? 'Viral Challenge', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.electricBlue)),
                          const SizedBox(height: 8),
                          Text(widget.dare['description'] ?? '', style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    
                    // Vibrant Side Actions
                    Column(
                      children: [
                        _buildSideAction(Icons.favorite, '4.2k', AppTheme.neonPink),
                        _buildSideAction(Icons.comment, '1.2k', Colors.white),
                        _buildSideAction(Icons.share, 'Share', Colors.white),
                        const SizedBox(height: 20),
                        Pulse(
                          infinite: true,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(gradient: AppTheme.viralGradient, shape: BoxShape.circle),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSideAction(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        children: [
          Icon(icon, color: color, size: 38),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
