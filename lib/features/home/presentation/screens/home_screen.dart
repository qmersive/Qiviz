import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import 'package:qiviz/features/home/presentation/screens/create_story_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CardSwiperController _controller = CardSwiperController();
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _onlineUsers = [];
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      final response = await _supabase.from('profiles').select().neq('id', currentUserId ?? '').eq('is_onboarded', true);
      final data = List<Map<String, dynamic>>.from(response);
      setState(() {
        _users = data;
        _onlineUsers = data.where((u) => u['is_online'] == true).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() {
      _suggestions = _users.where((user) {
        final name = (user['name'] ?? '').toLowerCase();
        final username = (user['username'] ?? '').toLowerCase();
        return name.contains(query.toLowerCase()) || username.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                _buildStories(),
                _buildBlindDateBanner(),
                _buildSearchBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.electricBlue))
                      : _users.isEmpty
                          ? const Center(child: Text('No users nearby.', style: TextStyle(color: AppTheme.textGrey)))
                          : _buildSwipeStack(),
                ),
              ],
            ),
            if (_suggestions.isNotEmpty) _buildSearchSuggestions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
            child: Text('Discover', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          IconButton(icon: const Icon(Icons.notifications_none, color: AppTheme.electricBlue), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildStories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text('Live Now 🟢', style: GoogleFonts.outfit(color: AppTheme.acidGreen, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _onlineUsers.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildMyStory();
              final user = _onlineUsers[index - 1];
              return _buildUserStory(user);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMyStory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateStoryScreen()));
              if (result == true) _fetchData();
            },
            borderRadius: BorderRadius.circular(40),
            child: Stack(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.surfaceDark),
                  child: const Icon(Icons.add, color: Colors.white, size: 30),
                ),
                Positioned(
                  bottom: 0, right: 0, 
                  child: Container(
                    padding: const EdgeInsets.all(4), 
                    decoration: const BoxDecoration(color: AppTheme.neonPink, shape: BoxShape.circle), 
                    child: const Icon(Icons.add, size: 12, color: Colors.white)
                  )
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text('Your Story', style: TextStyle(color: AppTheme.textGrey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildUserStory(Map<String, dynamic> user) {
    return GestureDetector(
      onTap: () => context.push('/chat', extra: user),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.primaryGradient),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.surfaceDark,
                backgroundImage: user['profile_photo_url'] != null ? NetworkImage(user['profile_photo_url']) : null,
                child: user['profile_photo_url'] == null ? Text(user['name'][0]) : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(user['username'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildBlindDateBanner() {
    return FadeInRight(
      child: GestureDetector(
        onTap: () => context.push('/blind-date'),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.viralGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppTheme.neonPink.withValues(alpha: 0.3), blurRadius: 15)],
          ),
          child: Row(
            children: [
              const Icon(Icons.favorite, color: Colors.white, size: 40),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Join Blind Date', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text('Match anonymously with vibes!', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(16)),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Search new friends...', prefixIcon: Icon(Icons.search, color: AppTheme.electricBlue), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 15)),
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return Positioned(
      top: 240, left: 24, right: 24,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)]),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _suggestions.length,
          itemBuilder: (context, index) {
            final user = _suggestions[index];
            return ListTile(
              leading: CircleAvatar(backgroundImage: user['profile_photo_url'] != null ? NetworkImage(user['profile_photo_url']) : null),
              title: Text(user['name'], style: const TextStyle(color: Colors.white)),
              onTap: () {
                _searchController.clear();
                setState(() => _suggestions = []);
                context.push('/chat', extra: user);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSwipeStack() {
    return CardSwiper(
      controller: _controller,
      numberOfCardsDisplayed: _users.length < 3 ? _users.length : 3,
      cards: _users.map((u) => _buildUserCard(u)).toList(),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            if (user['profile_photo_url'] != null)
              Image.network(user['profile_photo_url'], fit: BoxFit.cover, width: double.infinity, height: double.infinity)
            else
              const Center(child: Icon(Icons.person, size: 100, color: AppTheme.textGrey)),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87])),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['name'], style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('@${user['username']}', style: const TextStyle(color: AppTheme.electricBlue)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => context.push('/game', extra: user),
                          icon: const Icon(Icons.videocam),
                          label: const Text('Play Game'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                          onPressed: () => context.push('/chat', extra: user),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
