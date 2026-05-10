import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qiviz/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';

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
  RealtimeChannel? _inviteSubscription;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _listenForInvites();
  }

  @override
  void dispose() {
    _inviteSubscription?.unsubscribe();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      final response = await _supabase
          .from('profiles')
          .select()
          .neq('id', currentUserId ?? '')
          .eq('is_onboarded', true);

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
        final name = (user['name'] ?? '').toString().toLowerCase();
        final username = (user['username'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase()) || username.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _listenForInvites() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    _inviteSubscription = _supabase
        .channel('public:live_sessions')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'live_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'guest_id',
            value: currentUserId,
          ),
          callback: (payload) {
            final data = payload.newRecord;
            if (data['status'] == 'waiting') {
              _showInviteDialog(data);
            }
          },
        )
        .subscribe();
  }

  void _showInviteDialog(Map<String, dynamic> session) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Game Invite! 🎮', style: GoogleFonts.outfit(color: AppTheme.textWhite)),
        content: const Text('Someone wants to play a cultural trivia game with you live!', style: TextStyle(color: AppTheme.textGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Decline', style: TextStyle(color: AppTheme.neonPink)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/game', extra: {
                'name': 'Friend', 
                'channel': session['channel_name'],
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.electricBlue),
            child: const Text('Join Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendInvite(Map<String, dynamic> targetUser) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    final channelName = 'room_${currentUserId}_${targetUser['id']}';

    try {
      await _supabase.from('live_sessions').insert({
        'host_id': currentUserId,
        'guest_id': targetUser['id'],
        'channel_name': channelName,
        'status': 'waiting',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invite sent to ${targetUser['name']}! 🚀')),
        );
        context.push('/game', extra: {
          'name': targetUser['name'],
          'channel': channelName,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not send invite.')));
    }
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
                _buildOnlineSection(),
                _buildSearchBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.electricBlue))
                      : _users.isEmpty
                          ? _buildEmptyState()
                          : _buildSwipeStack(_users),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Discover', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
              Text('Find your tribe', style: GoogleFonts.inter(color: AppTheme.textGrey)),
            ],
          ),
          const CircleAvatar(backgroundColor: AppTheme.surfaceDark, child: Icon(Icons.notifications_none, color: AppTheme.textWhite)),
        ],
      ),
    );
  }

  Widget _buildOnlineSection() {
    if (_onlineUsers.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text('Live Now 🟢', style: GoogleFonts.outfit(color: AppTheme.electricBlue, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _onlineUsers.length,
            itemBuilder: (context, index) {
              final user = _onlineUsers[index];
              return GestureDetector(
                onTap: () => _sendInvite(user),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppTheme.electricBlue, AppTheme.primaryPurple])),
                            child: CircleAvatar(radius: 30, backgroundColor: AppTheme.surfaceDark, child: Text(user['name'][0])),
                          ),
                          Positioned(right: 2, bottom: 2, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: AppTheme.darkBackground, width: 2)))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(user['username'] ?? '', style: const TextStyle(color: AppTheme.textWhite, fontSize: 10)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: AppTheme.surfaceDark.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: const TextStyle(color: AppTheme.textWhite),
          decoration: const InputDecoration(
            hintText: 'Search students...',
            hintStyle: TextStyle(color: AppTheme.textGrey),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: AppTheme.electricBlue),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return Positioned(
      top: 200, left: 24, right: 24,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20)]),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _suggestions.length,
          itemBuilder: (context, index) {
            final user = _suggestions[index];
            return ListTile(
              leading: CircleAvatar(child: Text(user['name'][0])),
              title: Text(user['name'], style: const TextStyle(color: Colors.white)),
              subtitle: Text('@${user['username']}', style: const TextStyle(color: AppTheme.electricBlue)),
              onTap: () {
                _searchController.clear();
                setState(() => _suggestions = []);
                _sendInvite(user);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSwipeStack(List<Map<String, dynamic>> users) {
    return CardSwiper(
      controller: _controller,
      numberOfCardsDisplayed: users.length < 3 ? users.length : 3,
      onSwipe: _handleSwipe,
      cards: users.map((u) => _buildUserCard(u)).toList(),
    );
  }

  bool _handleSwipe(int index, CardSwiperDirection direction) {
    if (direction == CardSwiperDirection.right) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Matched with ${_users[index]['name']}! 💖')),
      );
    }
    return true;
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)])),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['name'] ?? '', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                    Text('@${user['username'] ?? ''}', style: const TextStyle(color: AppTheme.electricBlue)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _sendInvite(user),
                          icon: const Icon(Icons.videocam, size: 18),
                          label: const Text('Invite to Game'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                        if (user['is_streaming'] == true) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.push('/game', extra: {
                                'name': user['name'],
                                'channel': 'room_${user['id']}',
                              });
                            },
                            icon: const Icon(Icons.live_tv, size: 18),
                            label: const Text('Join Live'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.electricBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ],
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

  Widget _buildEmptyState() => const Center(child: Text('No users found.', style: TextStyle(color: AppTheme.textGrey)));
}
