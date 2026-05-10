import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:animate_do/animate_do.dart';

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
          .select('*, profiles(name, username, country)')
          .eq('is_active', true)
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_library_outlined, size: 80, color: AppTheme.textGrey),
          const SizedBox(height: 16),
          Text('No viral dares yet!', style: GoogleFonts.outfit(fontSize: 22, color: AppTheme.textWhite)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPink),
            child: const Text('Be the First! 🔥'),
          ),
        ],
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
    // Using a sample video URL for demonstration. In production, this would be dare['video_url']
    _controller = VideoPlayerController.networkUrl(
      Uri.parse('https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'),
    )..initialize().then((_) {
        setState(() => _isInitialized = true);
        _controller.setLooping(true);
        _controller.play();
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
        // Video Player
        Positioned.fill(
          child: _isInitialized
              ? GestureDetector(
                  onTap: () {
                    _controller.value.isPlaying ? _controller.pause() : _controller.play();
                  },
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                )
              : const Center(child: CircularProgressIndicator(color: AppTheme.neonPink)),
        ),

        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
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
                    Text('Viral Dares', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                    const Icon(Icons.search, color: AppTheme.textWhite),
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
                          FadeInLeft(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppTheme.electricBlue,
                                  child: Text(creator['username']?[0].toUpperCase() ?? 'U'),
                                ),
                                const SizedBox(width: 10),
                                Text('@${creator['username'] ?? 'user'}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeInUp(
                            child: Text(widget.dare['title'] ?? 'Challenge', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.electricBlue)),
                          ),
                          FadeInUp(
                            delay: const Duration(milliseconds: 200),
                            child: Text(widget.dare['description'] ?? '', style: const TextStyle(color: AppTheme.textWhite)),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    
                    // Side Actions
                    Column(
                      children: [
                        _buildSideAction(Icons.favorite, '2.4k', AppTheme.neonPink),
                        _buildSideAction(Icons.comment, '156', AppTheme.textWhite),
                        _buildSideAction(Icons.share, 'Share', AppTheme.textWhite),
                        const SizedBox(height: 10),
                        Bounce(
                          infinite: true,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: AppTheme.neonPink, shape: BoxShape.circle),
                            child: const Icon(Icons.add, color: AppTheme.textWhite),
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Icon(icon, color: color, size: 35),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.textWhite, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
